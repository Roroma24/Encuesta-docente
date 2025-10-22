""" 
Autores: Axel Castañeda Sánchez y Luis Roberto Rodríguez Marroquin
Descripción: Archivo principal de la aplicación Flask para la evaluación docente.
"""

# Importación de librerías y configuración de la app Flask
from flask import Flask, render_template, request, jsonify, redirect, url_for, session
import mysql.connector

app = Flask(__name__)
app.secret_key = "supersecretkey"  

# Conexión a la base de datos MySQL
db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="Saltamontes71#",
    database="evaluacion_d"  
)
cursor = db.cursor(dictionary=True)

# Ruta principal: Login de usuario (alumno o docente)
@app.route("/", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        matricula = request.form.get("matricula", "").strip()
        password = request.form.get("password", "").strip()
        
        # Verificar si es admin 
        if matricula == "admin" and password == "admin1":
            session['tipo_usuario'] = 'admin'
            return redirect(url_for('admin'))
            
        # Para alumnos y docentes, validar formato de fecha
        if not (len(password) == 6 and password.isdigit()):
            return render_template("login.html", error="Formato de contraseña incorrecto para alumnos/docentes (debe ser DDMMYY)")
        
        cursor.callproc("ver_alumnos")
        alumno = None
        for result in cursor.stored_results():
            for row in result.fetchall():
                if row['matricula'] == matricula:
                    alumno = row
                    break
        if alumno:
            # Validar contraseña: fecha de nacimiento en formato DDMMYY 
            fecha_nac = alumno.get('fecha_nacimiento')
            if fecha_nac:
                try:
                    expected = fecha_nac.strftime("%d%m%y")
                except Exception:
                    expected = ""
            else:
                expected = ""
            if password == expected and expected != "":
                session['tipo_usuario'] = 'alumno'
                session['matricula'] = matricula
                session['id_alumno'] = alumno['id_alumno']
                return redirect(url_for('index'))
            else:
                return render_template("login.html", error="Matrícula o contraseña incorrecta")
        cursor.callproc("ver_docentes")
        docente = None
        for result in cursor.stored_results():
            for row in result.fetchall():
                if row['matricula'] == matricula:
                    docente = row
                    break
        if docente:
            # Validar contraseña del docente con su fecha de nacimiento en formato DDMMYY
            fecha_nac_doc = docente.get('fecha_nacimiento')
            if fecha_nac_doc:
                try:
                    expected_doc = fecha_nac_doc.strftime("%d%m%y")
                except Exception:
                    expected_doc = ""
            else:
                expected_doc = ""
            if password == expected_doc and expected_doc != "":
                session['tipo_usuario'] = 'docente'
                session['matricula'] = matricula
                session['id_docente'] = docente['id_docente']
                return redirect(url_for('profesor'))
            else:
                return render_template("login.html", error="Matrícula o contraseña incorrecta")
        return render_template("login.html", error="Matrícula no encontrada")
    return render_template("login.html")

# Ruta para alumnos: muestra docentes y semestres contestados
@app.route("/inicio")
def index():
    if session.get('tipo_usuario') != 'alumno':
        return redirect(url_for('login'))
    id_alumno = session.get('id_alumno')

    # Obtener campus y número de semestre del alumno
    cursor.execute("SELECT id_campus, numero_semestre FROM alumnos WHERE id_alumno = %s", (id_alumno,))
    alumno = cursor.fetchone()
    id_campus = alumno['id_campus'] if alumno else None
    numero_semestre = alumno['numero_semestre'] if alumno else None

    # Si no hay información de campus o semestre -> no hay encuestas disponibles
    if not id_campus or not numero_semestre:
        return render_template("finale.html")

    # Semestres ya contestados por el alumno
    cursor.execute("SELECT id_semestre FROM evaluacion WHERE id_alumno = %s", (id_alumno,))
    semestres_contestados = {row['id_semestre'] for row in cursor.fetchall()}

    # Obtener semestres disponibles para el alumno y que no hayan sido contestados
    cursor.execute("""
        SELECT s.* FROM semestre s
        WHERE s.id_campus = %s AND s.numero = %s
        AND s.id_semestre NOT IN (
            SELECT id_semestre FROM evaluacion WHERE id_alumno = %s
        )
    """, (id_campus, numero_semestre, id_alumno))
    semestres_disponibles = cursor.fetchall()

    # Si no hay semestres disponibles -> no mostrar opciones (página final)
    if not semestres_disponibles:
        return render_template("finale.html")

    # Determinar docente(s) que tienen al menos un semestre disponible
    docente_ids = {s['id_docente'] for s in semestres_disponibles}
    if docente_ids:
        placeholders = ",".join(["%s"] * len(docente_ids))
        cursor.execute(f"SELECT * FROM docentes WHERE id_docente IN ({placeholders})", tuple(docente_ids))
        docentes = cursor.fetchall()
    else:
        docentes = []

    return render_template("index.html", docentes=docentes, semestres_contestados=semestres_contestados)

# Ruta para docentes: muestra reporte de evaluaciones
@app.route("/profesor")
def profesor():
    if session.get('tipo_usuario') != 'docente':
        return redirect(url_for('login'))
    id_docente = session.get('id_docente')
    cursor.callproc("reporte_evaluacion")
    resultados = []
    for result in cursor.stored_results():
        for row in result.fetchall():
            if row['nombre_docente'] and row.get('nombre_docente') and row.get('nombre_docente') != '':
                cursor2 = db.cursor(dictionary=True)
                cursor2.execute("SELECT id_docente FROM docentes WHERE nombre = %s AND apellidop = %s AND apellidom = %s", (row['nombre_docente'], row['apellidop'], row['apellidom']))
                doc = cursor2.fetchone()
                cursor2.close()
                if doc and doc['id_docente'] == id_docente:
                    resultados.append(row)
    return render_template("profesor.html", resultados=resultados)

# Ruta para obtener semestres disponibles para evaluar a un docente
@app.route("/semestres/<int:id_docente>")
def semestres_por_docente(id_docente):
    id_alumno = session.get('id_alumno')
    # Obtener el campus y semestre del alumno
    cursor.execute("SELECT id_campus, numero_semestre FROM alumnos WHERE id_alumno = %s", (id_alumno,))
    alumno = cursor.fetchone()
    id_campus = alumno['id_campus'] if alumno else None
    numero_semestre = alumno['numero_semestre'] if alumno else None
    # Obtener solo los semestres del docente que sean del mismo campus y mismo semestre
    cursor.execute("""
        SELECT * FROM semestre WHERE id_docente = %s AND id_campus = %s AND numero = %s
    """, (id_docente, id_campus, numero_semestre))
    semestres = cursor.fetchall()
    # Obtener semestres ya contestados por el alumno
    cursor.execute("""
        SELECT id_semestre FROM evaluacion WHERE id_alumno = %s AND id_docente = %s
    """, (id_alumno, id_docente))
    semestres_contestados = {row['id_semestre'] for row in cursor.fetchall()}
    # Filtrar semestres no contestados
    semestres_filtrados = [s for s in semestres if s['id_semestre'] not in semestres_contestados]
    if request.accept_mimetypes['application/json']:
        return jsonify(semestres_filtrados)
    return {'semestres': semestres_filtrados}

# Ruta para mostrar la encuesta de evaluación
@app.route("/encuesta", methods=["POST"])
def encuesta():
    id_docente = request.form.get("id_docente")
    id_semestre = request.form.get("id_semestre")
    id_alumno = session.get('id_alumno')

    # Validar que el semestre corresponde al docente, ambos son del mismo campus y mismo semestre que el alumno
    cursor.execute("SELECT id_campus, numero_semestre FROM alumnos WHERE id_alumno = %s", (id_alumno,))
    alumno = cursor.fetchone()
    id_campus = alumno['id_campus'] if alumno else None
    numero_semestre = alumno['numero_semestre'] if alumno else None
    cursor.execute("""
        SELECT * FROM semestre WHERE id_semestre = %s AND id_docente = %s AND id_campus = %s AND numero = %s
    """, (id_semestre, id_docente, id_campus, numero_semestre))
    semestre = cursor.fetchone()
    if not semestre:
        return "No tienes permiso para evaluar este semestre.", 403

    # Guardar temporalmente en sesión para que /guardar pueda crear la evaluación si el form no trae los hidden inputs
    session['pending_eval'] = {'id_docente': id_docente, 'id_semestre': id_semestre}

    # No crear la fila en evaluacion aquí — se hará al guardar las respuestas.
    preguntas = [
        "¿Qué tan claro y comprensible explica los temas durante la clase?",
        "¿En qué medida domina el contenido de la materia que imparte?",
        "¿Qué tan bien responde a las dudas o preguntas de los estudiantes?",
        "¿Qué tan organizado(a) es al estructurar y presentar los contenidos?",
        "¿Qué tanto fomenta la participación activa de los alumnos en clase?",
        "¿En qué medida utiliza ejemplos prácticos o aplicaciones reales para explicar los temas?",
        "¿Qué tan efectivo(a) es al utilizar recursos didácticos o tecnológicos para apoyar su enseñanza?",
        "¿Qué tan justo(a) y claro(a) es al evaluar el desempeño de los estudiantes?",
        "¿Qué tanto motiva a los estudiantes a interesarse en la materia?",
        "¿Qué tan accesible y disponible está fuera de clase para apoyar a los estudiantes?"
    ]

    # Enviar id_docente e id_semestre al template; el backend creará la evaluación cuando se guarden las respuestas.
    return render_template("encuesta.html", id_docente=id_docente, id_semestre=id_semestre, preguntas=preguntas)

# Ruta para guardar respuestas y comentarios de la encuesta
@app.route("/guardar", methods=["POST"])
def guardar():
    # Si la plantilla envía id_eval (por compatibilidad), usarlo; si no, crear la evaluación ahora.
    id_eval = request.form.get("id_eval")
    id_docente = request.form.get("id_docente")
    id_semestre = request.form.get("id_semestre")
    id_alumno = session.get('id_alumno')

    # Recuperar datos desde session si no vienen en el POST (por plantillas que no envían hidden fields)
    if (not id_docente or not id_semestre):
        pending = session.get('pending_eval')
        if pending:
            id_docente = id_docente or pending.get('id_docente')
            id_semestre = id_semestre or pending.get('id_semestre')

    # Si tenemos id_eval, obtener los ids asociados (por seguridad)
    if id_eval and id_eval.strip() != "":
        try:
            cursor.execute("SELECT id_docente, id_semestre FROM evaluacion WHERE id_evaluacion = %s", (id_eval,))
            ev = cursor.fetchone()
            if ev:
                id_docente = id_docente or ev.get('id_docente')
                id_semestre = id_semestre or ev.get('id_semestre')
        except Exception:
            pass

    # Ahora validar que existan los datos necesarios para crear la evaluación si hace falta
    if not id_eval or id_eval.strip() == "":
        if not id_docente or not id_semestre or not id_alumno:
            return "Datos insuficientes para registrar la evaluación.", 400
        # Crear la evaluación ahora que el alumno envía respuestas
        cursor.callproc("registrar_evaluacion", (int(id_docente), int(id_semestre), int(id_alumno)))
        db.commit()
        cursor.execute("SELECT LAST_INSERT_ID() AS id_eval")
        id_eval = cursor.fetchone()['id_eval']

    # Insertar respuestas
    for key in request.form:
        if key.startswith("pregunta_"):
            pregunta = request.form.get(key, "").strip()
            idx = key.split('_')[1]
            escala = request.form.get(f"escala_{idx}", "").strip()
            cursor.callproc("insertar_respuesta", (int(id_eval), pregunta, escala))
    db.commit()

    # Insertar comentario si existe
    comentario = request.form.get("comentario")
    if comentario and comentario.strip():
        cursor.callproc("insertar_comentario", (int(id_eval), comentario.strip()))
        db.commit()

    # Limpiar pending_eval de la sesión
    session.pop('pending_eval', None)

    return render_template("resultado.html")

# Ruta para cerrar sesión
@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for('login'))

# Ruta para admin: muestra reporte general y estadísticas
@app.route("/admin")
def admin():
    if session.get('tipo_usuario') != 'admin':
        return redirect(url_for('login'))
    
    # Obtener reporte de evaluaciones
    cursor.callproc("reporte_admin_evaluacion")
    evaluaciones = []
    for result in cursor.stored_results():
        evaluaciones = result.fetchall()
    
    # Obtener estadísticas (ahora devolvemos 6 conjuntos: total_campus, total_alumnos, por_campus, por_carrera, sin_evaluar, alumnos_estado)
    cursor.callproc("estadisticas_evaluacion")
    stats = {}
    results = list(cursor.stored_results())
    
    if len(results) >= 6:
        stats['total_campus'] = results[0].fetchone()['total_campus']
        stats['total_alumnos'] = results[1].fetchone()['total_alumnos']
        stats['por_campus'] = results[2].fetchall()
        stats['por_carrera'] = results[3].fetchall()
        stats['sin_evaluar'] = results[4].fetchall()            # para compatibilidad
        stats['alumnos_estado'] = results[5].fetchall()         # nuevo: lista con total_requerido/completadas/pendientes por alumno
    else:
        # Mantener compatibilidad si el procedimiento no devolviera el nuevo conjunto
        stats['total_campus'] = None
        stats['total_alumnos'] = None
        stats['por_campus'] = []
        stats['por_carrera'] = []
        stats['sin_evaluar'] = []
        stats['alumnos_estado'] = []

    return render_template("admin.html", evaluaciones=evaluaciones, stats=stats)

# Ejecución de la app Flask en modo debug
if __name__ == "__main__":
    app.run(debug=True)