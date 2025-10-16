/***
Autores: Axel Castañeda Sánchez y Luis Roberto Rodríguez Marroquin
Descripción: Script SQL para crear la base de datos y las tablas necesarias para el sistema de evaluación docente.
***/

-- Borrar la base de datos si existe
DROP DATABASE IF EXISTS evaluacion_d;

-- Crear la base de datos de evaluacion_d
CREATE DATABASE IF NOT EXISTS evaluacion_d;

-- Usar esquema predeterminado
USE evaluacion_d;

-- Tabla de campus
CREATE TABLE campus (
    id_campus INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(256) NOT NULL UNIQUE,
    direccion VARCHAR(512),
    telefono VARCHAR(50)
);

-- Tabla de carreras
CREATE TABLE carreras (
    id_carrera INT AUTO_INCREMENT PRIMARY KEY,
    clave VARCHAR(50) UNIQUE,
    nombre VARCHAR(256) NOT NULL,
    duracion_semestres INT
);

-- Tabla de docentes
CREATE TABLE docentes (
    id_docente INT AUTO_INCREMENT PRIMARY KEY,
    matricula VARCHAR(10) NOT NULL UNIQUE,
    nombre VARCHAR(256) NOT NULL,
    apellidop VARCHAR(256) NOT NULL,
    apellidom VARCHAR(256) NOT NULL,
    correo VARCHAR(256) UNIQUE,
    departamento VARCHAR(256) NOT NULL,
    fecha_nacimiento DATE NULL,
    id_campus INT NOT NULL,
    FOREIGN KEY (id_campus) REFERENCES campus(id_campus)
);

-- Tabla de vinculación campus con carrera
CREATE TABLE campus_carrera (
    id INT AUTO_INCREMENT PRIMARY KEY,
    campus_id INT NOT NULL,
    carrera_id INT NOT NULL,
    fecha_inicio DATE,
    fecha_fin DATE,
    UNIQUE KEY uq_campus_carrera (campus_id, carrera_id),
    FOREIGN KEY (campus_id) REFERENCES campus(id_campus),
    FOREIGN KEY (carrera_id) REFERENCES carreras(id_carrera)
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
    id_campus INT NULL,
    id_carrera INT NULL,
    FOREIGN KEY (id_docente) REFERENCES docentes(id_docente),
    FOREIGN KEY (id_campus) REFERENCES campus(id_campus),
    FOREIGN KEY (id_carrera) REFERENCES carreras(id_carrera)
);

-- Tabla de alumnos
CREATE TABLE alumnos (
    id_alumno INT AUTO_INCREMENT PRIMARY KEY,
    matricula VARCHAR(10) NOT NULL UNIQUE,
    nombre VARCHAR(256) NOT NULL,
    apellidop VARCHAR(256) NOT NULL,
    apellidom VARCHAR(256) NOT NULL,
    correo VARCHAR(256) UNIQUE NOT NULL,
    id_campus INT NULL,
    id_carrera INT NULL,
    numero_semestre ENUM('1','2','3','4','5','6','7','8','9') NULL,
    fecha_nacimiento DATE NULL,
    FOREIGN KEY (id_campus) REFERENCES campus(id_campus),
    FOREIGN KEY (id_carrera) REFERENCES carreras(id_carrera)
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

-- PROCEDIMIENTOS ALMACENADOS

DELIMITER $$

-- Procedimiento para insertar docente con campus 
CREATE PROCEDURE insertar_docente_con_campus(
    IN p_matricula VARCHAR(10),
    IN p_nombre VARCHAR(256),
    IN p_apellidop VARCHAR(256),
    IN p_apellidom VARCHAR(256),
    IN p_correo VARCHAR(256),
    IN p_departamento VARCHAR(256),
    IN p_fecha_nacimiento DATE,
    IN p_id_campus INT
)
BEGIN
    INSERT INTO docentes (matricula, nombre, apellidop, apellidom, correo, departamento, fecha_nacimiento, id_campus)
    VALUES (p_matricula, p_nombre, p_apellidop, p_apellidom, p_correo, p_departamento, p_fecha_nacimiento, p_id_campus);
END$$

-- Procedimiento para insertar semestre con campus y carrera 
CREATE PROCEDURE insertar_semestre_con_vinculos(
    IN p_id_docente INT,
    IN p_numero ENUM('1','2','3','4','5','6','7','8','9'),
    IN p_materia VARCHAR(256),
    IN p_curso VARCHAR(256),
    IN p_fecha_i DATE,
    IN p_fecha_fin DATE,
    IN p_id_campus INT,
    IN p_id_carrera INT
)
BEGIN
    IF p_id_campus IS NOT NULL AND p_id_carrera IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM campus_carrera cc WHERE cc.campus_id = p_id_campus AND cc.carrera_id = p_id_carrera) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La carrera no está disponible en el campus seleccionado (proc insertar_semestre_con_vinculos).';
        END IF;
    END IF;
    INSERT INTO semestre (id_docente, numero, materia, curso, fecha_i, fecha_fin, id_campus, id_carrera)
    VALUES (p_id_docente, p_numero, p_materia, p_curso, p_fecha_i, p_fecha_fin, p_id_campus, p_id_carrera);
END$$

-- Procedimiento para insertar alumno con campus y carrera 
CREATE PROCEDURE insertar_alumno_con_vinculos(
    IN p_matricula VARCHAR(10),
    IN p_nombre VARCHAR(256),
    IN p_apellidop VARCHAR(256),
    IN p_apellidom VARCHAR(256),
    IN p_correo VARCHAR(256),
    IN p_id_campus INT,
    IN p_id_carrera INT,
    IN p_numero_semestre ENUM('1','2','3','4','5','6','7','8','9'),
    IN p_fecha_nacimiento DATE
)
BEGIN
    IF p_id_campus IS NOT NULL AND p_id_carrera IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM campus_carrera cc WHERE cc.campus_id = p_id_campus AND cc.carrera_id = p_id_carrera) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La carrera no está disponible en el campus seleccionado (proc insertar_alumno_con_vinculos).';
        END IF;
    END IF;
    INSERT INTO alumnos (matricula, nombre, apellidop, apellidom, correo, id_campus, id_carrera, numero_semestre, fecha_nacimiento)
    VALUES (p_matricula, p_nombre, p_apellidop, p_apellidom, p_correo, p_id_campus, p_id_carrera, p_numero_semestre, p_fecha_nacimiento);
END$$

-- Procedimientos de consulta 
CREATE PROCEDURE ver_docentes()
BEGIN
    SELECT * FROM docentes;
END$$

CREATE PROCEDURE ver_semestres()
BEGIN
    SELECT * FROM semestre;
END$$

CREATE PROCEDURE ver_alumnos()
BEGIN
    SELECT * FROM alumnos;
END$$

CREATE PROCEDURE ver_evaluaciones()
BEGIN
    SELECT * FROM evaluacion;
END$$

CREATE PROCEDURE ver_comentarios()
BEGIN
    SELECT * FROM comentarios;
END$$

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

-- Procedimiento para registrar evaluacione
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

-- Insertar campus
INSERT INTO campus (nombre, direccion, telefono) VALUES
('Campus Centro', 'Av. Principal 123', '55-1234-5678'),
('Campus Norte', 'Calle Norte 45', '55-9876-5432'),
('Campus Sur', 'Boulevard Sur 9', '55-1111-2222');

-- Insertar carreras
INSERT INTO carreras (clave, nombre, duracion_semestres) VALUES
('ING-SIST', 'Ingeniería en Sistemas', 9),
('ING-IND', 'Ingeniería Industrial', 9),
('LIC-ADM', 'Licenciatura en Administración', 8),
('LIC-PSI', 'Licenciatura en Psicología', 8);

-- Vincular carreras a campus 
INSERT INTO campus_carrera (campus_id, carrera_id, fecha_inicio) VALUES
(1, 1, '2020-01-01'), -- Campus Centro: Ingeniería en Sistemas
(1, 3, '2019-08-01'), -- Campus Centro: Administración
(2, 2, '2021-01-01'), -- Campus Norte: Ingeniería Industrial
(2, 4, '2022-01-01'), -- Campus Norte: Psicología
(3, 1, '2023-01-01'); -- Campus Sur: Ingeniería en Sistemas

-- Insertar docentes 
INSERT INTO docentes (matricula, nombre, apellidop, apellidom, correo, departamento, fecha_nacimiento, id_campus) VALUES
('D1234567', 'María', 'González', 'López', 'maria.gonzalez@uvm.mx', 'Ingeniería', '1980-03-15', 1),
('D2345678', 'Carlos', 'Ramírez', 'Torres', 'carlos.ramirez@uvm.mx', 'Ciencias Básicas', '1978-07-22', 2),
('D3456789', 'Ana', 'Martínez', 'Soto', 'ana.martinez@uvm.mx', 'Sistemas Computacionales', '1985-01-30', 1),
('D4567890', 'Luis', 'Hernández', 'Pérez', 'luis.hernandez@uvm.mx', 'Matemáticas', '1975-11-11', 3);

-- Insertar semestres 
CALL insertar_semestre_con_vinculos(1, '5', 'Bases de Datos', 'BD-501', '2025-08-12', '2025-12-15', 1, 1);
CALL insertar_semestre_con_vinculos(2, '6', 'Redes de Computadoras', 'RC-601', '2025-08-12', '2025-12-15', 2, 2);
CALL insertar_semestre_con_vinculos(3, '7', 'Seguridad Informática', 'SI-701', '2025-08-12', '2025-12-15', 1, 1);
CALL insertar_semestre_con_vinculos(4, '8', 'Arquitectura de Software', 'AS-801', '2025-08-12', '2025-12-15', 1, 1);

-- Insertar alumnos vinculados a campus y carrera 
CALL insertar_alumno_con_vinculos('A1234567', 'Juan', 'Pérez', 'López', 'juan.perez@uvmnet.edu', 1, 1, '5', '2002-04-09');
CALL insertar_alumno_con_vinculos('A2345678', 'Mariana', 'Hernández', 'Gómez', 'mariana.hernandez@uvmnet.edu', 2, 4, '6', '2001-11-03');
CALL insertar_alumno_con_vinculos('A3456789', 'Roberto', 'Martínez', 'Soto', 'roberto.martinez@uvmnet.edu', 1, 3, '8', '2000-02-20');

CALL ver_docentes();
CALL ver_semestres();
CALL ver_alumnos();
CALL ver_evaluaciones();
CALL ver_respuestas();
CALL ver_comentarios();