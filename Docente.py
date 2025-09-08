import mysql.connector

# Conexión a MySQL
conexion = mysql.connector.connect(
    host="localhost",
    user="root",          
    password="Ror@$2405",  
    database="evaluacion_d"
)

cursor = conexion.cursor()

def mostrar_docentes():
    cursor.execute("SELECT id_docente, nombre, apellidop, apellidom FROM docentes")
    docentes = cursor.fetchall()
    print("\n=== DOCENTES DISPONIBLES ===")
    for d in docentes:
        print(f"{d[0]} - {d[1]} {d[2]} {d[3]}")
    return docentes

def mostrar_semestres():
    cursor.execute("SELECT id_semestre, numero, materia, curso FROM semestre")
    semestres = cursor.fetchall()
    print("\n=== SEMESTRES DISPONIBLES ===")
    for s in semestres:
        print(f"{s[0]} - Semestre {s[1]} | {s[2]} ({s[3]})")
    return semestres

def registrar_evaluacion(id_docente, id_semestre):
    # Crear la evaluación general (1 por persona/docente/semestre)
    cursor.execute(
        "INSERT INTO evaluacion (id_docente, id_semestre) VALUES (%s, %s)",
        (id_docente, id_semestre)
    )
    id_eval = cursor.lastrowid  # mismo ID para todas las respuestas

    preguntas = [
        "¿Explica claramente los conceptos?",
        "¿Fomenta la participación en clase?",
        "¿Entrega retroalimentación útil?",
        "¿Utiliza recursos tecnológicos apropiados?"
    ]

    for pregunta in preguntas:
        print(f"\nPregunta: {pregunta}")
        respuesta = input("Respuesta (texto): ")
        escala = input("Calificación (1 a 5): ")

        # Insertar cada respuesta
        cursor.execute(
            "INSERT INTO respuestas (id_evaluacion, pregunta, respuesta, escala) VALUES (%s, %s, %s, %s)",
            (id_eval, pregunta, respuesta, escala)
        )

    # Resumen global
    resumen = input("\nResumen global (Deficiente, Regular, Bueno, Muy bueno, Excelente): ")
    cursor.execute(
        "INSERT INTO criterios (resumen, id_evaluacion) VALUES (%s, %s)",
        (resumen, id_eval)
    )

    # Comentario adicional
    comentario = input("Comentario adicional: ")
    cursor.execute(
        "INSERT INTO comentarios (id_evaluacion, comentario) VALUES (%s, %s)",
        (id_eval, comentario)
    )

    conexion.commit()
    print(f"\n✅ Evaluación {id_eval} registrada con éxito.")

def main():
    print("=== SISTEMA DE ENCUESTAS DOCENTES ===")

    mostrar_docentes()
    id_docente = int(input("\nSeleccione el ID del docente a evaluar: "))

    mostrar_semestres()
    id_semestre = int(input("\nSeleccione el ID del semestre: "))

    registrar_evaluacion(id_docente, id_semestre)

    cursor.close()
    conexion.close()

if __name__ == "__main__":
    main()
