/***
Autores: Axel Castañeda Sánchez y Luis Roberto Rodríguez Marroquin
Descripción: Script SQL para crear la base de datos y las tablas necesarias para el sistema de evaluación docente.
***/

-- Crear la base de datos de evaluacion_d
CREATE DATABASE IF NOT EXISTS evaluacion_d;

-- Usar esquema predeterminado
USE evaluacion_d;

-- Tabla de docentes
CREATE TABLE docentes (
    id_docente INT AUTO_INCREMENT PRIMARY KEY,
    matricula VARCHAR(10) NOT NULL UNIQUE,
    nombre VARCHAR(256) NOT NULL,
    apellidop VARCHAR(256) NOT NULL,
    apellidom VARCHAR(256) NOT NULL,
    correo VARCHAR(256) UNIQUE,
    departamento VARCHAR(256) NOT NULL
);

-- Tabla de semestres
CREATE TABLE semestre (
    id_semestre INT AUTO_INCREMENT PRIMARY KEY,
    id_docente INT NOT NULL,
    numero ENUM('1','2','3','4','5','6','7','8','9'),
    materia VARCHAR(256),
    curso VARCHAR(256),
    fecha_i DATE,
    fecha_fin DATE,
    FOREIGN KEY (id_docente) REFERENCES docentes(id_docente)
);

-- Tabla de alumnos
CREATE TABLE alumnos (
    id_alumno INT AUTO_INCREMENT PRIMARY KEY,
    matricula VARCHAR(10) NOT NULL UNIQUE,
    nombre VARCHAR(256) NOT NULL,
    apellidop VARCHAR(256) NOT NULL,
    apellidom VARCHAR(256) NOT NULL,
    correo VARCHAR(256) UNIQUE NOT NULL
);

-- Tabla de evaluaciones
CREATE TABLE evaluacion (
    id_evaluacion INT AUTO_INCREMENT PRIMARY KEY,
    id_docente INT NOT NULL,
    id_semestre INT NOT NULL,
    id_alumno INT NOT NULL,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_docente) REFERENCES docentes(id_docente),
    FOREIGN KEY (id_semestre) REFERENCES semestre(id_semestre),
    FOREIGN KEY (id_alumno) REFERENCES alumnos(id_alumno)
);

-- Tabla de respuestas
CREATE TABLE respuestas (
    id_respuesta INT AUTO_INCREMENT PRIMARY KEY,
    id_evaluacion INT NOT NULL,
    pregunta TEXT NOT NULL,
    escala ENUM('1','2','3','4','5'),
    FOREIGN KEY (id_evaluacion) REFERENCES evaluacion(id_evaluacion)
);

-- Tabla de comentarios
CREATE TABLE comentarios (
    id_comentario INT AUTO_INCREMENT PRIMARY KEY,
    id_evaluacion INT NOT NULL,
    comentario TEXT NOT NULL,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_evaluacion) REFERENCES evaluacion(id_evaluacion)
);

-- Procedimientos almacenados
DELIMITER $$

-- Procedimiento para insertar docentes
CREATE PROCEDURE insertar_docente(
    IN p_matricula VARCHAR(10),
    IN p_nombre VARCHAR(256),
    IN p_apellidop VARCHAR(256),
    IN p_apellidom VARCHAR(256),
    IN p_correo VARCHAR(256),
    IN p_departamento VARCHAR(256)
)
BEGIN
    INSERT INTO docentes (matricula, nombre, apellidop, apellidom, correo, departamento)
    VALUES (p_matricula, p_nombre, p_apellidop, p_apellidom, p_correo, p_departamento);
END$$

-- Procedimiento para insertar semestres
CREATE PROCEDURE insertar_semestre(
    IN p_id_docente INT,
    IN p_numero ENUM('1','2','3','4','5','6','7','8','9'),
    IN p_materia VARCHAR(256),
    IN p_curso VARCHAR(256),
    IN p_fecha_i DATE,
    IN p_fecha_fin DATE
)
BEGIN
    INSERT INTO semestre (id_docente, numero, materia, curso, fecha_i, fecha_fin)
    VALUES (p_id_docente, p_numero, p_materia, p_curso, p_fecha_i, p_fecha_fin);
END$$

-- Procedimiento para insertar alumnos
CREATE PROCEDURE insertar_alumno(
    IN p_matricula VARCHAR(10),
    IN p_nombre VARCHAR(256),
    IN p_apellidop VARCHAR(256),
    IN p_apellidom VARCHAR(256),
    IN p_correo VARCHAR(256)
)
BEGIN
    INSERT INTO alumnos (matricula, nombre, apellidop, apellidom, correo)
    VALUES (p_matricula, p_nombre, p_apellidop, p_apellidom, p_correo);
END$$

-- Procedimiento para ver docentes
CREATE PROCEDURE ver_docentes()
BEGIN
    SELECT * FROM docentes;
END$$

-- Procedimiento para ver semestres
CREATE PROCEDURE ver_semestres()
BEGIN
    SELECT * FROM semestre;
END$$

-- Procedimiento para ver alumnos
CREATE PROCEDURE ver_alumnos()
BEGIN
    SELECT * FROM alumnos;
END$$

-- Procedimiento para ver evaluaciones
CREATE PROCEDURE ver_evaluaciones()
BEGIN
    SELECT * FROM evaluacion;
END$$

-- Procedimiento para ver comentarios
CREATE PROCEDURE ver_comentarios()
BEGIN
    SELECT * FROM comentarios;
END$$

-- Procedimiento para ver respuestas
CREATE PROCEDURE ver_respuestas()
BEGIN
    SELECT * FROM respuestas;
END$$

-- Procedimiento para generar reporte de evaluaciones
CREATE PROCEDURE reporte_evaluacion()
BEGIN
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
    GROUP BY d.id_docente, s.id_semestre;
END$$

DELIMITER ;

DELIMITER $$

-- Procedimiento para registrar evaluaciones
CREATE PROCEDURE registrar_evaluacion(
    IN p_id_docente INT,
    IN p_id_semestre INT,
    IN p_id_alumno INT
)
BEGIN
    INSERT INTO evaluacion (id_docente, id_semestre, id_alumno)
    VALUES (p_id_docente, p_id_semestre, p_id_alumno);
END$$

-- Procedimiento para insertar respuestas
CREATE PROCEDURE insertar_respuesta(
    IN p_id_evaluacion INT,
    IN p_pregunta TEXT,
    IN p_escala ENUM('1','2','3','4','5')
)
BEGIN
    INSERT INTO respuestas (id_evaluacion, pregunta, escala)
    VALUES (p_id_evaluacion, p_pregunta, p_escala);
END$$

-- Procedimiento para insertar comentarios
CREATE PROCEDURE insertar_comentario(
    IN p_id_evaluacion INT,
    IN p_comentario TEXT
)
BEGIN
    INSERT INTO comentarios (id_evaluacion, comentario)
    VALUES (p_id_evaluacion, p_comentario);
END$$

-- Procedimiento para ver semestres por docente
CREATE PROCEDURE ver_semestres_por_docente(
    IN p_id_docente INT
)
BEGIN
    SELECT * FROM semestre WHERE id_docente = p_id_docente;
END$$

-- Procedimiento para ver semestres contestados por alumno
CREATE PROCEDURE ver_semestres_contestados(
    IN p_id_docente INT,
    IN p_id_alumno INT
)
BEGIN
    SELECT e.id_semestre
    FROM evaluacion e
    JOIN respuestas r ON e.id_evaluacion = r.id_evaluacion
    WHERE e.id_docente = p_id_docente AND e.id_alumno = p_id_alumno
    GROUP BY e.id_semestre;
END$$

DELIMITER ;

-- Insertar docentes
CALL insertar_docente('D1234567', 'María', 'González', 'López', 'maria.gonzalez@uvm.mx', 'Ingeniería');
CALL insertar_docente('D2345678', 'Carlos', 'Ramírez', 'Torres', 'carlos.ramirez@uvm.mx', 'Ciencias Básicas');
CALL insertar_docente('D3456789', 'Ana', 'Martínez', 'Soto', 'ana.martinez@uvm.mx', 'Sistemas Computacionales');
CALL insertar_docente('D4567890', 'Luis', 'Hernández', 'Pérez', 'luis.hernandez@uvm.mx', 'Matemáticas');

-- Insertar semestres 
CALL insertar_semestre(1, '5', 'Bases de Datos', 'BD-501', '2025-08-12', '2025-12-15');
CALL insertar_semestre(2, '6', 'Redes de Computadoras', 'RC-601', '2025-08-12', '2025-12-15');
CALL insertar_semestre(3, '7', 'Seguridad Informática', 'SI-701', '2025-08-12', '2025-12-15');
CALL insertar_semestre(4, '8', 'Arquitectura de Software', 'AS-801', '2025-08-12', '2025-12-15');
CALL insertar_semestre(4, '1', 'Física', 'F-101', '2025-08-12', '2025-12-15');
CALL insertar_semestre(4, '3', 'Cálculo Diferencial', 'CD-301', '2025-08-12', '2025-12-15');

-- Insertar alumnos
CALL insertar_alumno('A1234567', 'Juan', 'Pérez', 'López', 'juan.perez@uvmnet.edu');
CALL insertar_alumno('A2345678', 'Mariana', 'Hernández', 'Gómez', 'mariana.hernandez@uvmnet.edu');
CALL insertar_alumno('A3456789', 'Roberto', 'Martínez', 'Soto', 'roberto.martinez@uvmnet.edu');

-- Consultar todos los docentes
CALL ver_docentes();

-- Consultar todos los semestres
CALL ver_semestres();

-- Consultar todos los alumnos
CALL ver_alumnos();

-- Consultar todas las evaluaciones 
CALL ver_evaluaciones();

-- Consultar todas las respuestas 
CALL ver_respuestas();

-- Consultar todos los comentarios 
CALL ver_comentarios();