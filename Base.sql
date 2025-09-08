CREATE DATABASE IF NOT EXISTS evaluacion_d;
USE evaluacion_d;

-- Tabla de docentes
CREATE TABLE docentes (
    id_docente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(256) NOT NULL,
    apellidop VARCHAR(256) NOT NULL,
    apellidom VARCHAR(256) NOT NULL,
    matricula VARCHAR(8) NOT NULL,
    correo VARCHAR(256) UNIQUE,
    departamento VARCHAR(256) NOT NULL
);

-- Tabla de semestres
CREATE TABLE semestre (
    id_semestre INT AUTO_INCREMENT PRIMARY KEY,
    numero ENUM("1","2","3","4","5","6","7","8","9"),
    materia VARCHAR(256),
    curso VARCHAR(256),
    fecha_i DATE,
    fecha_fin DATE
);

-- Evaluación general (una por encuestado/docente/semestre)
CREATE TABLE evaluacion (
    id_evaluacion INT AUTO_INCREMENT PRIMARY KEY,
    id_docente INT NOT NULL,
    id_semestre INT NOT NULL,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_docente) REFERENCES docentes(id_docente),
    FOREIGN KEY (id_semestre) REFERENCES semestre(id_semestre)
);

-- Respuestas a preguntas (todas ligadas a un id_evaluacion)
CREATE TABLE respuestas (
    id_respuesta INT AUTO_INCREMENT PRIMARY KEY,
    id_evaluacion INT NOT NULL,
    pregunta TEXT NOT NULL,
    respuesta VARCHAR(256),
    escala ENUM("1","2","3","4","5"),
    FOREIGN KEY (id_evaluacion) REFERENCES evaluacion(id_evaluacion)
);

-- Resumen global de la evaluación
CREATE TABLE criterios (
    id_criterios INT AUTO_INCREMENT PRIMARY KEY,
    resumen ENUM("Deficiente", "Regular", "Bueno", "Muy bueno", "Excelente"),
    id_evaluacion INT,
    FOREIGN KEY (id_evaluacion) REFERENCES evaluacion(id_evaluacion)
);

-- Comentarios adicionales
CREATE TABLE comentarios (
    id_comentario INT AUTO_INCREMENT PRIMARY KEY,
    id_evaluacion INT NOT NULL,
    comentario TEXT NOT NULL,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_evaluacion) REFERENCES evaluacion(id_evaluacion)
);

-- Datos de prueba
INSERT INTO docentes (nombre, apellidop, apellidom, matricula, correo, departamento)
VALUES 
('María', 'González', 'López', 'D1234567', 'maria.gonzalez@uvm.mx', 'Ingeniería'),
('Carlos', 'Ramírez', 'Torres', 'D2345678', 'carlos.ramirez@uvm.mx', 'Ciencias Básicas'),
('Ana', 'Martínez', 'Soto', 'D3456789', 'ana.martinez@uvm.mx', 'Sistemas Computacionales'),
('Luis', 'Hernández', 'Pérez', 'D4567890', 'luis.hernandez@uvm.mx', 'Matemáticas');

INSERT INTO semestre (numero, materia, curso, fecha_i, fecha_fin)
VALUES 
("5", "Bases de Datos", "BD-501", "2025-08-12", "2025-12-15"),
("6", "Redes de Computadoras", "RC-601", "2025-08-12", "2025-12-15"),
("7", "Seguridad Informática", "SI-701", "2025-08-12", "2025-12-15"),
("8", "Arquitectura de Software", "AS-801", "2025-08-12", "2025-12-15");

/***Consultas***/
-- Ver todos los docentes
SELECT * FROM docentes;

-- Ver todos los periodos
SELECT * FROM semestre;

-- Ver todas las evaluaciones
SELECT * FROM evaluacion;

-- Ver todos los criterios
SELECT * FROM criterios;

-- Ver todos los comentarios
SELECT * FROM comentarios;

-- Ver todos las respuestas
SELECT * FROM respuestas;

SELECT d.nombre, d.apellidop, d.apellidom,
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
GROUP BY d.id_docente;
