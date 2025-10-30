""" 
Autores: Axel Castañeda Sánchez y Luis Roberto Rodríguez Marroquin
Descripción: Archivo principal de la aplicación Flask para la evaluación docente.
"""

# Importación de librerías y configuración de la app Flask
from flask import Flask, render_template, request, jsonify, redirect, url_for, session
import mysql.connector
import json

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

    # Verificar estado de evaluaciones docentes y de servicios
    cursor.execute("""
        SELECT 
            (SELECT COUNT(*) FROM semestre s 
             WHERE s.id_campus = %s AND s.numero = %s) as total_docentes,
            (SELECT COUNT(*) FROM evaluacion e 
             JOIN semestre s ON e.id_semestre = s.id_semestre 
             WHERE e.id_alumno = %s AND s.id_campus = %s AND s.numero = %s) as completadas_docentes,
            EXISTS(SELECT 1 FROM evaluacion_servicios WHERE id_alumno = %s) as servicios_completado
    """, (id_campus, numero_semestre, id_alumno, id_campus, numero_semestre, id_alumno))
    
    estado = cursor.fetchone()
    
    # Si no hay más evaluaciones docentes pendientes y falta la de servicios,
    # mostrar la página de selección dentro de index
    if estado['total_docentes'] == estado['completadas_docentes'] and not estado['servicios_completado']:
        # renderizar index con bandera para mostrar la selección de la encuesta de servicios
        return render_template("index.html",
                               docentes=[],
                               servicios_completado=False,
                               servicios_pendiente=True)
    
    # Si completó todo (docentes + servicios), mostrar página final
    if estado['total_docentes'] == estado['completadas_docentes'] and estado['servicios_completado']:
        return render_template("finale.html")

    # Obtener semestres disponibles para el alumno y que no hayan sido contestados
    cursor.execute("""
        SELECT s.* FROM semestre s
        WHERE s.id_campus = %s AND s.numero = %s
        AND s.id_semestre NOT IN (
            SELECT id_semestre FROM evaluacion WHERE id_alumno = %s
        )
    """, (id_campus, numero_semestre, id_alumno))
    semestres_disponibles = cursor.fetchall()

    # Determinar docente(s) que tienen al menos un semestre disponible
    docente_ids = {s['id_docente'] for s in semestres_disponibles}
    if docente_ids:
        placeholders = ",".join(["%s"] * len(docente_ids))
        cursor.execute(f"SELECT * FROM docentes WHERE id_docente IN ({placeholders})", tuple(docente_ids))
        docentes = cursor.fetchall()
    else:
        docentes = []

    # También pasar el estado de la evaluación de servicios al template (asegurarse bandera presente)
    return render_template("index.html", 
                         docentes=docentes, 
                         servicios_completado=estado['servicios_completado'],
                         servicios_pendiente=False)

# Ruta para docentes: muestra reporte de evaluaciones
@app.route("/profesor")
def profesor():
    if session.get('tipo_usuario') != 'docente':
        return redirect(url_for('login'))
    id_docente = session.get('id_docente')
    resultados = []
    try:
        # Llamar la función que devuelve JSON
        cursor.execute("SELECT fn_reporte_evaluacion(%s) AS data", (id_docente,))
        row = cursor.fetchone()
        data_json = row['data'] if row else None
        if data_json:
            # mysql-connector devuelve JSON como str; parsear a lista de dicts
            resultados = json.loads(data_json)
        else:
            resultados = []
    except Exception:
        # Fallback: si la función no está disponible o falla, usar el procedimiento antiguo y filtrar
        try:
            cursor.callproc("reporte_evaluacion")
            for result in cursor.stored_results():
                for row in result.fetchall():
                    if row and row.get('nombre_docente'):
                        cursor2 = db.cursor(dictionary=True)
                        cursor2.execute(
                            "SELECT id_docente FROM docentes WHERE nombre = %s AND apellidop = %s AND apellidom = %s",
                            (row['nombre_docente'], row['apellidop'], row['apellidom'])
                        )
                        doc = cursor2.fetchone()
                        cursor2.close()
                        if doc and doc.get('id_docente') == id_docente:
                            resultados.append(row)
        except Exception:
            # En caso de error silencioso, dejar resultados vacíos
            resultados = []
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
    # Siempre devolver JSON para el fetch del frontend
    return jsonify(semestres_filtrados)

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
    
    # Obtener estadísticas 
    cursor.callproc("estadisticas_evaluacion")
    stats = {}
    results = list(cursor.stored_results())
    
    if len(results) >= 6:
        stats['total_campus'] = results[0].fetchone()['total_campus']
        stats['total_alumnos'] = results[1].fetchone()['total_alumnos']
        stats['por_campus'] = results[2].fetchall()
        stats['por_carrera'] = results[3].fetchall()
        stats['sin_evaluar'] = results[4].fetchall()            
        stats['alumnos_estado'] = results[5].fetchall()         
    else:
        # Mantener compatibilidad si el procedimiento no devuelve el nuevo conjunto
        stats['total_campus'] = None
        stats['total_alumnos'] = None
        stats['por_campus'] = []
        stats['por_carrera'] = []
        stats['sin_evaluar'] = []
        stats['alumnos_estado'] = []

    return render_template("admin.html", evaluaciones=evaluaciones, stats=stats)

# Soporte GET y POST para mostrar el formulario de servicios 
@app.route("/encuesta_servicios", methods=["GET", "POST"])
def encuesta_servicios():
    if session.get('tipo_usuario') != 'alumno':
        return redirect(url_for('login'))
    id_alumno = session.get('id_alumno')
    # comprobar si ya hizo la encuesta de servicios
    cursor.execute("SELECT 1 FROM evaluacion_servicios WHERE id_alumno = %s", (id_alumno,))
    if cursor.fetchone():
        return render_template("finale.html")
    preguntas = [
        "¿Cómo califica la limpieza general de las instalaciones?",
        "¿Qué tan adecuadas son las instalaciones para el desarrollo académico?",
        "¿Cómo evalúa el servicio de biblioteca?",
        "¿Qué tan eficiente es el servicio de control escolar?",
        "¿Cómo califica la atención del personal administrativo?",
        "¿Qué tan bueno es el servicio de cafetería?",
        "¿Cómo evalúa la seguridad dentro del campus?",
        "¿Qué tan adecuado es el equipamiento de los laboratorios?",
        "¿Cómo califica el servicio de internet y recursos tecnológicos?",
        "¿Qué tan eficiente es el proceso de inscripción y reinscripción?"
    ]
    return render_template("servicios.html", preguntas=preguntas)

# Guardar respuestas de la encuesta de servicios
@app.route("/guardar_servicios", methods=["POST"])
def guardar_servicios():
    if session.get('tipo_usuario') != 'alumno':
        return redirect(url_for('login'))
    id_alumno = session.get('id_alumno')
    # obtener campus alumno
    cursor.execute("SELECT id_campus FROM alumnos WHERE id_alumno = %s", (id_alumno,))
    row = cursor.fetchone()
    id_campus = row['id_campus'] if row else None
    # insertar evaluacion_servicios
    cursor.execute("INSERT INTO evaluacion_servicios (id_alumno, id_campus) VALUES (%s, %s)", (id_alumno, id_campus))
    db.commit()
    id_eval_serv = cursor.lastrowid
    # insertar respuestas_servicios
    for key in request.form:
        if key.startswith("pregunta_"):
            pregunta = request.form.get(key, "").strip()
            idx = key.split('_')[1]
            escala = request.form.get(f"escala_{idx}", "").strip()
            cursor.execute("INSERT INTO respuestas_servicios (id_evaluacion_servicios, pregunta, escala) VALUES (%s, %s, %s)",
                           (id_eval_serv, pregunta, escala))
    db.commit()
    return render_template("resultado.html")

# Ejecución de la app Flask en modo debug
if __name__ == "__main__":
    app.run(debug=True)