CREATE DATABASE IF NOT EXISTS evaluacion_d;
USE evaluacion_d;

CREATE TABLE docentes (
    id_docente INT AUTO_INCREMENT PRIMARY KEY,
    matricula VARCHAR(10) NOT NULL UNIQUE, 
    nombre VARCHAR(256) NOT NULL,
    apellidop VARCHAR(256) NOT NULL,
    apellidom VARCHAR(256) NOT NULL,
    correo VARCHAR(256) UNIQUE,
    departamento VARCHAR(256) NOT NULL
);

CREATE TABLE semestre (
    id_semestre INT AUTO_INCREMENT PRIMARY KEY,
    id_docente INT NOT NULL,
    numero ENUM("1","2","3","4","5","6","7","8","9"),
    materia VARCHAR(256),
    curso VARCHAR(256),
    fecha_i DATE,
    fecha_fin DATE,
    FOREIGN KEY (id_docente) REFERENCES docentes(id_docente)
);

CREATE TABLE alumnos (
    id_alumno INT AUTO_INCREMENT PRIMARY KEY,
    matricula VARCHAR(10) NOT NULL UNIQUE,
    nombre VARCHAR(256) NOT NULL,
    apellidop VARCHAR(256) NOT NULL,
    apellidom VARCHAR(256) NOT NULL,
    correo VARCHAR(256) UNIQUE NOT NULL
);

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

CREATE TABLE respuestas (
    id_respuesta INT AUTO_INCREMENT PRIMARY KEY,
    id_evaluacion INT NOT NULL,
    pregunta TEXT NOT NULL,
    escala ENUM("1","2","3","4","5"),
    FOREIGN KEY (id_evaluacion) REFERENCES evaluacion(id_evaluacion)
);

CREATE TABLE comentarios (
    id_comentario INT AUTO_INCREMENT PRIMARY KEY,
    id_evaluacion INT NOT NULL,
    comentario TEXT NOT NULL,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_evaluacion) REFERENCES evaluacion(id_evaluacion)
);

INSERT INTO docentes (matricula, nombre, apellidop, apellidom, correo, departamento)
VALUES 
('D1234567', 'María', 'González', 'López', 'maria.gonzalez@uvm.mx', 'Ingeniería'),
('D2345678', 'Carlos', 'Ramírez', 'Torres', 'carlos.ramirez@uvm.mx', 'Ciencias Básicas'),
('D3456789', 'Ana', 'Martínez', 'Soto', 'ana.martinez@uvm.mx', 'Sistemas Computacionales'),
('D4567890', 'Luis', 'Hernández', 'Pérez', 'luis.hernandez@uvm.mx', 'Matemáticas');

INSERT INTO semestre (id_docente, numero, materia, curso, fecha_i, fecha_fin)
VALUES 
(1, "5", "Bases de Datos", "BD-501", "2025-08-12", "2025-12-15"),
(2, "6", "Redes de Computadoras", "RC-601", "2025-08-12", "2025-12-15"),
(3, "7", "Seguridad Informática", "SI-701", "2025-08-12", "2025-12-15"),
(4, "8", "Arquitectura de Software", "AS-801", "2025-08-12", "2025-12-15"),
(4, "1", "Física", "F-101", "2025-08-12", "2025-12-15"),
(4, "3", "Cálculo Diferencial", "CD-301", "2025-08-12", "2025-12-15");

INSERT INTO alumnos (matricula, nombre, apellidop, apellidom, correo)
VALUES
('A1234567', 'Juan', 'Pérez', 'López', 'juan.perez@uvmnet.edu'),
('A2345678', 'Mariana', 'Hernández', 'Gómez', 'mariana.hernandez@uvmnet.edu'),
('A3456789', 'Roberto', 'Martínez', 'Soto', 'roberto.martinez@uvmnet.edu');

/***Consultas***/
-- Ver todos los docentes
SELECT * FROM docentes;

-- Ver todos los periodos
SELECT * FROM semestre;

-- Ver todos los alumnos
SELECT * FROM alumnos;

-- Ver todas las evaluaciones
SELECT * FROM evaluacion;

-- Ver todos los comentarios
SELECT * FROM comentarios;

-- Ver todos las respuestas
SELECT * FROM respuestas;

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