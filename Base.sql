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

-- Procedimiento para reporte administrativo de evaluaciones
CREATE PROCEDURE reporte_admin_evaluacion()
BEGIN
    SELECT 
        d.id_docente,
        d.nombre AS nombre_docente,
        d.apellidop,
        d.apellidom,
        s.numero AS semestre_numero,
        s.materia,
        s.curso,
        s.fecha_i,
        s.fecha_fin,
        c.nombre AS campus_nombre,
        SUM(CAST(r.escala AS UNSIGNED)) AS total_puntos,
        COUNT(r.id_respuesta) AS total_respuestas,
        ROUND(AVG(CAST(r.escala AS UNSIGNED)),2) AS promedio,
        CASE
            WHEN AVG(CAST(r.escala AS UNSIGNED)) >= 4.5 THEN 'Asignación de materias'
            WHEN AVG(CAST(r.escala AS UNSIGNED)) >= 3.0 THEN 'En valoración'
            ELSE 'Sin asignación'
        END AS estatus_docente
    FROM docentes d
    JOIN evaluacion e ON d.id_docente = e.id_docente
    JOIN respuestas r ON e.id_evaluacion = r.id_evaluacion
    JOIN semestre s ON e.id_semestre = s.id_semestre
    JOIN campus c ON d.id_campus = c.id_campus
    GROUP BY d.id_docente, s.id_semestre;
END$$

-- Procedimiento para estadísticas generales
CREATE PROCEDURE estadisticas_evaluacion()
BEGIN
    -- Total de campus que evalúan
    SELECT COUNT(DISTINCT id_campus) as total_campus FROM evaluacion e 
    JOIN alumnos a ON e.id_alumno = a.id_alumno;
    
    -- Total de alumnos que han evaluado
    SELECT COUNT(DISTINCT id_alumno) as total_alumnos FROM evaluacion;
    
    -- Alumnos por campus que han evaluado
    SELECT c.nombre as campus, COUNT(DISTINCT e.id_alumno) as alumnos
    FROM evaluacion e
    JOIN alumnos a ON e.id_alumno = a.id_alumno
    JOIN campus c ON a.id_campus = c.id_campus
    GROUP BY a.id_campus;
    
    -- Alumnos por carrera que han evaluado
    SELECT ca.nombre as carrera, COUNT(DISTINCT e.id_alumno) as alumnos
    FROM evaluacion e
    JOIN alumnos a ON e.id_alumno = a.id_alumno
    JOIN carreras ca ON a.id_carrera = ca.id_carrera
    GROUP BY a.id_carrera;
    
    -- Alumnos que no han evaluado (antiguo: sin evaluacion alguna)
    SELECT a.*, c.nombre as campus, ca.nombre as carrera
    FROM alumnos a
    LEFT JOIN evaluacion e ON a.id_alumno = e.id_alumno
    JOIN campus c ON a.id_campus = c.id_campus
    JOIN carreras ca ON a.id_carrera = ca.id_carrera
    WHERE e.id_evaluacion IS NULL;

    -- Nuevo: Estado por alumno: total requerido / completadas / pendientes
    SELECT 
        a.id_alumno,
        a.matricula,
        a.nombre,
        a.apellidop,
        c.nombre as campus,
        ca.nombre as carrera,
        COALESCE((
            SELECT COUNT(*) FROM semestre s 
            WHERE s.id_campus = a.id_campus AND s.numero = a.numero_semestre
        ),0) AS total_requerido,
        COALESCE((
            SELECT COUNT(DISTINCT e.id_semestre) 
            FROM evaluacion e 
            JOIN semestre s2 ON e.id_semestre = s2.id_semestre
            WHERE e.id_alumno = a.id_alumno 
              AND s2.id_campus = a.id_campus 
              AND s2.numero = a.numero_semestre
        ),0) AS completadas,
        (COALESCE((
            SELECT COUNT(*) FROM semestre s 
            WHERE s.id_campus = a.id_campus AND s.numero = a.numero_semestre
        ),0) - COALESCE((
            SELECT COUNT(DISTINCT e.id_semestre) 
            FROM evaluacion e 
            JOIN semestre s2 ON e.id_semestre = s2.id_semestre
            WHERE e.id_alumno = a.id_alumno 
              AND s2.id_campus = a.id_campus 
              AND s2.numero = a.numero_semestre
        ),0)) AS pendientes
    FROM alumnos a
    LEFT JOIN campus c ON a.id_campus = c.id_campus
    LEFT JOIN carreras ca ON a.id_carrera = ca.id_carrera;
END$$

-- Insertar campus
INSERT INTO campus (nombre, direccion, telefono) VALUES
('Coyoacán - Tlalpan', 'Av. Insurgentes Sur 1760, Coyoacán, CDMX', '55-5689-1234'),
('Reforma - San Rafael', 'Paseo de la Reforma 250, Col. San Rafael, CDMX', '55-3344-5566'),
('Hispano', 'Calz. de Tlalpan 780, Benito Juárez, CDMX', '55-7788-9900'),
('Lomas Verdes', 'Blvd. Lomas Verdes 102, Naucalpan, Estado de México', '55-5555-1212'),
('Texcoco', 'Av. Juárez 45, Texcoco, Estado de México', '595-954-3030'),
('Aguascalientes', 'Av. Universidad 1, Aguascalientes, Ags.', '449-912-3456'),
('Guadalajara Sur', 'Av. Vallarta 3000, Guadalajara, Jalisco', '33-3666-7788'),
('Zapopan', 'Av. Patria 1500, Zapopan, Jalisco', '33-3777-8899'),
('Cuernavaca', 'Av. Morelos 210, Cuernavaca, Morelos', '777-123-4567'),
('Puebla', 'Boulevard 5 de Mayo 800, Puebla, Pue.', '222-444-8800'),
('Mexicali', 'Blvd. Lázaro Cárdenas 500, Mexicali, B.C.', '686-555-0101'),
('Chihuahua', 'Av. Tecnológico 200, Chihuahua, Chih.', '614-555-0202'),
('Saltillo', 'Carretera Saltillo-Monterrey Km. 5, Coah.', '844-555-0303'),
('Monterrey Cumbres', 'Calz. del Valle 120, Monterrey, N.L.', '81-5555-0404'),
('San Luis Potosí', 'Av. Salvador Nava 400, SLP', '444-555-0505'),
('Toluca', 'Blvd. Aeropuerto 50, Toluca, Edo. de México', '722-123-6789'),
('Querétaro', 'Av. Universidad 455, Querétaro, Qro.', '442-555-6060'),
('Hermosillo', 'Av. Kino 1500, Hermosillo, Son.', '662-555-7070'),
('Ciudad Victoria', 'Av. Hidalgo 210, Ciudad Victoria, Tamps.', '834-555-8080');

-- Insertar carreras
INSERT INTO carreras (clave, nombre, duracion_semestres) VALUES
('ING-SIST', 'Ingeniería en Sistemas', 9),
('ING-IND', 'Ingeniería Industrial', 9),
('LIC-ADM', 'Licenciatura en Administración', 8),
('LIC-PSI', 'Licenciatura en Psicología', 8),
('ING-ELEC', 'Ingeniería Eléctrica', 9),
('ING-MEC', 'Ingeniería Mecánica', 9),
('LIC-PSI2', 'Licenciatura en Psicopedagogía', 8),
('LIC-MER', 'Licenciatura en Mercadotecnia', 8);

-- Vincular carreras a campus 
INSERT INTO campus_carrera (campus_id, carrera_id, fecha_inicio) VALUES
(1, 1, '2018-06-01'), -- Coyoacán - Ingeniería en Sistemas
(1, 3, '2019-06-01'), -- Coyoacán - Lic. Administración
(7, 6, '2021-09-01'), -- Guadalajara Sur - Ingeniería Mecánica
(1, 2, '2018-01-01'), -- Coyoacán - Ingeniería Industrial
(1, 4, '2019-01-01'), -- Coyoacán - Lic. Psicología 
(2, 1, '2020-06-01'), -- Reforma - Ingeniería en Sistemas
(2, 2, '2020-06-01'), -- Reforma - Ingeniería Industrial
(2, 5, '2021-01-15'), -- Reforma - Ingeniería Eléctrica
(3, 1, '2022-02-01'), -- Hispano - Ingeniería en Sistemas
(3, 6, '2022-02-01'), -- Hispano - Ingeniería Mecánica
(4, 5, '2021-08-01'), -- Lomas Verdes - Ingeniería Eléctrica
(4, 3, '2020-09-01'), -- Lomas Verdes - Lic. Administración
(5, 1, '2020-03-01'), -- Texcoco - Ingeniería en Sistemas
(6, 3, '2019-02-01'), -- Aguascalientes - Lic. Administración
(7, 1, '2021-09-01'), -- Guadalajara Sur - Ingeniería en Sistemas
(7, 5, '2021-09-01'), -- Guadalajara Sur - Ingeniería Eléctrica
(8, 1, '2021-09-01'), -- Zapopan - Ingeniería en Sistemas
(9, 4, '2018-05-01'), -- Cuernavaca - Lic. Psicología
(10, 4, '2019-08-01'), -- Puebla - Lic. Psicología
(11, 6, '2020-01-01'), -- Mexicali - Ingeniería Mecánica
(12, 6, '2020-01-01'), -- Chihuahua - Ingeniería Mecánica
(13, 2, '2019-11-01'), -- Saltillo - Ingeniería Industrial
(14, 1, '2018-07-01'), -- Monterrey Cumbres - Ingeniería en Sistemas
(15, 3, '2019-07-01'), -- San Luis Potosí - Lic. Administración
(16, 2, '2020-02-01'), -- Toluca - Ingeniería Industrial
(17, 3, '2021-03-01'), -- Querétaro - Lic. Administración
(18, 5, '2022-04-01'), -- Hermosillo - Ingeniería Eléctrica
(19, 4, '2021-05-01'); -- Ciudad Victoria - Lic. Psicología

-- Insertar docentes 
INSERT INTO docentes (matricula, nombre, apellidop, apellidom, correo, departamento, fecha_nacimiento, id_campus) VALUES
-- Reforma (prefijo 01)
('01D00001', 'Verónica', 'Sánchez', 'Ramos', 'veronica.sanchez@uvm.mx', 'Sistemas', '1982-05-10', 2),
('01D00002', 'Eduardo', 'López', 'Marín', 'eduardo.lopez@uvm.mx', 'Industrial', '1976-09-02', 2),
('01D00003', 'Roberto', 'Castillo', 'Martínez', 'roberto.castillo@uvm.mx', 'Sistemas', '1985-03-17', 2),
('01D00004', 'Laura', 'González', 'Pérez', 'laura.gonzalez@uvm.mx', 'Sistemas', '1990-08-22', 2),
-- Coyoacán (prefijo 02)
('02D00001', 'Patricia', 'Ortiz', 'Fuentes', 'patricia.ortiz@uvm.mx', 'Administración', '1988-12-11', 1),
('02D00002', 'Marco', 'Arias', 'Díaz', 'marco.arias@uvm.mx', 'Matemáticas', '1980-06-20', 1),
-- Hispano (prefijo 03)
('03D00001', 'Sofía', 'Vega', 'Castillo', 'sofia.vega@uvm.mx', 'Computación', '1987-01-05', 3),
-- Lomas Verdes (prefijo 04)
('04D00001', 'Diego', 'Ruiz', 'Mendoza', 'diego.ruiz@uvm.mx', 'Eléctrica', '1979-03-14', 4),
-- Texcoco (prefijo 05)
('05D00001', 'Elena', 'Silva', 'Navarro', 'elena.silva@uvm.mx', 'Sistemas', '1985-10-30', 5),
-- Guadalajara Sur (prefijo 07)
('07D00001', 'Fernando', 'González', 'Ríos', 'fernando.gonzalez@uvm.mx', 'Mecánica', '1977-04-22', 7),
-- Zapopan (prefijo 08)
('08D00001', 'Liliana', 'Pérez', 'Cruz', 'liliana.perez@uvm.mx', 'Sistemas', '1984-02-17', 8),
-- Puebla (prefijo 10)
('10D00001', 'Raúl', 'Torres', 'Sánchez', 'raul.torres@uvm.mx', 'Psicología', '1975-08-09', 10),
-- Toluca (prefijo 16)
('16D00001', 'Mónica', 'Ibarra', 'Luna', 'monica.ibarra@uvm.mx', 'Industrial', '1983-11-01', 16),
-- Querétaro (prefijo 17)
('17D00001', 'Javier', 'Castro', 'Beltrán', 'javier.castro@uvm.mx', 'Administración', '1989-07-07', 17),
-- Monterrey Cumbres (prefijo 14)
('14D00001', 'Ana Laura', 'Hidalgo', 'Paz', 'analaura.hidalgo@uvm.mx', 'Sistemas', '1981-09-28', 14);

-- Insertar semestres 
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='01D00001'), '3', 'Programación Web', 'PW-301', '2025-01-15', '2025-05-30', 2, 1);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='01D00002'), '5', 'Producción Industrial', 'PI-501', '2025-01-15', '2025-05-30', 2, 2);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='02D00001'), '4', 'Contabilidad', 'CT-401', '2025-01-15', '2025-05-30', 1, 3);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='02D00002'), '2', 'Álgebra Lineal', 'AL-201', '2025-01-15', '2025-05-30', 1, 1);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='03D00001'), '6', 'Sistemas Operativos', 'SO-601', '2025-01-15', '2025-05-30', 3, 1);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='04D00001'), '7', 'Máquinas Eléctricas', 'ME-701', '2025-01-15', '2025-05-30', 4, 5);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='05D00001'), '5', 'Estructuras de Datos', 'ED-501', '2025-01-15', '2025-05-30', 5, 1);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='07D00001'), '4', 'Termodinámica', 'TD-401', '2025-01-15', '2025-05-30', 7, 6);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='08D00001'), '3', 'Bases de Datos Avanzadas', 'BDA-301', '2025-01-15', '2025-05-30', 8, 1);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='10D00001'), '2', 'Psicología del Aprendizaje', 'PA-201', '2025-01-15', '2025-05-30', 10, 4);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='16D00001'), '6', 'Optimización de Producción', 'OP-601', '2025-01-15', '2025-05-30', 16, 2);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='17D00001'), '1', 'Introducción a Mercadotecnia', 'IM-101', '2025-01-15', '2025-05-30', 17, 3);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='14D00001'), '8', 'Desarrollo Móvil', 'DM-801', '2025-01-15', '2025-05-30', 14, 1);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='01D00003'), '3', 'Programación Avanzada', 'PA-302', '2025-01-15', '2025-05-30', 2, 1);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='01D00004'), '3', 'Bases de Datos', 'BD-303', '2025-01-15', '2025-05-30', 2, 1);

-- Insertar alumnos vinculados a campus y carrera 
CALL insertar_alumno_con_vinculos('01A00001', 'Santiago', 'Vargas', 'Lara', 'santiago.vargas@uvmnet.edu', 2, 1, '3', '2003-02-14');
CALL insertar_alumno_con_vinculos('01A00002', 'Camila', 'Gómez', 'Ruiz', 'camila.gomez@uvmnet.edu', 2, 2, '5', '2002-06-01');
CALL insertar_alumno_con_vinculos('02A00001', 'Diego', 'Molina', 'Paz', 'diego.molina@uvmnet.edu', 1, 3, '4', '2004-01-20');
CALL insertar_alumno_con_vinculos('02A00002', 'Karina', 'Soto', 'Vázquez', 'karina.soto@uvmnet.edu', 1, 1, '2', '2003-09-09');
CALL insertar_alumno_con_vinculos('03A00001', 'Andrés', 'Reyes', 'Ortiz', 'andres.reyes@uvmnet.edu', 3, 1, '6', '2001-12-12');
CALL insertar_alumno_con_vinculos('04A00001', 'María José', 'Ponce', 'Guerra', 'mariajose.ponce@uvmnet.edu', 4, 5, '7', '2000-07-07');
CALL insertar_alumno_con_vinculos('07A00001', 'Jorge', 'Medina', 'Silva', 'jorge.medina@uvmnet.edu', 7, 6, '4', '2002-11-11');
CALL insertar_alumno_con_vinculos('08A00001', 'Valeria', 'Ramírez', 'Lopez', 'valeria.ramirez@uvmnet.edu', 8, 1, '3', '2003-03-03');
CALL insertar_alumno_con_vinculos('10A00001', 'Pablo', 'Santos', 'Hernández', 'pablo.santos@uvmnet.edu', 10, 4, '2', '2004-10-10');
CALL insertar_alumno_con_vinculos('16A00001', 'Andrea', 'Cervantes', 'Núñez', 'andrea.cervantes@uvmnet.edu', 16, 2, '5', '2001-05-05');
CALL insertar_alumno_con_vinculos('01A00003', 'Mariana', 'López', 'Ramos', 'mariana.lopez@uvmnet.edu', 2, 1, '3', '2003-07-18');
CALL insertar_alumno_con_vinculos('01A00004', 'Diego', 'Fernández', 'Ruiz', 'diego.fernandez@uvmnet.edu', 2, 1, '3', '2003-11-02');
CALL insertar_alumno_con_vinculos('01A00005', 'Sofía', 'Vega', 'Martínez', 'sofia.vega@uvmnet.edu', 2, 1, '3', '2003-05-12');
CALL insertar_alumno_con_vinculos('17A00001', 'Luis', 'Beltrán', 'Ramos', 'luis.beltran@uvmnet.edu', 17, 3, '1', '2004-04-04');
CALL insertar_alumno_con_vinculos('14A00001', 'Sergio', 'Duarte', 'Mora', 'sergio.duarte@uvmnet.edu', 14, 1, '8', '1999-12-01');

-- Consultas directas
CALL ver_docentes();
CALL ver_semestres();
CALL ver_alumnos();
CALL ver_evaluaciones();
CALL ver_respuestas();
CALL ver_comentarios();