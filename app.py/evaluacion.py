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
    password="Ror@$2405",
    database="evaluacion_d"
)
cursor = db.cursor(dictionary=True)

# Ruta principal: Login de usuario (alumno o docente)
@app.route("/", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        matricula = request.form.get("matricula", "").strip()
        cursor.callproc("ver_alumnos")
        alumno = None
        for result in cursor.stored_results():
            for row in result.fetchall():
                if row['matricula'] == matricula:
                    alumno = row
                    break
        if alumno:
            session['tipo_usuario'] = 'alumno'
            session['matricula'] = matricula
            session['id_alumno'] = alumno['id_alumno']
            return redirect(url_for('index'))
        cursor.callproc("ver_docentes")
        docente = None
        for result in cursor.stored_results():
            for row in result.fetchall():
                if row['matricula'] == matricula:
                    docente = row
                    break
        if docente:
            session['tipo_usuario'] = 'docente'
            session['matricula'] = matricula
            session['id_docente'] = docente['id_docente']
            return redirect(url_for('profesor'))
        return render_template("login.html", error="Matrícula no encontrada")
    return render_template("login.html")

# Ruta para alumnos: muestra docentes y semestres contestados
@app.route("/inicio")
def index():
    if session.get('tipo_usuario') != 'alumno':
        return redirect(url_for('login'))
    cursor.callproc("ver_docentes")
    docentes = []
    for result in cursor.stored_results():
        docentes = result.fetchall()
    id_alumno = session.get('id_alumno')
    cursor.callproc("ver_evaluaciones")
    semestres_contestados = set()
    for result in cursor.stored_results():
        for row in result.fetchall():
            if row['id_alumno'] == id_alumno:
                cursor2 = db.cursor(dictionary=True)
                cursor2.execute("SELECT id_semestre FROM evaluacion e JOIN respuestas r ON e.id_evaluacion = r.id_evaluacion WHERE e.id_evaluacion = %s GROUP BY e.id_semestre", (row['id_evaluacion'],))
                for r in cursor2.fetchall():
                    semestres_contestados.add(r['id_semestre'])
                cursor2.close()
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
    cursor.callproc("ver_semestres_por_docente", (id_docente,))
    semestres = []
    for result in cursor.stored_results():
        semestres = result.fetchall()
    cursor.callproc("ver_semestres_contestados", (id_docente, id_alumno))
    semestres_contestados = set()
    for result in cursor.stored_results():
        semestres_contestados = {row['id_semestre'] for row in result.fetchall()}
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
    cursor.callproc("registrar_evaluacion", (id_docente, id_semestre, id_alumno))
    db.commit()
    cursor.execute("SELECT LAST_INSERT_ID() AS id_eval")
    id_eval = cursor.fetchone()['id_eval']
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
    return render_template("encuesta.html", id_eval=id_eval, preguntas=preguntas)

# Ruta para guardar respuestas y comentarios de la encuesta
@app.route("/guardar", methods=["POST"])
def guardar():
    id_eval = request.form.get("id_eval")
    for key in request.form:
        if key.startswith("pregunta_"):
            pregunta = request.form.get(key, "").strip()
            idx = key.split('_')[1]
            escala = request.form.get(f"escala_{idx}", "").strip()
            cursor.callproc("insertar_respuesta", (id_eval, pregunta, escala))
    db.commit()
    comentario = request.form.get("comentario")
    if comentario and comentario.strip():
        cursor.callproc("insertar_comentario", (id_eval, comentario.strip()))
        db.commit()
    return render_template("resultado.html")

# Ruta para cerrar sesión
@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for('login'))

# Ejecución de la app Flask en modo debug
if __name__ == "__main__":
    app.run(debug=True)