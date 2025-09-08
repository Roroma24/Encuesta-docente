from flask import Flask, render_template, request, jsonify
import mysql.connector

app = Flask(__name__)

db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="Saltamontes71#",
    database="evaluacion_d"
)
cursor = db.cursor(dictionary=True)

@app.route("/")
def index():
    cursor.execute("SELECT * FROM docentes")
    docentes = cursor.fetchall()
    return render_template("index.html", docentes=docentes)

@app.route("/semestres/<int:id_docente>")
def semestres_por_docente(id_docente):
    # Consulta segura con parámetros
    cursor.execute("SELECT * FROM semestre WHERE id_docente = %s", (id_docente,))
    semestres = cursor.fetchall()
    # Retorna JSON si lo piden con Accept: application/json
    if request.accept_mimetypes['application/json']:
        return jsonify(semestres)
    return {'semestres': semestres}

@app.route("/encuesta", methods=["POST"])
def encuesta():
    id_docente = request.form.get("id_docente")
    id_semestre = request.form.get("id_semestre")

    cursor.execute(
        "INSERT INTO evaluacion (id_docente, id_semestre) VALUES (%s, %s)",
        (id_docente, id_semestre)
    )
    db.commit()
    id_eval = cursor.lastrowid

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

@app.route("/guardar", methods=["POST"])
def guardar():
    id_eval = request.form.get("id_eval")

    for key in request.form:
        if key.startswith("pregunta_"):
            pregunta = request.form.get(key, "").strip()
            respuesta = request.form.get(f"respuesta_{key.split('_')[1]}", "").strip()
            escala = request.form.get(f"escala_{key.split('_')[1]}", "").strip()

            cursor.execute(
                "INSERT INTO respuestas (id_evaluacion, pregunta, respuesta, escala) VALUES (%s, %s, %s, %s)",
                (id_eval, pregunta, respuesta, escala)
            )
    db.commit()

    comentario = request.form.get("comentario")
    if comentario and comentario.strip():
        cursor.execute(
            "INSERT INTO comentarios (id_evaluacion, comentario) VALUES (%s, %s)",
            (id_eval, comentario.strip())
        )
        db.commit()

    return render_template("resultado.html")

if __name__ == "__main__":
    app.run(debug=True)
