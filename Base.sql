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
    password VARCHAR(255) NULL,
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

-- Tabla de materias impartidas
CREATE TABLE materias_impartidas (
    id_materia_impartida INT AUTO_INCREMENT PRIMARY KEY,
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
    password VARCHAR(255) NULL,
    tipo_alumno ENUM('regular', 'intercambio') NOT NULL DEFAULT 'regular',
    FOREIGN KEY (id_campus) REFERENCES campus(id_campus),
    FOREIGN KEY (id_carrera) REFERENCES carreras(id_carrera)
);

-- Tabla de evaluaciones
CREATE TABLE evaluacion (
    id_evaluacion INT AUTO_INCREMENT PRIMARY KEY,
    id_docente INT NOT NULL,
    id_materia_impartida INT NOT NULL,   
    id_alumno INT NOT NULL,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_docente) REFERENCES docentes(id_docente),
    FOREIGN KEY (id_materia_impartida) REFERENCES materias_impartidas(id_materia_impartida),
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

-- Tabla de evaluación de servicios
CREATE TABLE evaluacion_servicios (
    id_evaluacion_servicios INT AUTO_INCREMENT PRIMARY KEY,
    id_alumno INT NOT NULL,
    id_campus INT NOT NULL,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_alumno) REFERENCES alumnos(id_alumno),
    FOREIGN KEY (id_campus) REFERENCES campus(id_campus)
);

-- Tabla de respuestas de los servicios
CREATE TABLE respuestas_servicios (
    id_respuesta INT AUTO_INCREMENT PRIMARY KEY,
    id_evaluacion_servicios INT NOT NULL,
    pregunta TEXT NOT NULL,
    escala ENUM('1','2','3','4','5'),
    FOREIGN KEY (id_evaluacion_servicios) REFERENCES evaluacion_servicios(id_evaluacion_servicios)
);

-- Tabla para almacenar el historial de promedios
CREATE TABLE historial_evaluacion (
    id_historial INT AUTO_INCREMENT PRIMARY KEY,
    id_docente INT,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    promedio DECIMAL(4,2),
    total_evaluaciones INT,
    FOREIGN KEY (id_docente) REFERENCES docentes(id_docente)
);

-- Tabla para almacenar el historial de comentarios
CREATE TABLE historial_comentarios (
    id_historial_comentario INT AUTO_INCREMENT PRIMARY KEY,  
    id_docente INT,
    id_alumno INT,
    comentario TEXT NOT NULL,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    materia VARCHAR(256),
    FOREIGN KEY (id_docente) REFERENCES docentes(id_docente),
    FOREIGN KEY (id_alumno) REFERENCES alumnos(id_alumno)
);

-- Tabla de administradores
CREATE TABLE admin_users (
    id_admin INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NULL
);

-- Tablas de resumen (Sirven para la actualización constante)
CREATE TABLE IF NOT EXISTS resumen_docentes_vm (
    id_docente INT PRIMARY KEY,
    total_respuestas INT NOT NULL DEFAULT 0,
    promedio DECIMAL(4,2) NOT NULL DEFAULT 0.00,
    ultima_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_resumen_docentes_docentes_vm FOREIGN KEY (id_docente) REFERENCES docentes(id_docente)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS resumen_servicios_vm (
    id_campus INT PRIMARY KEY,
    total_respuestas INT NOT NULL DEFAULT 0,
    promedio DECIMAL(4,2) NOT NULL DEFAULT 0.00,
    ultima_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_resumen_servicios_campus_vm FOREIGN KEY (id_campus) REFERENCES campus(id_campus)
) ENGINE=InnoDB;

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
    IN p_id_campus INT,
    IN p_password VARCHAR(255)
)
BEGIN
    INSERT INTO docentes (matricula, nombre, apellidop, apellidom, correo, departamento, fecha_nacimiento, id_campus, password)
    VALUES (p_matricula, p_nombre, p_apellidop, p_apellidom, p_correo, p_departamento, p_fecha_nacimiento, p_id_campus, p_password);
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
    INSERT INTO materias_impartidas (id_docente, numero, materia, curso, fecha_i, fecha_fin, id_campus, id_carrera)
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
    IN p_fecha_nacimiento DATE,
    IN p_password VARCHAR(255),
    IN p_tipo_alumno ENUM('regular', 'intercambio')
)
BEGIN
	IF p_tipo_alumno IS NULL THEN
		SET p_tipo_alumno = 'regular';
    END IF;

    IF p_id_campus IS NOT NULL AND p_id_carrera IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM campus_carrera cc WHERE cc.campus_id = p_id_campus AND cc.carrera_id = p_id_carrera) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La carrera no está disponible en el campus seleccionado (proc insertar_alumno_con_vinculos).';
        END IF;
    END IF;
    INSERT INTO alumnos (matricula, nombre, apellidop, apellidom, correo, id_campus, id_carrera, numero_semestre, fecha_nacimiento, password, tipo_alumno)
    VALUES (p_matricula, p_nombre, p_apellidop, p_apellidom, p_correo, p_id_campus, p_id_carrera, p_numero_semestre, p_fecha_nacimiento, p_password, p_tipo_alumno);
END$$

-- Procedimientos de consulta 
CREATE PROCEDURE ver_docentes()
BEGIN
    SELECT * FROM docentes;
END$$

CREATE PROCEDURE ver_semestres()
BEGIN
    SELECT 
        id_materia_impartida,
        id_docente,
        numero AS semestre,   
        materia,
        curso,
        fecha_i,
        fecha_fin,
        id_campus,
        id_carrera
    FROM materias_impartidas;
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

CREATE PROCEDURE ver_evaluacion_servicios()
BEGIN
    SELECT * FROM evaluacion_servicios;
END$$

CREATE PROCEDURE ver_respuestas_servicios()
BEGIN
    SELECT * FROM respuestas_servicios;
END$$

-- Función que devuelve el reporte de evaluaciones para un docente en formato JSON
CREATE FUNCTION fn_reporte_evaluacion(p_id_docente INT) 
RETURNS JSON
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE res JSON;

    SELECT JSON_ARRAYAGG(obj) INTO res
    FROM (
        SELECT JSON_OBJECT(
            'id_docente', d.id_docente,
            'nombre_docente', d.nombre,
            'apellidop', d.apellidop,
            'apellidom', d.apellidom,
            'id_materia_impartida', s.id_materia_impartida,
            'semestre_numero', s.numero,
            'materia', s.materia,
            'curso', s.curso,
            'fecha_i', DATE_FORMAT(s.fecha_i, '%Y-%m-%d'),
            'fecha_fin', DATE_FORMAT(s.fecha_fin, '%Y-%m-%d'),
            'total_puntos', COALESCE(SUM(CAST(r.escala AS UNSIGNED)), 0),
            'total_respuestas', COUNT(r.id_respuesta),
            'promedio', ROUND(AVG(CAST(r.escala AS UNSIGNED)),2),
            'evaluacion_final',
                CASE
                    WHEN AVG(CAST(r.escala AS UNSIGNED)) >= 4.5 THEN 'Excelente profesor'
                    WHEN AVG(CAST(r.escala AS UNSIGNED)) >= 4.0 THEN 'Muy buen profesor'
                    WHEN AVG(CAST(r.escala AS UNSIGNED)) >= 3.0 THEN 'Buen profesor'
                    WHEN AVG(CAST(r.escala AS UNSIGNED)) >= 2.0 THEN 'Profesor regular'
                    ELSE 'Mal profesor'
                END
        ) AS obj
        FROM docentes d
        JOIN evaluacion e ON d.id_docente = e.id_docente
        JOIN respuestas r ON e.id_evaluacion = r.id_evaluacion
        JOIN materias_impartidas s ON e.id_materia_impartida = s.id_materia_impartida
        WHERE d.id_docente = p_id_docente
        GROUP BY d.id_docente, s.id_materia_impartida
        ORDER BY s.numero, s.fecha_i
    ) AS sub;

    RETURN COALESCE(res, JSON_ARRAY());
END$$

-- Procedimiento para registrar evaluaciones
CREATE PROCEDURE registrar_evaluacion(
    IN p_id_docente INT,
    IN p_id_materia_impartida INT,
    IN p_id_alumno INT
)
BEGIN
    INSERT INTO evaluacion (id_docente, id_materia_impartida, id_alumno)
    VALUES (p_id_docente, p_id_materia_impartida, p_id_alumno);
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
    JOIN materias_impartidas s ON e.id_materia_impartida = s.id_materia_impartida
    JOIN campus c ON d.id_campus = c.id_campus
    GROUP BY d.id_docente, s.id_materia_impartida;
END$$

-- Procedimiento para reporte administrativo de evaluación de servicios
CREATE PROCEDURE reporte_admin_servicios()
BEGIN
    SELECT 
        c.nombre AS campus_nombre,
        COUNT(DISTINCT es.id_alumno) AS total_evaluaciones,
        ROUND(AVG(CAST(rs.escala AS UNSIGNED)), 2) AS promedio,
        CASE
            WHEN AVG(CAST(rs.escala AS UNSIGNED)) >= 4.5 THEN 'Excelente'
            WHEN AVG(CAST(rs.escala AS UNSIGNED)) >= 3.5 THEN 'Satisfactorio'
            ELSE 'Requiere Atención'
        END AS estatus_servicios
    FROM evaluacion_servicios es
    JOIN campus c ON es.id_campus = c.id_campus
    JOIN respuestas_servicios rs ON es.id_evaluacion_servicios = rs.id_evaluacion_servicios
    GROUP BY c.id_campus;
END$$

-- Procedimiento para estadísticas generales
CREATE PROCEDURE estadisticas_evaluacion()
BEGIN
    -- Total de campus que evalúan (solo alumnos que completaron todo, incluyendo servicios)
    SELECT COUNT(DISTINCT a.id_campus) as total_campus 
    FROM alumnos a
    WHERE NOT EXISTS (
        SELECT 1 FROM materias_impartidas m 
        WHERE m.id_campus = a.id_campus 
        AND m.numero = a.numero_semestre
        AND NOT EXISTS (
            SELECT 1 FROM evaluacion e 
            WHERE e.id_materia_impartida = m.id_materia_impartida 
            AND e.id_alumno = a.id_alumno
        )
    )
    AND EXISTS (
        SELECT 1 FROM evaluacion_servicios es 
        WHERE es.id_alumno = a.id_alumno
    );
    
    -- Total de alumnos que han completado todas las evaluaciones (docentes + servicios)
    SELECT COUNT(*) as total_alumnos 
    FROM alumnos a
    WHERE NOT EXISTS (
        SELECT 1 FROM materias_impartidas m 
        WHERE m.id_campus = a.id_campus 
        AND m.numero = a.numero_semestre
        AND NOT EXISTS (
            SELECT 1 FROM evaluacion e 
            WHERE e.id_materia_impartida = m.id_materia_impartida 
            AND e.id_alumno = a.id_alumno
        )
    )
    AND EXISTS (
        SELECT 1 FROM evaluacion_servicios es 
        WHERE es.id_alumno = a.id_alumno
    );
    
    -- Alumnos por campus que han evaluado (sólo con evaluaciones docentes)
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
    
    -- Alumnos que no han evaluado (sin evaluacion docente alguna)
    SELECT a.*, c.nombre as campus, ca.nombre as carrera
    FROM alumnos a
    LEFT JOIN evaluacion e ON a.id_alumno = e.id_alumno
    JOIN campus c ON a.id_campus = c.id_campus
    JOIN carreras ca ON a.id_carrera = ca.id_carrera
    WHERE e.id_evaluacion IS NULL;

    -- Estado por alumno: total requerido / completadas / pendientes 
    SELECT 
        a.id_alumno,
        a.matricula,
        a.nombre,
        a.apellidop,
        c.nombre as campus,
        ca.nombre as carrera,
        COALESCE((
            SELECT COUNT(*) FROM materias_impartidas m 
            WHERE m.id_campus = a.id_campus AND m.numero = a.numero_semestre
        ),0) AS total_requerido,
        COALESCE((
            SELECT COUNT(DISTINCT e.id_materia_impartida) 
            FROM evaluacion e 
            JOIN materias_impartidas m2 ON e.id_materia_impartida = m2.id_materia_impartida
            WHERE e.id_alumno = a.id_alumno 
              AND m2.id_campus = a.id_campus 
              AND m2.numero = a.numero_semestre
        ),0) AS completadas,
        (COALESCE((
            SELECT COUNT(*) FROM materias_impartidas m 
            WHERE m.id_campus = a.id_campus AND m.numero = a.numero_semestre
        ),0) - COALESCE((
            SELECT COUNT(DISTINCT e.id_materia_impartida) 
            FROM evaluacion e 
            JOIN materias_impartidas m2 ON e.id_materia_impartida = m2.id_materia_impartida
            WHERE e.id_alumno = a.id_alumno 
              AND m2.id_campus = a.id_campus 
              AND m2.numero = a.numero_semestre
        ),0)) AS pendientes
    FROM alumnos a
    LEFT JOIN campus c ON a.id_campus = c.id_campus
    LEFT JOIN carreras ca ON a.id_carrera = ca.id_carrera;
END$$

-- Procedimiento para reporte de maestros evaluados y no evaluados
DELIMITER $$

CREATE PROCEDURE reporte_maestros_evaluados()
BEGIN
    -- Maestros evaluados
    SELECT 
        d.id_docente,
        CONCAT(d.nombre, ' ', d.apellidop, ' ', d.apellidom) AS nombre_docente,
        COUNT(DISTINCT e.id_evaluacion) AS total_evaluaciones,
        'Evaluado' AS estado
    FROM docentes d
    JOIN evaluacion e ON d.id_docente = e.id_docente
    GROUP BY d.id_docente

    UNION ALL

    -- Maestros NO evaluados
    SELECT 
        d.id_docente,
        CONCAT(d.nombre, ' ', d.apellidop, ' ', d.apellidom) AS nombre_docente,
        0 AS total_evaluaciones,
        'No evaluado' AS estado
    FROM docentes d
    LEFT JOIN evaluacion e ON d.id_docente = e.id_docente
    WHERE e.id_evaluacion IS NULL
    ORDER BY estado DESC, nombre_docente ASC;
END$$

DELIMITER ;

-- Procedimiento granular (actualiza los datos para 1 docente)
DELIMITER $$
CREATE PROCEDURE sp_vm_refrescar_docente_individual(IN p_id_docente INT)
BEGIN
    DECLARE v_total INT DEFAULT 0;
    DECLARE v_prom DECIMAL(4,2) DEFAULT 0.00;

    SELECT COUNT(r.id_respuesta), ROUND(AVG(CAST(r.escala AS UNSIGNED)),2)
    INTO v_total, v_prom
    FROM evaluacion e
    JOIN respuestas r ON e.id_evaluacion = r.id_evaluacion
    WHERE e.id_docente = p_id_docente;

    IF v_total IS NULL OR v_total = 0 THEN
        DELETE FROM resumen_docentes_vm WHERE id_docente = p_id_docente;
    ELSE
        INSERT INTO resumen_docentes_vm (id_docente, total_respuestas, promedio)
        VALUES (p_id_docente, v_total, COALESCE(v_prom,0.00))
        ON DUPLICATE KEY UPDATE
            total_respuestas = VALUES(total_respuestas),
            promedio = VALUES(promedio);
    END IF;
END$$
DELIMITER ;

-- Procedimiento granular para servicios por campus
DELIMITER $$
CREATE PROCEDURE sp_vm_refrescar_campus_servicio_individual(IN p_id_campus INT)
BEGIN
    DECLARE v_total INT DEFAULT 0;
    DECLARE v_prom DECIMAL(4,2) DEFAULT 0.00;

    SELECT COUNT(rs.id_respuesta), ROUND(AVG(CAST(rs.escala AS UNSIGNED)),2)
    INTO v_total, v_prom
    FROM evaluacion_servicios es
    JOIN respuestas_servicios rs ON es.id_evaluacion_servicios = rs.id_evaluacion_servicios
    WHERE es.id_campus = p_id_campus;

    IF v_total IS NULL OR v_total = 0 THEN
        DELETE FROM resumen_servicios_vm WHERE id_campus = p_id_campus;
    ELSE
        INSERT INTO resumen_servicios_vm (id_campus, total_respuestas, promedio)
        VALUES (p_id_campus, v_total, COALESCE(v_prom,0.00))
        ON DUPLICATE KEY UPDATE
            total_respuestas = VALUES(total_respuestas),
            promedio = VALUES(promedio);
    END IF;
END$$
DELIMITER ;

-- Procedimiento de refresco completo (reconcilia todo: docentes + servicios)
DELIMITER $$
CREATE PROCEDURE sp_vm_refrescar_resumen_completo()
BEGIN
    -- Docentes: resumen completo
    DROP TEMPORARY TABLE IF EXISTS tmp_vm_doc;
    CREATE TEMPORARY TABLE tmp_vm_doc AS
    SELECT e.id_docente,
           COUNT(r.id_respuesta) AS total_respuestas,
           ROUND(AVG(CAST(r.escala AS UNSIGNED)),2) AS promedio
    FROM evaluacion e
    JOIN respuestas r ON e.id_evaluacion = r.id_evaluacion
    GROUP BY e.id_docente;

    INSERT INTO resumen_docentes_vm (id_docente, total_respuestas, promedio)
    SELECT id_docente, total_respuestas, COALESCE(promedio,0.00) FROM tmp_vm_doc
    ON DUPLICATE KEY UPDATE
        total_respuestas = VALUES(total_respuestas),
        promedio = VALUES(promedio);

    DELETE rd FROM resumen_docentes_vm rd
    LEFT JOIN tmp_vm_doc t ON rd.id_docente = t.id_docente
    WHERE t.id_docente IS NULL;

    DROP TEMPORARY TABLE IF EXISTS tmp_vm_doc;

    -- Servicios: resumen completo por campus
    DROP TEMPORARY TABLE IF EXISTS tmp_vm_serv;
    CREATE TEMPORARY TABLE tmp_vm_serv AS
    SELECT es.id_campus,
           COUNT(rs.id_respuesta) AS total_respuestas,
           ROUND(AVG(CAST(rs.escala AS UNSIGNED)),2) AS promedio
    FROM evaluacion_servicios es
    JOIN respuestas_servicios rs ON es.id_evaluacion_servicios = rs.id_evaluacion_servicios
    GROUP BY es.id_campus;

    INSERT INTO resumen_servicios_vm (id_campus, total_respuestas, promedio)
    SELECT id_campus, total_respuestas, COALESCE(promedio,0.00) FROM tmp_vm_serv
    ON DUPLICATE KEY UPDATE
        total_respuestas = VALUES(total_respuestas),
        promedio = VALUES(promedio);

    DELETE rs FROM resumen_servicios_vm rs
    LEFT JOIN tmp_vm_serv t ON rs.id_campus = t.id_campus
    WHERE t.id_campus IS NULL;

    DROP TEMPORARY TABLE IF EXISTS tmp_vm_serv;
END$$
DELIMITER ;

-- Evento horario: refresca todo cada 1 HORA
CREATE EVENT IF NOT EXISTS ev_vm_refrescar_resumen_hourly
ON SCHEDULE EVERY 1 HOUR
ON COMPLETION PRESERVE
DO
  CALL sp_vm_refrescar_resumen_completo();

DELIMITER $$
-- Trigger que registra el nuevo promedio cuando se inserta una respuesta
CREATE TRIGGER trg_actualizar_historial_evaluacion 
AFTER INSERT ON respuestas
FOR EACH ROW
BEGIN
    DECLARE v_id_docente INT;
    DECLARE v_promedio DECIMAL(4,2);
    DECLARE v_total_evaluaciones INT;

    -- Obtener el id_docente de la evaluación
    SELECT e.id_docente INTO v_id_docente
    FROM evaluacion e
    WHERE e.id_evaluacion = NEW.id_evaluacion;

    -- Calcular el nuevo promedio del docente
    SELECT 
        ROUND(AVG(CAST(r.escala AS UNSIGNED)),2),
        COUNT(DISTINCT e.id_evaluacion)
    INTO v_promedio, v_total_evaluaciones
    FROM respuestas r
    JOIN evaluacion e ON r.id_evaluacion = e.id_evaluacion
    WHERE e.id_docente = v_id_docente;

    -- Insertar el registro en el historial
    INSERT INTO historial_evaluacion (id_docente, promedio, total_evaluaciones)
    VALUES (v_id_docente, v_promedio, v_total_evaluaciones);

    -- Actualizar resumen del docente (llama al procedimiento granular)
    CALL sp_vm_refrescar_docente_individual(v_id_docente);
END$$

-- Trigger que registra el comentario en el historial cuando se inserta un nuevo comentario
CREATE TRIGGER trg_historial_comentarios
AFTER INSERT ON comentarios
FOR EACH ROW
BEGIN
    DECLARE v_id_docente INT;
    DECLARE v_id_alumno INT;
    DECLARE v_materia VARCHAR(256);
    
    -- Obtener datos de la evaluación relacionada
    SELECT 
        e.id_docente,
        e.id_alumno,
        m.materia
    INTO 
        v_id_docente,
        v_id_alumno,
        v_materia
    FROM evaluacion e
    JOIN materias_impartidas m ON e.id_materia_impartida = m.id_materia_impartida
    WHERE e.id_evaluacion = NEW.id_evaluacion;

    -- Registrar en el historial
    INSERT INTO historial_comentarios (
        id_docente,
        id_alumno, 
        comentario,
        materia
    ) VALUES (
        v_id_docente,
        v_id_alumno,
        NEW.comentario,
        v_materia
    );
END$$

-- Trigger que actualiza resumen de servicios por campus cuando se inserta una respuesta de servicio
CREATE TRIGGER trg_refrescar_resumen_servicios
AFTER INSERT ON respuestas_servicios
FOR EACH ROW
BEGIN
    DECLARE v_id_campus INT;

    -- Obtener el id_campus de la evaluación de servicios
    SELECT es.id_campus INTO v_id_campus
    FROM evaluacion_servicios es
    WHERE es.id_evaluacion_servicios = NEW.id_evaluacion_servicios;

    -- Actualizar resumen por campus (llama al procedimiento granular)
    CALL sp_vm_refrescar_campus_servicio_individual(v_id_campus);
END$$
DELIMITER ;

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
('Ciudad Victoria', 'Av. Hidalgo 210, Ciudad Victoria, Tamps.', '834-555-8080'),
('Toronto - Canadá', 'University Ave 27, Toronto, ON M5J 1A1, Canada', '+1-416-978-0000'),
('Madrid - España', 'Calle Serrano 123, Madrid, 28006, Spain', '+34-91-123-4567'),
('Sao Paulo - Brasil', 'Avenida Paulista 1000, Sao Paulo, SP 01311-100, Brazil', '+55-11-3333-4444'),
('Sydney - Australia', 'University Avenue 10, Camperdown, NSW 2006, Australia', '+61-2-9351-0000'),
('Tokyo - Japón', 'Hongo 7-3-1, Bunkyo City, Tokyo 113-0033, Japan', '+81-3-3812-2111');

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
(19, 4, '2021-05-01'), -- Ciudad Victoria - Lic. Psicología
(20, 1, '2024-01-15'), -- Toronto - Ingeniería en Sistemas
(20, 3, '2024-01-15'), -- Toronto - Lic. Administración
(21, 2, '2024-02-01'), -- Madrid - Ingeniería Industrial
(21, 4, '2024-02-01'), -- Madrid - Lic. Psicología
(22, 1, '2024-03-01'), -- Sao Paulo - Ingeniería en Sistemas
(22, 6, '2024-03-01'), -- Sao Paulo - Ingeniería Mecánica
(23, 5, '2024-04-01'), -- Sydney - Ingeniería Eléctrica
(23, 3, '2024-04-01'), -- Sydney - Lic. Administración
(24, 1, '2024-05-01'), -- Tokyo - Ingeniería en Sistemas
(24, 8, '2024-05-01'); -- Tokyo - Lic. Mercadotecnia

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

-- Más docentes para Reforma (prefijo 01)
CALL insertar_docente_con_campus('01D00005','Roberto','Salinas','Vega','roberto.salinas@uvm.mx','Física','1975-04-12',2, NULL);
CALL insertar_docente_con_campus('01D00006','Laura','Gómez','Rivera','laura.gomez@uvm.mx','Química','1980-09-05',2, NULL);
CALL insertar_docente_con_campus('01D00007','Daniel','Pérez','Ortiz','daniel.perez@uvm.mx','Matemáticas','1978-02-20',2, NULL);
CALL insertar_docente_con_campus('01D00008','Emily','Torres','Castillo','emily.torres@uvm.mx','Idiomas','1984-07-15',2, NULL);
CALL insertar_docente_con_campus('01D00009','Mauricio','Hernández','Luna','mauricio.hernandez@uvm.mx','Computación','1979-11-30',2, NULL);

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
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='16D00001'), '5', 'Optimización de Producción', 'OP-601', '2025-01-15', '2025-05-30', 16, 2);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='17D00001'), '1', 'Introducción a Mercadotecnia', 'IM-101', '2025-01-15', '2025-05-30', 17, 3);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='14D00001'), '8', 'Desarrollo Móvil', 'DM-801', '2025-01-15', '2025-05-30', 14, 1);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='01D00003'), '3', 'Programación Avanzada', 'PA-302', '2025-01-15', '2025-05-30', 2, 1);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='01D00004'), '3', 'Bases de Datos', 'BD-303', '2025-01-15', '2025-05-30', 2, 1);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='01D00005'), '1', 'Física', 'FI-101', '2025-01-15', '2025-05-30', 2, 1);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='01D00006'), '1', 'Química', 'QU-101', '2025-01-15', '2025-05-30', 2, 1);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='01D00007'), '1', 'Álgebra', 'AL-101', '2025-01-15', '2025-05-30', 2, 1);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='01D00008'), '1', 'Inglés I', 'IN-101', '2025-01-15', '2025-05-30', 2, 1);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='01D00009'), '1', 'Arquitectura de Computadoras', 'AC-101', '2025-01-15', '2025-05-30', 2, 1);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula = '01D00008'), '1', 'Empatía para resolver', 'EM-101', '2025-01-15', '2025-05-30', 2, 1);

-- Insertar alumnos vinculados a campus y carrera 
-- Reforma (prefijo 01)
CALL insertar_alumno_con_vinculos('01A00001', 'Santiago', 'Vargas', 'Lara', 'santiago.vargas1@uvmnet.edu', 2, 1, '3', '2003-02-14', NULL, 'regular');
CALL insertar_alumno_con_vinculos('01A00002', 'Camila', 'Gómez', 'Ruiz', 'camila.gomez1@uvmnet.edu', 2, 2, '5', '2002-06-01', NULL, 'regular');
CALL insertar_alumno_con_vinculos('01A00003', 'Mariana', 'López', 'Ramos', 'mariana.lopez1@uvmnet.edu', 2, 1, '3', '2003-07-18', NULL, 'regular');
CALL insertar_alumno_con_vinculos('01A00004', 'Diego', 'Fernández', 'Ruiz', 'diego.fernandez1@uvmnet.edu', 2, 1, '3', '2003-11-02', NULL, 'regular');
CALL insertar_alumno_con_vinculos('01A00005', 'Sofía', 'Vega', 'Martínez', 'sofia.vega1@uvmnet.edu', 2, 1, '3', '2003-05-12', NULL, 'regular');
CALL insertar_alumno_con_vinculos('01A00006', 'Georgina Wendy', 'Mondragón', 'Vázquez', 'georgina.mondragon1@uvmnet.edu', 2, 1, '1', '2006-03-10', NULL, 'regular');
CALL insertar_alumno_con_vinculos('01A00007', 'Brenda Sofía', 'Hernández', 'López', 'brenda.hernandez1@uvmnet.edu', 2, 1, '1', '2006-04-05', NULL, 'regular');
CALL insertar_alumno_con_vinculos('01A00008', 'Juan Carlos', 'Ruiz', 'Martínez', 'juan.carlos.ruiz1@uvmnet.edu', 2, 1, '1', '2006-02-20', NULL, 'regular');
CALL insertar_alumno_con_vinculos('01A00009', 'Valeria', 'Castillo', 'García', 'valeria.castillo1@uvmnet.edu', 2, 2, '5', '2002-08-15', NULL, 'regular');
CALL insertar_alumno_con_vinculos('01A00010', 'Miguel', 'Ramírez', 'Santos', 'miguel.ramirez1@uvmnet.edu', 2, 1, '3', '2003-10-22', NULL, 'regular');
CALL insertar_alumno_con_vinculos('01A00011', 'Paola', 'Martínez', 'Gómez', 'paola.martinez1@uvmnet.edu', 2, 1, '3', '2003-03-30', NULL, 'regular');
CALL insertar_alumno_con_vinculos('01A00012', 'Luis', 'Hernández', 'Vega', 'luis.hernandez1@uvmnet.edu', 2, 1, '3', '2003-09-17', NULL, 'regular');
CALL insertar_alumno_con_vinculos('01A00013', 'Andrea', 'Soto', 'López', 'andrea.soto1@uvmnet.edu', 2, 2, '5', '2002-12-05', NULL, 'regular');
CALL insertar_alumno_con_vinculos('01A00014', 'Carlos', 'García', 'Fernández', 'carlos.garcia1@uvmnet.edu', 2, 1, '3', '2003-06-21', NULL, 'regular');
CALL insertar_alumno_con_vinculos('01A00015', 'Fernanda', 'Ruiz', 'Martínez', 'fernanda.ruiz1@uvmnet.edu', 2, 1, '3', '2003-01-28', NULL, 'regular');
CALL insertar_alumno_con_vinculos('01A00016', 'Jorge', 'Lara', 'Vargas', 'jorge.lara1@uvmnet.edu', 2, 1, '1', '2006-05-13', NULL, 'regular');
CALL insertar_alumno_con_vinculos('01A00017', 'Daniela', 'Vázquez', 'Mondragón', 'daniela.vazquez1@uvmnet.edu', 2, 1, '1', '2006-06-09', NULL, 'regular');
CALL insertar_alumno_con_vinculos('01A00018', 'Alejandro', 'López', 'Hernández', 'alejandro.lopez1@uvmnet.edu', 2, 1, '1', '2006-07-02', NULL, 'regular');
CALL insertar_alumno_con_vinculos('01A00019', 'Regina', 'Martínez', 'Santos', 'regina.martinez1@uvmnet.edu', 2, 2, '5', '2002-04-18', NULL, 'regular');
CALL insertar_alumno_con_vinculos('01A00020', 'Iván', 'Gómez', 'Ramírez', 'ivan.gomez1@uvmnet.edu', 2, 1, '3', '2003-12-25', NULL, 'regular');

-- Coyoacán (prefijo 02)
CALL insertar_alumno_con_vinculos('02A00001', 'Diego', 'Molina', 'Paz', 'diego.molina2@uvmnet.edu', 1, 3, '4', '2004-01-20', NULL, 'regular');
CALL insertar_alumno_con_vinculos('02A00002', 'Karina', 'Soto', 'Vázquez', 'karina.soto2@uvmnet.edu', 1, 1, '2', '2003-09-09', NULL, 'regular');
CALL insertar_alumno_con_vinculos('02A00003', 'Luis', 'Ramírez', 'Gómez', 'luis.ramirez2@uvmnet.edu', 1, 1, '3', '2003-05-15', NULL, 'regular');
CALL insertar_alumno_con_vinculos('02A00004', 'María', 'Fernández', 'López', 'maria.fernandez2@uvmnet.edu', 1, 3, '4', '2004-02-10', NULL, 'regular');
CALL insertar_alumno_con_vinculos('02A00005', 'Jorge', 'Sánchez', 'Martínez', 'jorge.sanchez2@uvmnet.edu', 1, 1, '2', '2003-08-22', NULL, 'regular');
CALL insertar_alumno_con_vinculos('02A00006', 'Ana', 'García', 'Hernández', 'ana.garcia2@uvmnet.edu', 1, 3, '4', '2004-03-18', NULL, 'regular');
CALL insertar_alumno_con_vinculos('02A00007', 'Ricardo', 'Vega', 'Ruiz', 'ricardo.vega2@uvmnet.edu', 1, 1, '3', '2003-11-30', NULL, 'regular');
CALL insertar_alumno_con_vinculos('02A00008', 'Paola', 'Luna', 'Castillo', 'paola.luna2@uvmnet.edu', 1, 3, '4', '2004-06-12', NULL, 'regular');
CALL insertar_alumno_con_vinculos('02A00009', 'Fernando', 'Torres', 'Santos', 'fernando.torres2@uvmnet.edu', 1, 1, '2', '2003-10-05', NULL, 'regular');
CALL insertar_alumno_con_vinculos('02A00010', 'Valeria', 'Morales', 'Jiménez', 'valeria.morales2@uvmnet.edu', 1, 3, '4', '2004-04-25', NULL, 'regular');
CALL insertar_alumno_con_vinculos('02A00011', 'Sofía', 'Pérez', 'Navarro', 'sofia.perez2@uvmnet.edu', 1, 1, '3', '2003-07-19', NULL, 'regular');
CALL insertar_alumno_con_vinculos('02A00012', 'Miguel', 'Cruz', 'Flores', 'miguel.cruz2@uvmnet.edu', 1, 3, '4', '2004-09-14', NULL, 'regular');
CALL insertar_alumno_con_vinculos('02A00013', 'Andrea', 'Gómez', 'Vargas', 'andrea.gomez2@uvmnet.edu', 1, 1, '2', '2003-12-03', NULL, 'regular');
CALL insertar_alumno_con_vinculos('02A00014', 'Carlos', 'Hernández', 'Soto', 'carlos.hernandez2@uvmnet.edu', 1, 3, '4', '2004-05-27', NULL, 'regular');
CALL insertar_alumno_con_vinculos('02A00015', 'Fernanda', 'Ruiz', 'Mendoza', 'fernanda.ruiz2@uvmnet.edu', 1, 1, '3', '2003-06-16', NULL, 'regular');
CALL insertar_alumno_con_vinculos('02A00016', 'Javier', 'López', 'Ramírez', 'javier.lopez2@uvmnet.edu', 1, 3, '4', '2004-08-21', NULL, 'regular');
CALL insertar_alumno_con_vinculos('02A00017', 'Daniela', 'Martínez', 'García', 'daniela.martinez2@uvmnet.edu', 1, 1, '2', '2003-09-28', NULL, 'regular');
CALL insertar_alumno_con_vinculos('02A00018', 'Alejandro', 'Santos', 'Pérez', 'alejandro.santos2@uvmnet.edu', 1, 3, '4', '2004-11-11', NULL, 'regular');
CALL insertar_alumno_con_vinculos('02A00019', 'Regina', 'Castillo', 'Luna', 'regina.castillo2@uvmnet.edu', 1, 1, '3', '2003-03-23', NULL, 'regular');
CALL insertar_alumno_con_vinculos('02A00020', 'Iván', 'Navarro', 'Morales', 'ivan.navarro2@uvmnet.edu', 1, 3, '4', '2004-12-08', NULL, 'regular');

-- Hispano (prefijo 03)
CALL insertar_alumno_con_vinculos('03A00001', 'Andrés', 'Reyes', 'Ortiz', 'andres.reyes3@uvmnet.edu', 3, 1, '6', '2001-12-12', NULL, 'regular');
CALL insertar_alumno_con_vinculos('03A00002', 'María Fernanda', 'García', 'López', 'mariafernanda.garcia3@uvmnet.edu', 3, 6, '6', '2001-11-23', NULL, 'regular');
CALL insertar_alumno_con_vinculos('03A00003', 'José Luis', 'Martínez', 'Sánchez', 'joseluis.martinez3@uvmnet.edu', 3, 1, '6', '2002-01-15', NULL, 'regular');
CALL insertar_alumno_con_vinculos('03A00004', 'Ana', 'Hernández', 'Ramírez', 'ana.hernandez3@uvmnet.edu', 3, 6, '6', '2001-10-05', NULL, 'regular');
CALL insertar_alumno_con_vinculos('03A00005', 'Carlos', 'Pérez', 'Gómez', 'carlos.perez3@uvmnet.edu', 3, 1, '6', '2002-02-28', NULL, 'regular');
CALL insertar_alumno_con_vinculos('03A00006', 'Paola', 'Soto', 'Vega', 'paola.soto3@uvmnet.edu', 3, 6, '6', '2001-09-19', NULL, 'regular');
CALL insertar_alumno_con_vinculos('03A00007', 'Luis', 'Ramírez', 'Flores', 'luis.ramirez3@uvmnet.edu', 3, 1, '6', '2002-03-10', NULL, 'regular');
CALL insertar_alumno_con_vinculos('03A00008', 'Fernanda', 'Castillo', 'Navarro', 'fernanda.castillo3@uvmnet.edu', 3, 6, '6', '2001-08-14', NULL, 'regular');
CALL insertar_alumno_con_vinculos('03A00009', 'Miguel', 'Luna', 'Jiménez', 'miguel.luna3@uvmnet.edu', 3, 1, '6', '2002-04-22', NULL, 'regular');
CALL insertar_alumno_con_vinculos('03A00010', 'Valeria', 'Morales', 'Cruz', 'valeria.morales3@uvmnet.edu', 3, 6, '6', '2001-07-30', NULL, 'regular');
CALL insertar_alumno_con_vinculos('03A00011', 'Javier', 'Gómez', 'Santos', 'javier.gomez3@uvmnet.edu', 3, 1, '6', '2002-05-18', NULL, 'regular');
CALL insertar_alumno_con_vinculos('03A00012', 'Andrea', 'Vega', 'Martínez', 'andrea.vega3@uvmnet.edu', 3, 6, '6', '2001-06-25', NULL, 'regular');
CALL insertar_alumno_con_vinculos('03A00013', 'Daniel', 'Sánchez', 'Ruiz', 'daniel.sanchez3@uvmnet.edu', 3, 1, '6', '2002-06-12', NULL, 'regular');
CALL insertar_alumno_con_vinculos('03A00014', 'Regina', 'Flores', 'Hernández', 'regina.flores3@uvmnet.edu', 3, 6, '6', '2001-05-09', NULL, 'regular');
CALL insertar_alumno_con_vinculos('03A00015', 'Iván', 'Jiménez', 'Pérez', 'ivan.jimenez3@uvmnet.edu', 3, 1, '6', '2002-07-03', NULL, 'regular');
CALL insertar_alumno_con_vinculos('03A00016', 'Sofía', 'Navarro', 'López', 'sofia.navarro3@uvmnet.edu', 3, 6, '6', '2001-04-16', NULL, 'regular');
CALL insertar_alumno_con_vinculos('03A00017', 'Jorge', 'Cruz', 'García', 'jorge.cruz3@uvmnet.edu', 3, 1, '6', '2002-08-27', NULL, 'regular');
CALL insertar_alumno_con_vinculos('03A00018', 'Camila', 'Santos', 'Morales', 'camila.santos3@uvmnet.edu', 3, 6, '6', '2001-03-21', NULL, 'regular');
CALL insertar_alumno_con_vinculos('03A00019', 'Alejandro', 'García', 'Vega', 'alejandro.garcia3@uvmnet.edu', 3, 1, '6', '2002-09-14', NULL, 'regular');
CALL insertar_alumno_con_vinculos('03A00020', 'Lucía', 'Martínez', 'Soto', 'lucia.martinez3@uvmnet.edu', 3, 6, '6', '2001-02-02', NULL, 'regular');

-- Lomas Verdes (prefijo 04)
CALL insertar_alumno_con_vinculos('04A00001', 'María José', 'Ponce', 'Guerra', 'mariajose.ponce4@uvmnet.edu', 4, 5, '7', '2000-07-07', NULL, 'regular');
CALL insertar_alumno_con_vinculos('04A00002', 'Alejandro', 'Mendoza', 'Soto', 'alejandro.mendoza4@uvmnet.edu', 4, 3, '7', '2000-08-15', NULL, 'regular');
CALL insertar_alumno_con_vinculos('04A00003', 'Fernanda', 'García', 'López', 'fernanda.garcia4@uvmnet.edu', 4, 5, '7', '2000-09-10', NULL, 'regular');
CALL insertar_alumno_con_vinculos('04A00004', 'Jorge', 'Ramírez', 'Martínez', 'jorge.ramirez4@uvmnet.edu', 4, 3, '7', '2000-10-22', NULL, 'regular');
CALL insertar_alumno_con_vinculos('04A00005', 'Valeria', 'Sánchez', 'Pérez', 'valeria.sanchez4@uvmnet.edu', 4, 5, '7', '2000-11-30', NULL, 'regular');
CALL insertar_alumno_con_vinculos('04A00006', 'Luis', 'Hernández', 'Ruiz', 'luis.hernandez4@uvmnet.edu', 4, 3, '7', '2000-12-12', NULL, 'regular');
CALL insertar_alumno_con_vinculos('04A00007', 'Andrea', 'Luna', 'Gómez', 'andrea.luna4@uvmnet.edu', 4, 5, '7', '2001-01-25', NULL, 'regular');
CALL insertar_alumno_con_vinculos('04A00008', 'Carlos', 'Vega', 'Navarro', 'carlos.vega4@uvmnet.edu', 4, 3, '7', '2001-02-14', NULL, 'regular');
CALL insertar_alumno_con_vinculos('04A00009', 'Sofía', 'Castillo', 'Morales', 'sofia.castillo4@uvmnet.edu', 4, 5, '7', '2001-03-19', NULL, 'regular');
CALL insertar_alumno_con_vinculos('04A00010', 'Miguel', 'Flores', 'Jiménez', 'miguel.flores4@uvmnet.edu', 4, 3, '7', '2001-04-07', NULL, 'regular');
CALL insertar_alumno_con_vinculos('04A00011', 'Paola', 'Santos', 'Cruz', 'paola.santos4@uvmnet.edu', 4, 5, '7', '2001-05-21', NULL, 'regular');
CALL insertar_alumno_con_vinculos('04A00012', 'Javier', 'Gómez', 'Beltrán', 'javier.gomez4@uvmnet.edu', 4, 3, '7', '2001-06-13', NULL, 'regular');
CALL insertar_alumno_con_vinculos('04A00013', 'Daniela', 'Ruiz', 'Fernández', 'daniela.ruiz4@uvmnet.edu', 4, 5, '7', '2001-07-29', NULL, 'regular');
CALL insertar_alumno_con_vinculos('04A00014', 'Alejandro', 'Martínez', 'Santos', 'alejandro.martinez4@uvmnet.edu', 4, 3, '7', '2001-08-18', NULL, 'regular');
CALL insertar_alumno_con_vinculos('04A00015', 'Regina', 'López', 'Vega', 'regina.lopez4@uvmnet.edu', 4, 5, '7', '2001-09-25', NULL, 'regular');
CALL insertar_alumno_con_vinculos('04A00016', 'Iván', 'Soto', 'Ramírez', 'ivan.soto4@uvmnet.edu', 4, 3, '7', '2001-10-30', NULL, 'regular');
CALL insertar_alumno_con_vinculos('04A00017', 'Camila', 'Morales', 'García', 'camila.morales4@uvmnet.edu', 4, 5, '7', '2001-11-11', NULL, 'regular');
CALL insertar_alumno_con_vinculos('04A00018', 'Diego', 'Navarro', 'Luna', 'diego.navarro4@uvmnet.edu', 4, 3, '7', '2001-12-20', NULL, 'regular');
CALL insertar_alumno_con_vinculos('04A00019', 'Lucía', 'Jiménez', 'Castillo', 'lucia.jimenez4@uvmnet.edu', 4, 5, '7', '2002-01-15', NULL, 'regular');
CALL insertar_alumno_con_vinculos('04A00020', 'Antonio', 'Beltrán', 'Santos', 'antonio.beltran4@uvmnet.edu', 4, 3, '7', '2002-02-28', NULL, 'regular');

-- Guadalajara Sur (prefijo 07)
CALL insertar_alumno_con_vinculos('07A00001', 'Jorge', 'Medina', 'Silva', 'jorge.medina7@uvmnet.edu', 7, 6, '4', '2002-11-11', NULL, 'regular');
CALL insertar_alumno_con_vinculos('07A00002', 'María', 'Gómez', 'Ríos', 'maria.gomez7@uvmnet.edu', 7, 6, '4', '2002-03-22', NULL, 'regular');
CALL insertar_alumno_con_vinculos('07A00003', 'Luis', 'Hernández', 'Pérez', 'luis.hernandez7@uvmnet.edu', 7, 6, '4', '2002-07-15', NULL, 'regular');
CALL insertar_alumno_con_vinculos('07A00004', 'Ana', 'Martínez', 'López', 'ana.martinez7@uvmnet.edu', 7, 6, '4', '2002-09-10', NULL, 'regular');
CALL insertar_alumno_con_vinculos('07A00005', 'Carlos', 'Sánchez', 'Ramírez', 'carlos.sanchez7@uvmnet.edu', 7, 6, '4', '2002-01-30', NULL, 'regular');
CALL insertar_alumno_con_vinculos('07A00006', 'Fernanda', 'Ruiz', 'García', 'fernanda.ruiz7@uvmnet.edu', 7, 6, '4', '2002-05-18', NULL, 'regular');
CALL insertar_alumno_con_vinculos('07A00007', 'Miguel', 'Luna', 'Morales', 'miguel.luna7@uvmnet.edu', 7, 6, '4', '2002-12-03', NULL, 'regular');
CALL insertar_alumno_con_vinculos('07A00008', 'Paola', 'Castillo', 'Navarro', 'paola.castillo7@uvmnet.edu', 7, 6, '4', '2002-08-27', NULL, 'regular');
CALL insertar_alumno_con_vinculos('07A00009', 'Javier', 'Vega', 'Santos', 'javier.vega7@uvmnet.edu', 7, 6, '4', '2002-04-14', NULL, 'regular');
CALL insertar_alumno_con_vinculos('07A00010', 'Andrea', 'Flores', 'Jiménez', 'andrea.flores7@uvmnet.edu', 7, 6, '4', '2002-06-21', NULL, 'regular');
CALL insertar_alumno_con_vinculos('07A00011', 'Sofía', 'Pérez', 'Beltrán', 'sofia.perez7@uvmnet.edu', 7, 6, '4', '2002-10-05', NULL, 'regular');
CALL insertar_alumno_con_vinculos('07A00012', 'Diego', 'Gómez', 'Vargas', 'diego.gomez7@uvmnet.edu', 7, 6, '4', '2002-02-12', NULL, 'regular');
CALL insertar_alumno_con_vinculos('07A00013', 'Valeria', 'Santos', 'Cruz', 'valeria.santos7@uvmnet.edu', 7, 6, '4', '2002-03-29', NULL, 'regular');
CALL insertar_alumno_con_vinculos('07A00014', 'Jorge', 'Ramírez', 'López', 'jorge.ramirez7@uvmnet.edu', 7, 6, '4', '2002-07-08', NULL, 'regular');
CALL insertar_alumno_con_vinculos('07A00015', 'Camila', 'Hernández', 'Gómez', 'camila.hernandez7@uvmnet.edu', 7, 6, '4', '2002-11-19', NULL, 'regular');
CALL insertar_alumno_con_vinculos('07A00016', 'Alejandro', 'López', 'Martínez', 'alejandro.lopez7@uvmnet.edu', 7, 6, '4', '2002-05-25', NULL, 'regular');
CALL insertar_alumno_con_vinculos('07A00017', 'Lucía', 'García', 'Ruiz', 'lucia.garcia7@uvmnet.edu', 7, 6, '4', '2002-09-14', NULL, 'regular');
CALL insertar_alumno_con_vinculos('07A00018', 'Iván', 'Navarro', 'Soto', 'ivan.navarro7@uvmnet.edu', 7, 6, '4', '2002-04-02', NULL, 'regular');
CALL insertar_alumno_con_vinculos('07A00019', 'Regina', 'Morales', 'Fernández', 'regina.morales7@uvmnet.edu', 7, 6, '4', '2002-08-11', NULL, 'regular');
CALL insertar_alumno_con_vinculos('07A00020', 'Antonio', 'Jiménez', 'Castillo', 'antonio.jimenez7@uvmnet.edu', 7, 6, '4', '2002-06-30', NULL, 'regular');

-- Zapopan (prefijo 08)
CALL insertar_alumno_con_vinculos('08A00001', 'Valeria', 'Ramírez', 'Lopez', 'valeria.ramirez8@uvmnet.edu', 8, 1, '3', '2003-03-03', NULL, 'regular');
CALL insertar_alumno_con_vinculos('08A00002', 'Carlos', 'Gómez', 'Santos', 'carlos.gomez8@uvmnet.edu', 8, 1, '3', '2003-04-12', NULL, 'regular');
CALL insertar_alumno_con_vinculos('08A00003', 'Fernanda', 'López', 'Martínez', 'fernanda.lopez8@uvmnet.edu', 8, 1, '3', '2003-05-21', NULL, 'regular');
CALL insertar_alumno_con_vinculos('08A00004', 'Jorge', 'Sánchez', 'Ruiz', 'jorge.sanchez8@uvmnet.edu', 8, 1, '3', '2003-06-30', NULL, 'regular');
CALL insertar_alumno_con_vinculos('08A00005', 'Sofía', 'Pérez', 'García', 'sofia.perez8@uvmnet.edu', 8, 1, '3', '2003-07-09', NULL, 'regular');
CALL insertar_alumno_con_vinculos('08A00006', 'Miguel', 'Hernández', 'Vega', 'miguel.hernandez8@uvmnet.edu', 8, 1, '3', '2003-08-18', NULL, 'regular');
CALL insertar_alumno_con_vinculos('08A00007', 'Andrea', 'Ramírez', 'Flores', 'andrea.ramirez8@uvmnet.edu', 8, 1, '3', '2003-09-27', NULL, 'regular');
CALL insertar_alumno_con_vinculos('08A00008', 'Luis', 'Martínez', 'Soto', 'luis.martinez8@uvmnet.edu', 8, 1, '3', '2003-10-06', NULL, 'regular');
CALL insertar_alumno_con_vinculos('08A00009', 'Camila', 'García', 'Navarro', 'camila.garcia8@uvmnet.edu', 8, 1, '3', '2003-11-15', NULL, 'regular');
CALL insertar_alumno_con_vinculos('08A00010', 'Javier', 'Santos', 'Morales', 'javier.santos8@uvmnet.edu', 8, 1, '3', '2003-12-24', NULL, 'regular');
CALL insertar_alumno_con_vinculos('08A00011', 'Lucía', 'Flores', 'Jiménez', 'lucia.flores8@uvmnet.edu', 8, 1, '3', '2004-01-02', NULL, 'regular');
CALL insertar_alumno_con_vinculos('08A00012', 'Iván', 'Luna', 'Beltrán', 'ivan.luna8@uvmnet.edu', 8, 1, '3', '2004-02-11', NULL, 'regular');
CALL insertar_alumno_con_vinculos('08A00013', 'Regina', 'Castillo', 'Cruz', 'regina.castillo8@uvmnet.edu', 8, 1, '3', '2004-03-20', NULL, 'regular');
CALL insertar_alumno_con_vinculos('08A00014', 'Antonio', 'Morales', 'Gómez', 'antonio.morales8@uvmnet.edu', 8, 1, '3', '2004-04-29', NULL, 'regular');
CALL insertar_alumno_con_vinculos('08A00015', 'María', 'Jiménez', 'Fernández', 'maria.jimenez8@uvmnet.edu', 8, 1, '3', '2004-06-07', NULL, 'regular');
CALL insertar_alumno_con_vinculos('08A00016', 'Alejandro', 'Ruiz', 'Paz', 'alejandro.ruiz8@uvmnet.edu', 8, 1, '3', '2004-07-16', NULL, 'regular');
CALL insertar_alumno_con_vinculos('08A00017', 'Paola', 'Vega', 'López', 'paola.vega8@uvmnet.edu', 8, 1, '3', '2004-08-25', NULL, 'regular');
CALL insertar_alumno_con_vinculos('08A00018', 'Daniel', 'Navarro', 'Santos', 'daniel.navarro8@uvmnet.edu', 8, 1, '3', '2004-10-03', NULL, 'regular');
CALL insertar_alumno_con_vinculos('08A00019', 'Valentina', 'Gómez', 'Ramírez', 'valentina.gomez8@uvmnet.edu', 8, 1, '3', '2004-11-12', NULL, 'regular');
CALL insertar_alumno_con_vinculos('08A00020', 'Emilio', 'Soto', 'Martínez', 'emilio.soto8@uvmnet.edu', 8, 1, '3', '2004-12-21', NULL, 'regular');

-- Puebla (prefijo 10)
CALL insertar_alumno_con_vinculos('10A00001', 'Pablo', 'Santos', 'Hernández', 'pablo.santos10@uvmnet.edu', 10, 4, '2', '2004-10-10', NULL, 'regular');
CALL insertar_alumno_con_vinculos('10A00002', 'María', 'Gómez', 'López', 'maria.gomez10@uvmnet.edu', 10, 4, '2', '2004-01-15', NULL, 'regular');
CALL insertar_alumno_con_vinculos('10A00003', 'Luis', 'Ramírez', 'Martínez', 'luis.ramirez10@uvmnet.edu', 10, 4, '2', '2004-02-20', NULL, 'regular');
CALL insertar_alumno_con_vinculos('10A00004', 'Ana', 'Fernández', 'Soto', 'ana.fernandez10@uvmnet.edu', 10, 4, '2', '2004-03-25', NULL, 'regular');
CALL insertar_alumno_con_vinculos('10A00005', 'Carlos', 'Luna', 'Vega', 'carlos.luna10@uvmnet.edu', 10, 4, '2', '2004-04-30', NULL, 'regular');
CALL insertar_alumno_con_vinculos('10A00006', 'Fernanda', 'Navarro', 'Cruz', 'fernanda.navarro10@uvmnet.edu', 10, 4, '2', '2004-05-05', NULL, 'regular');
CALL insertar_alumno_con_vinculos('10A00007', 'Miguel', 'Santos', 'Jiménez', 'miguel.santos10@uvmnet.edu', 10, 4, '2', '2004-06-10', NULL, 'regular');
CALL insertar_alumno_con_vinculos('10A00008', 'Andrea', 'García', 'Flores', 'andrea.garcia10@uvmnet.edu', 10, 4, '2', '2004-07-15', NULL, 'regular');
CALL insertar_alumno_con_vinculos('10A00009', 'Javier', 'Pérez', 'Beltrán', 'javier.perez10@uvmnet.edu', 10, 4, '2', '2004-08-20', NULL, 'regular');
CALL insertar_alumno_con_vinculos('10A00010', 'Sofía', 'Morales', 'Ruiz', 'sofia.morales10@uvmnet.edu', 10, 4, '2', '2004-09-25', NULL, 'regular');
CALL insertar_alumno_con_vinculos('10A00011', 'Valeria', 'Castillo', 'Santos', 'valeria.castillo10@uvmnet.edu', 10, 4, '2', '2004-11-30', NULL, 'regular');
CALL insertar_alumno_con_vinculos('10A00012', 'Jorge', 'Martínez', 'Gómez', 'jorge.martinez10@uvmnet.edu', 10, 4, '2', '2004-12-05', NULL, 'regular');
CALL insertar_alumno_con_vinculos('10A00013', 'Camila', 'Hernández', 'López', 'camila.hernandez10@uvmnet.edu', 10, 4, '2', '2004-01-10', NULL, 'regular');
CALL insertar_alumno_con_vinculos('10A00014', 'Alejandro', 'Vega', 'Ramírez', 'alejandro.vega10@uvmnet.edu', 10, 4, '2', '2004-02-15', NULL, 'regular');
CALL insertar_alumno_con_vinculos('10A00015', 'Lucía', 'Soto', 'Fernández', 'lucia.soto10@uvmnet.edu', 10, 4, '2', '2004-03-20', NULL, 'regular');
CALL insertar_alumno_con_vinculos('10A00016', 'Antonio', 'Jiménez', 'Morales', 'antonio.jimenez10@uvmnet.edu', 10, 4, '2', '2004-04-25', NULL, 'regular');
CALL insertar_alumno_con_vinculos('10A00017', 'Regina', 'Flores', 'Navarro', 'regina.flores10@uvmnet.edu', 10, 4, '2', '2004-05-30', NULL, 'regular');
CALL insertar_alumno_con_vinculos('10A00018', 'Iván', 'Luna', 'Castillo', 'ivan.luna10@uvmnet.edu', 10, 4, '2', '2004-06-04', NULL, 'regular');
CALL insertar_alumno_con_vinculos('10A00019', 'María José', 'Beltrán', 'Santos', 'mariajose.beltran10@uvmnet.edu', 10, 4, '2', '2004-07-09', NULL, 'regular');
CALL insertar_alumno_con_vinculos('10A00020', 'Emilio', 'Gómez', 'Paz', 'emilio.gomez10@uvmnet.edu', 10, 4, '2', '2004-08-14', NULL, 'regular');

-- Monterrey Cumbres (prefijo 14)
CALL insertar_alumno_con_vinculos('14A00001', 'Sergio', 'Duarte', 'Mora', 'sergio.duarte14@uvmnet.edu', 14, 1, '8', '1999-12-01', NULL, 'regular');
CALL insertar_alumno_con_vinculos('14A00002', 'Mariana', 'Gómez', 'López', 'mariana.gomez14@uvmnet.edu', 14, 1, '8', '2000-01-10', NULL, 'regular');
CALL insertar_alumno_con_vinculos('14A00003', 'Luis', 'Ramírez', 'Martínez', 'luis.ramirez14@uvmnet.edu', 14, 1, '8', '2000-02-19', NULL, 'regular');
CALL insertar_alumno_con_vinculos('14A00004', 'Ana', 'Fernández', 'Soto', 'ana.fernandez14@uvmnet.edu', 14, 1, '8', '2000-03-28', NULL, 'regular');
CALL insertar_alumno_con_vinculos('14A00005', 'Carlos', 'Luna', 'Vega', 'carlos.luna14@uvmnet.edu', 14, 1, '8', '2000-04-06', NULL, 'regular');
CALL insertar_alumno_con_vinculos('14A00006', 'Fernanda', 'Navarro', 'Cruz', 'fernanda.navarro14@uvmnet.edu', 14, 1, '8', '2000-05-15', NULL, 'regular');
CALL insertar_alumno_con_vinculos('14A00007', 'Miguel', 'Santos', 'Jiménez', 'miguel.santos14@uvmnet.edu', 14, 1, '8', '2000-06-24', NULL, 'regular');
CALL insertar_alumno_con_vinculos('14A00008', 'Andrea', 'García', 'Flores', 'andrea.garcia14@uvmnet.edu', 14, 1, '8', '2000-07-03', NULL, 'regular');
CALL insertar_alumno_con_vinculos('14A00009', 'Javier', 'Pérez', 'Beltrán', 'javier.perez14@uvmnet.edu', 14, 1, '8', '2000-08-12', NULL, 'regular');
CALL insertar_alumno_con_vinculos('14A00010', 'Sofía', 'Morales', 'Ruiz', 'sofia.morales14@uvmnet.edu', 14, 1, '8', '2000-09-21', NULL, 'regular');
CALL insertar_alumno_con_vinculos('14A00011', 'Valeria', 'Castillo', 'Santos', 'valeria.castillo14@uvmnet.edu', 14, 1, '8', '2000-10-30', NULL, 'regular');
CALL insertar_alumno_con_vinculos('14A00012', 'Jorge', 'Martínez', 'Gómez', 'jorge.martinez14@uvmnet.edu', 14, 1, '8', '2000-11-08', NULL, 'regular');
CALL insertar_alumno_con_vinculos('14A00013', 'Camila', 'Hernández', 'López', 'camila.hernandez14@uvmnet.edu', 14, 1, '8', '2000-12-17', NULL, 'regular');
CALL insertar_alumno_con_vinculos('14A00014', 'Alejandro', 'Vega', 'Ramírez', 'alejandro.vega14@uvmnet.edu', 14, 1, '8', '2001-01-26', NULL, 'regular');
CALL insertar_alumno_con_vinculos('14A00015', 'Lucía', 'Soto', 'Fernández', 'lucia.soto14@uvmnet.edu', 14, 1, '8', '2001-03-07', NULL, 'regular');
CALL insertar_alumno_con_vinculos('14A00016', 'Antonio', 'Jiménez', 'Morales', 'antonio.jimenez14@uvmnet.edu', 14, 1, '8', '2001-04-16', NULL, 'regular');
CALL insertar_alumno_con_vinculos('14A00017', 'Regina', 'Flores', 'Navarro', 'regina.flores14@uvmnet.edu', 14, 1, '8', '2001-05-25', NULL, 'regular');
CALL insertar_alumno_con_vinculos('14A00018', 'Iván', 'Luna', 'Castillo', 'ivan.luna14@uvmnet.edu', 14, 1, '8', '2001-07-04', NULL, 'regular');
CALL insertar_alumno_con_vinculos('14A00019', 'María José', 'Beltrán', 'Santos', 'mariajose.beltran14@uvmnet.edu', 14, 1, '8', '2001-08-13', NULL, 'regular');
CALL insertar_alumno_con_vinculos('14A00020', 'Emilio', 'Gómez', 'Paz', 'emilio.gomez14@uvmnet.edu', 14, 1, '8', '2001-09-22', NULL, 'regular');

-- Toluca (prefijo 16)
CALL insertar_alumno_con_vinculos('16A00001', 'Andrea', 'Cervantes', 'Núñez', 'andrea.cervantes16@uvmnet.edu', 16, 2, '5', '2001-05-05', NULL, 'regular');
CALL insertar_alumno_con_vinculos('16A00002', 'Pablo', 'Santos', 'Hernández', 'pablo.santos16@uvmnet.edu', 16, 2, '5', '2001-06-10', NULL, 'regular');
CALL insertar_alumno_con_vinculos('16A00003', 'María', 'Gómez', 'López', 'maria.gomez16@uvmnet.edu', 16, 2, '5', '2001-07-15', NULL, 'regular');
CALL insertar_alumno_con_vinculos('16A00004', 'Luis', 'Ramírez', 'Martínez', 'luis.ramirez16@uvmnet.edu', 16, 2, '5', '2001-08-20', NULL, 'regular');
CALL insertar_alumno_con_vinculos('16A00005', 'Ana', 'Fernández', 'Soto', 'ana.fernandez16@uvmnet.edu', 16, 2, '5', '2001-09-25', NULL, 'regular');
CALL insertar_alumno_con_vinculos('16A00006', 'Carlos', 'Luna', 'Vega', 'carlos.luna16@uvmnet.edu', 16, 2, '5', '2001-10-30', NULL, 'regular');
CALL insertar_alumno_con_vinculos('16A00007', 'Fernanda', 'Navarro', 'Cruz', 'fernanda.navarro16@uvmnet.edu', 16, 2, '5', '2001-12-05', NULL, 'regular');
CALL insertar_alumno_con_vinculos('16A00008', 'Miguel', 'Santos', 'Jiménez', 'miguel.santos16@uvmnet.edu', 16, 2, '5', '2002-01-10', NULL, 'regular');
CALL insertar_alumno_con_vinculos('16A00009', 'Andrea', 'García', 'Flores', 'andrea.garcia16@uvmnet.edu', 16, 2, '5', '2002-02-15', NULL, 'regular');
CALL insertar_alumno_con_vinculos('16A00010', 'Javier', 'Pérez', 'Beltrán', 'javier.perez16@uvmnet.edu', 16, 2, '5', '2002-03-20', NULL, 'regular');
CALL insertar_alumno_con_vinculos('16A00011', 'Sofía', 'Morales', 'Ruiz', 'sofia.morales16@uvmnet.edu', 16, 2, '5', '2002-04-25', NULL, 'regular');
CALL insertar_alumno_con_vinculos('16A00012', 'Valeria', 'Castillo', 'Santos', 'valeria.castillo16@uvmnet.edu', 16, 2, '5', '2002-05-30', NULL, 'regular');
CALL insertar_alumno_con_vinculos('16A00013', 'Jorge', 'Martínez', 'Gómez', 'jorge.martinez16@uvmnet.edu', 16, 2, '5', '2002-06-04', NULL, 'regular');
CALL insertar_alumno_con_vinculos('16A00014', 'Camila', 'Hernández', 'López', 'camila.hernandez16@uvmnet.edu', 16, 2, '5', '2002-07-09', NULL, 'regular');
CALL insertar_alumno_con_vinculos('16A00015', 'Alejandro', 'Vega', 'Ramírez', 'alejandro.vega16@uvmnet.edu', 16, 2, '5', '2002-08-14', NULL, 'regular');
CALL insertar_alumno_con_vinculos('16A00016', 'Lucía', 'Soto', 'Fernández', 'lucia.soto16@uvmnet.edu', 16, 2, '5', '2002-09-19', NULL, 'regular');
CALL insertar_alumno_con_vinculos('16A00017', 'Antonio', 'Jiménez', 'Morales', 'antonio.jimenez16@uvmnet.edu', 16, 2, '5', '2002-10-24', NULL, 'regular');
CALL insertar_alumno_con_vinculos('16A00018', 'Regina', 'Flores', 'Navarro', 'regina.flores16@uvmnet.edu', 16, 2, '5', '2002-11-29', NULL, 'regular');
CALL insertar_alumno_con_vinculos('16A00019', 'Iván', 'Luna', 'Castillo', 'ivan.luna16@uvmnet.edu', 16, 2, '5', '2002-12-04', NULL, 'regular');
CALL insertar_alumno_con_vinculos('16A00020', 'María José', 'Beltrán', 'Santos', 'mariajose.beltran16@uvmnet.edu', 16, 2, '5', '2003-01-09', NULL, 'regular');

-- Querétaro (prefijo 17)
CALL insertar_alumno_con_vinculos('17A00001', 'Luis', 'Beltrán', 'Ramos', 'luis.beltran17@uvmnet.edu', 17, 3, '1', '2004-04-04', NULL, 'regular');
CALL insertar_alumno_con_vinculos('17A00002', 'María', 'Gómez', 'López', 'maria.gomez17@uvmnet.edu', 17, 3, '1', '2004-05-09', NULL, 'regular');
CALL insertar_alumno_con_vinculos('17A00003', 'Luis', 'Ramírez', 'Martínez', 'luis.ramirez17@uvmnet.edu', 17, 3, '1', '2004-06-14', NULL, 'regular');
CALL insertar_alumno_con_vinculos('17A00004', 'Ana', 'Fernández', 'Soto', 'ana.fernandez17@uvmnet.edu', 17, 3, '1', '2004-07-19', NULL, 'regular');
CALL insertar_alumno_con_vinculos('17A00005', 'Carlos', 'Luna', 'Vega', 'carlos.luna17@uvmnet.edu', 17, 3, '1', '2004-08-24', NULL, 'regular');
CALL insertar_alumno_con_vinculos('17A00006', 'Fernanda', 'Navarro', 'Cruz', 'fernanda.navarro17@uvmnet.edu', 17, 3, '1', '2004-09-29', NULL, 'regular');
CALL insertar_alumno_con_vinculos('17A00007', 'Miguel', 'Santos', 'Jiménez', 'miguel.santos17@uvmnet.edu', 17, 3, '1', '2004-11-03', NULL, 'regular');
CALL insertar_alumno_con_vinculos('17A00008', 'Andrea', 'García', 'Flores', 'andrea.garcia17@uvmnet.edu', 17, 3, '1', '2004-12-08', NULL, 'regular');
CALL insertar_alumno_con_vinculos('17A00009', 'Javier', 'Pérez', 'Beltrán', 'javier.perez17@uvmnet.edu', 17, 3, '1', '2005-01-13', NULL, 'regular');
CALL insertar_alumno_con_vinculos('17A00010', 'Sofía', 'Morales', 'Ruiz', 'sofia.morales17@uvmnet.edu', 17, 3, '1', '2005-02-18', NULL, 'regular');
CALL insertar_alumno_con_vinculos('17A00011', 'Valeria', 'Castillo', 'Santos', 'valeria.castillo17@uvmnet.edu', 17, 3, '1', '2005-03-25', NULL, 'regular');
CALL insertar_alumno_con_vinculos('17A00012', 'Jorge', 'Martínez', 'Gómez', 'jorge.martinez17@uvmnet.edu', 17, 3, '1', '2005-04-30', NULL, 'regular');
CALL insertar_alumno_con_vinculos('17A00013', 'Camila', 'Hernández', 'López', 'camila.hernandez17@uvmnet.edu', 17, 3, '1', '2005-06-04', NULL, 'regular');
CALL insertar_alumno_con_vinculos('17A00014', 'Alejandro', 'Vega', 'Ramírez', 'alejandro.vega17@uvmnet.edu', 17, 3, '1', '2005-07-09', NULL, 'regular');
CALL insertar_alumno_con_vinculos('17A00015', 'Lucía', 'Soto', 'Fernández', 'lucia.soto17@uvmnet.edu', 17, 3, '1', '2005-08-14', NULL, 'regular');
CALL insertar_alumno_con_vinculos('17A00016', 'Antonio', 'Jiménez', 'Morales', 'antonio.jimenez17@uvmnet.edu', 17, 3, '1', '2005-09-19', NULL, 'regular');
CALL insertar_alumno_con_vinculos('17A00017', 'Regina', 'Flores', 'Navarro', 'regina.flores17@uvmnet.edu', 17, 3, '1', '2005-10-24', NULL, 'regular');
CALL insertar_alumno_con_vinculos('17A00018', 'Iván', 'Luna', 'Castillo', 'ivan.luna17@uvmnet.edu', 17, 3, '1', '2005-11-29', NULL, 'regular');
CALL insertar_alumno_con_vinculos('17A00019', 'María José', 'Beltrán', 'Santos', 'mariajose.beltran17@uvmnet.edu', 17, 3, '1', '2005-12-04', NULL, 'regular');
CALL insertar_alumno_con_vinculos('17A00020', 'Emilio', 'Gómez', 'Paz', 'emilio.gomez17@uvmnet.edu', 17, 3, '1', '2006-01-09', NULL, 'regular');

-- Insertar admin 
INSERT INTO admin_users (username, password) VALUES ('admin', NULL) ON DUPLICATE KEY UPDATE username=username;

-- Insertar docentes para campus de intercambio
-- Toronto (prefijo 20)
CALL insertar_docente_con_campus('20D00001', 'Robert', 'Mitchell', 'Thompson', 'robert.mitchell@uvm.mx', 'Sistemas', '1980-03-15', 20, NULL);
CALL insertar_docente_con_campus('20D00002', 'Jennifer', 'Taylor', 'Anderson', 'jennifer.taylor@uvm.mx', 'Administración', '1985-07-22', 20, NULL);

-- Madrid (prefijo 21)
CALL insertar_docente_con_campus('21D00001', 'Juan Carlos', 'García', 'Rodríguez', 'juancarlos.garcia@uvm.mx', 'Industrial', '1978-11-05', 21, NULL);
CALL insertar_docente_con_campus('21D00002', 'María', 'López', 'Fernández', 'maria.lopez@uvm.mx', 'Psicología', '1982-09-18', 21, NULL);

-- Sao Paulo (prefijo 22)
CALL insertar_docente_con_campus('22D00001', 'Paulo', 'Silva', 'Santos', 'paulo.silva@uvm.mx', 'Sistemas', '1979-02-28', 22, NULL);
CALL insertar_docente_con_campus('22D00002', 'Beatriz', 'Oliveira', 'Souza', 'beatriz.oliveira@uvm.mx', 'Mecánica', '1984-06-10', 22, NULL);

-- Sydney (prefijo 23)
CALL insertar_docente_con_campus('23D00001', 'David', 'Johnson', 'Williams', 'david.johnson@uvm.mx', 'Eléctrica', '1976-12-01', 23, NULL);
CALL insertar_docente_con_campus('23D00002', 'Sarah', 'Brown', 'Davis', 'sarah.brown@uvm.mx', 'Administración', '1983-04-14', 23, NULL);

-- Tokyo (prefijo 24)
CALL insertar_docente_con_campus('24D00001', 'Takeshi', 'Yamamoto', 'Tanaka', 'takeshi.yamamoto@uvm.mx', 'Sistemas', '1981-08-20', 24, NULL);
CALL insertar_docente_con_campus('24D00002', 'Yumiko', 'Sato', 'Nakamura', 'yumiko.sato@uvm.mx', 'Mercadotecnia', '1986-01-11', 24, NULL);

-- Insertar semestres para docentes de intercambio
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='20D00001'),'3','Programación Estructurada III','PE-301','2025-01-15','2025-05-30',20,1);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='20D00002'),'4','Comportamiento Organizacional','CO-401','2025-01-15','2025-05-30',20,3);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='20D00002'),'5','Gestión Estratégica','GE-501','2025-01-15','2025-05-30',20,3);

CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='21D00001'),'3','Procesos Industriales I','PI-301','2025-01-15','2025-05-30',21,2);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='21D00001'),'5','Gestión de Producción','GP-501','2025-01-15','2025-05-30',21,2);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='21D00002'),'2','Psicología Social I','PS-201','2025-01-15','2025-05-30',21,4);

CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='22D00001'),'4','Bases de Datos I','BD-401','2025-01-15','2025-05-30',22,1);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='22D00001'),'6','Arquitectura de Software','AS-601','2025-01-15','2025-05-30',22,1);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='22D00002'),'4','Dinámica de Sistemas Mecánicos','DSM-401','2025-01-15','2025-05-30',22,6);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='22D00002'),'5','Materiales Industriales','MI-501','2025-01-15','2025-05-30',22,6);

CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='23D00001'),'6','Electrónica Industrial','EI-601','2025-01-15','2025-05-30',23,5);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='23D00001'),'7','Sistemas de Potencia','SP-701','2025-01-15','2025-05-30',23,5);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='23D00002'),'3','Administración Financiera','AF-301','2025-01-15','2025-05-30',23,3);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='23D00002'),'4','Marketing Operativo','MO-401','2025-01-15','2025-05-30',23,3);

CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='24D00001'),'3','Programación Orientada a Objetos','POO-301','2025-01-15','2025-05-30',24,1);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='24D00001'),'5','Redes de Computadoras','RC-501','2025-01-15','2025-05-30',24,1);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='24D00001'),'6','Sistemas Distribuidos','SD-601','2025-01-15','2025-05-30',24,1);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='24D00002'),'2','Introducción a la Publicidad','IP-201','2025-01-15','2025-05-30',24,8);
CALL insertar_semestre_con_vinculos((SELECT id_docente FROM docentes WHERE matricula='24D00002'),'4','Marketing Digital','MD-401','2025-01-15','2025-05-30',24,8);

-- Insertar 20 alumnos de intercambio
-- Toronto (prefijo 20)
CALL insertar_alumno_con_vinculos('INT20001', 'Emma', 'Johnson', 'Smith', 'emma.johnson@uvmnet.edu', 20, 1, '3', '2002-03-15', NULL, 'intercambio');
CALL insertar_alumno_con_vinculos('INT20002', 'James', 'Wilson', 'Brown', 'james.wilson@uvmnet.edu', 20, 1, '3', '2002-07-22', NULL, 'intercambio');
CALL insertar_alumno_con_vinculos('INT20003', 'Olivia', 'Davis', 'Miller', 'olivia.davis@uvmnet.edu', 20, 3, '4', '2001-11-10', NULL, 'intercambio');
CALL insertar_alumno_con_vinculos('INT20004', 'Masashi', 'Nakamura', 'Hashimoto', 'masashi.nakamura@uvmnet.edu', 20, 3, '5', '2001-05-30', NULL, 'intercambio');
-- Madrid (prefijo 21)
CALL insertar_alumno_con_vinculos('INT21001', 'Lucas', 'Garcia', 'Rodriguez', 'lucas.garcia@uvmnet.edu', 21, 2, '5', '2001-01-05', NULL, 'intercambio');
CALL insertar_alumno_con_vinculos('INT21002', 'Sofia', 'Martinez', 'Gonzalez', 'sofia.martinez@uvmnet.edu', 21, 4, '2', '2003-08-18', NULL, 'intercambio');
CALL insertar_alumno_con_vinculos('INT21003', 'Miguel', 'Hernandez', 'Lopez', 'miguel.hernandez@uvmnet.edu', 21, 2, '3', '2002-04-25', NULL, 'intercambio');
-- Sao Paulo (prefijo 22)
CALL insertar_alumno_con_vinculos('INT22001', 'Isabella', 'Perez', 'Sanchez', 'isabella.perez@uvmnet.edu', 22, 1, '4', '2001-06-12', NULL, 'intercambio');
CALL insertar_alumno_con_vinculos('INT22002', 'Carlos', 'Fernandez', 'Torres', 'carlos.fernandez@uvmnet.edu', 22, 6, '5', '2000-12-30', NULL, 'intercambio');
CALL insertar_alumno_con_vinculos('INT22003', 'Andrea', 'Ramirez', 'Flores', 'andrea.ramirez@uvmnet.edu', 22, 1, '6', '2001-02-14', NULL, 'intercambio');
CALL insertar_alumno_con_vinculos('INT22004', 'Diego', 'Castillo', 'Ruiz', 'diego.castillo@uvmnet.edu', 22, 6, '4', '2002-09-28', NULL, 'intercambio');
-- Sidney (prefijo 23)
CALL insertar_alumno_con_vinculos('INT23001', 'Lucia', 'Moreno', 'Vargas', 'lucia.moreno@uvmnet.edu', 23, 5, '7', '2000-05-19', NULL, 'intercambio');
CALL insertar_alumno_con_vinculos('INT23002', 'Antonio', 'Jimenez', 'Gutierrez', 'antonio.jimenez@uvmnet.edu', 23, 3, '3', '2003-01-08', NULL, 'intercambio');
CALL insertar_alumno_con_vinculos('INT23003', 'Valentina', 'Romero', 'Mendoza', 'valentina.romero@uvmnet.edu', 23, 5, '6', '2001-10-11', NULL, 'intercambio');
CALL insertar_alumno_con_vinculos('INT23004', 'Fernando', 'Ortiz', 'Navarro', 'fernando.ortiz@uvmnet.edu', 23, 3, '4', '2002-08-03', NULL, 'intercambio');
-- Tokyo (prefijo 24)
CALL insertar_alumno_con_vinculos('INT24001', 'Camila', 'Silva', 'Soto', 'camila.silva@uvmnet.edu', 24, 1, '5', '2001-04-21', NULL, 'intercambio');
CALL insertar_alumno_con_vinculos('INT24002', 'Kenji', 'Tanaka', 'Yamamoto', 'kenji.tanaka@uvmnet.edu', 24, 1, '3', '2002-11-07', NULL, 'intercambio');
CALL insertar_alumno_con_vinculos('INT24003', 'Yuki', 'Suzuki', 'Nakamura', 'yuki.suzuki@uvmnet.edu', 24, 8, '4', '2002-03-16', NULL, 'intercambio');
CALL insertar_alumno_con_vinculos('INT24004', 'Hiroshi', 'Sato', 'Kobayashi', 'hiroshi.sato@uvmnet.edu', 24, 1, '6', '2000-09-24', NULL, 'intercambio');
CALL insertar_alumno_con_vinculos('INT24005', 'Sakura', 'Ito', 'Watanabe', 'sakura.ito@uvmnet.edu', 24, 8, '2', '2003-07-13', NULL, 'intercambio');

-- Consultas directas
CALL ver_docentes();
CALL ver_semestres();
CALL ver_alumnos();
CALL ver_evaluaciones();
CALL ver_respuestas();
CALL ver_comentarios();
CALL ver_evaluacion_servicios();
CALL ver_respuestas_servicios();

-- Pruebas
/***
SELECT @@event_scheduler AS event_scheduler;

ALTER EVENT ev_vm_refrescar_resumen_hourly
ON SCHEDULE EVERY 1 MINUTE;

SELECT EVENT_NAME, STATUS, LAST_EXECUTED
FROM information_schema.EVENTS
WHERE EVENT_SCHEMA = 'evaluacion_d'
  AND EVENT_NAME = 'ev_vm_refrescar_resumen_hourly';
  ***/