from flask import Flask, render_template, request, jsonify, redirect, url_for, session
import mysql.connector

app = Flask(__name__)
app.secret_key = "supersecretkey"  

db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="Ror@$2405",
    database="evaluacion_d"
)
cursor = db.cursor(dictionary=True)

@app.route("/", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        matricula = request.form.get("matricula", "").strip()
        cursor.execute("SELECT * FROM alumnos WHERE matricula = %s", (matricula,))
        alumno = cursor.fetchone()
        if alumno:
            session['tipo_usuario'] = 'alumno'
            session['matricula'] = matricula
            return redirect(url_for('index'))
        cursor.execute("SELECT * FROM docentes WHERE matricula = %s", (matricula,))
        docente = cursor.fetchone()
        if docente:
            session['tipo_usuario'] = 'docente'
            session['matricula'] = matricula
            session['id_docente'] = docente['id_docente']
            return redirect(url_for('profesor'))
        return render_template("login.html", error="Matrícula no encontrada")
    return render_template("login.html")

@app.route("/inicio")
def index():
    if session.get('tipo_usuario') != 'alumno':
        return redirect(url_for('login'))
    cursor.execute("SELECT * FROM docentes")
    docentes = cursor.fetchall()
    return render_template("index.html", docentes=docentes)

@app.route("/profesor")
def profesor():
    if session.get('tipo_usuario') != 'docente':
        return redirect(url_for('login'))
    id_docente = session.get('id_docente')
    cursor.execute("""
        SELECT 
            d.nombre AS nombre_docente,
            d.apellidop,
            d.apellidom,
            s.numero AS semestre_numero,
            s.materia,
            s.curso,
            s.fecha_i,
            s.fecha_fin,
            SUM(CAST(r.escala AS UNSIGNED)) AS total_puntos,
            COUNT(r.id_respuesta) AS total_respuestas,
            ROUND(AVG(CAST(r.escala AS UNSIGNED)),2) AS promedio,
            CASE
                WHEN AVG(CAST(r.escala AS UNSIGNED)) >= 4.5 THEN 'Excelente profesor'
                WHEN AVG(CAST(r.escala AS UNSIGNED)) >= 4.0 THEN 'Muy buen profesor'
                WHEN AVG(CAST(r.escala AS UNSIGNED)) >= 3.0 THEN 'Buen profesor'
                WHEN AVG(CAST(r.escala AS UNSIGNED)) >= 2.0 THEN 'Profesor regular'
                ELSE 'Mal profesor'
            END AS evaluacion_final
        FROM docentes d
        JOIN evaluacion e ON d.id_docente = e.id_docente
        JOIN respuestas r ON e.id_evaluacion = r.id_evaluacion
        JOIN semestre s ON e.id_semestre = s.id_semestre
        WHERE d.id_docente = %s
        GROUP BY d.id_docente, s.id_semestre
        ORDER BY s.fecha_i DESC
    """, (id_docente,))
    resultados = cursor.fetchall()
    return render_template("profesor.html", resultados=resultados)

@app.route("/semestres/<int:id_docente>")
def semestres_por_docente(id_docente):
    cursor.execute("SELECT * FROM semestre WHERE id_docente = %s", (id_docente,))
    semestres = cursor.fetchall()
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
            idx = key.split('_')[1]
            escala = request.form.get(f"escala_{idx}", "").strip()

            cursor.execute(
                "INSERT INTO respuestas (id_evaluacion, pregunta, escala) VALUES (%s, %s, %s)",
                (id_eval, pregunta, escala)
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

@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for('login'))

if __name__ == "__main__":
    app.run(debug=True)
