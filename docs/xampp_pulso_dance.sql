-- Josue Ramos expone: estructura relacional, restricciones y vistas SQL.
CREATE DATABASE IF NOT EXISTS pulso_dance
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE pulso_dance;

CREATE TABLE IF NOT EXISTS dancers (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  full_name VARCHAR(160) NOT NULL,
  category VARCHAR(200) NOT NULL,
  career VARCHAR(120) NOT NULL,
  shift VARCHAR(30) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_dancers_name_category (full_name, category)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS evaluators (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  full_name VARCHAR(160) NOT NULL,
  position VARCHAR(120) NOT NULL DEFAULT '',
  PRIMARY KEY (id),
  UNIQUE KEY uq_evaluators_full_name (full_name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS dance_styles (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(160) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_dance_styles_name (name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS criteria (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(160) NOT NULL,
  weight DECIMAL(5,2) NOT NULL DEFAULT 1.00,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_criteria_name (name),
  CONSTRAINT chk_criteria_weight CHECK (weight > 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS evaluations (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  dancer_id INT UNSIGNED NOT NULL,
  evaluator_id INT UNSIGNED NOT NULL,
  dance_style_id INT UNSIGNED NOT NULL,
  evaluated_at DATETIME NOT NULL,
  notes TEXT NOT NULL,
  signature VARCHAR(160) NOT NULL DEFAULT '',
  PRIMARY KEY (id),
  KEY idx_evaluations_date (evaluated_at),
  KEY idx_evaluations_dancer (dancer_id),
  CONSTRAINT fk_evaluations_dancer
    FOREIGN KEY (dancer_id) REFERENCES dancers (id),
  CONSTRAINT fk_evaluations_evaluator
    FOREIGN KEY (evaluator_id) REFERENCES evaluators (id),
  CONSTRAINT fk_evaluations_dance_style
    FOREIGN KEY (dance_style_id) REFERENCES dance_styles (id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS scores (
  evaluation_id INT UNSIGNED NOT NULL,
  criterion_id INT UNSIGNED NOT NULL,
  score DECIMAL(5,2) NOT NULL,
  PRIMARY KEY (evaluation_id, criterion_id),
  CONSTRAINT fk_scores_evaluation
    FOREIGN KEY (evaluation_id) REFERENCES evaluations (id)
    ON DELETE CASCADE,
  CONSTRAINT fk_scores_criterion
    FOREIGN KEY (criterion_id) REFERENCES criteria (id),
  CONSTRAINT chk_scores_range CHECK (score >= 0 AND score <= 25)
) ENGINE=InnoDB;

INSERT IGNORE INTO evaluators (full_name, position) VALUES
  ('Jurado principal', ''),
  ('Jurado invitado', '');

INSERT IGNORE INTO dance_styles (name) VALUES
  ('Salsa'),
  ('Bachata'),
  ('Folklore'),
  ('Contemporaneo');

INSERT IGNORE INTO criteria (name, weight, is_active) VALUES
  ('Tecnica', 1.00, 1),
  ('Expresion y arte', 1.00, 1),
  ('Coreografia', 1.00, 1),
  ('Vestuario y puesta en escena', 1.00, 1);

CREATE OR REPLACE VIEW v_evaluation_summary AS
SELECT
  e.id AS evaluation_id,
  d.id AS dancer_id,
  d.full_name AS dancer_name,
  d.career AS career,
  d.shift AS shift,
  ds.name AS dance_style,
  u.full_name AS evaluator_name,
  u.position AS evaluator_position,
  e.signature AS signature,
  e.evaluated_at AS evaluated_at,
  e.notes AS notes,
  COALESCE(ROUND(SUM(sc.score), 1), 0) AS total_score,
  COALESCE(ROUND(AVG(sc.score), 1), 0) AS average_score,
  COUNT(sc.criterion_id) AS scored_criteria
FROM evaluations e
JOIN dancers d ON d.id = e.dancer_id
JOIN dance_styles ds ON ds.id = e.dance_style_id
JOIN evaluators u ON u.id = e.evaluator_id
LEFT JOIN scores sc ON sc.evaluation_id = e.id
GROUP BY
  e.id, d.id, d.full_name, d.career, d.shift, ds.name,
  u.full_name, u.position, e.signature, e.evaluated_at, e.notes;

CREATE OR REPLACE VIEW v_criterion_performance AS
SELECT
  c.id AS criterion_id,
  c.name AS criterion_name,
  c.weight AS weight,
  COUNT(sc.evaluation_id) AS score_count,
  COALESCE(ROUND(AVG(sc.score), 1), 0) AS average_score
FROM criteria c
LEFT JOIN scores sc ON sc.criterion_id = c.id
WHERE c.is_active = 1
GROUP BY c.id, c.name, c.weight;

-- Consultas de ejemplo para revisar los datos guardados.
SELECT *
FROM v_evaluation_summary
ORDER BY evaluated_at DESC;

SELECT criterion_name, score_count, average_score
FROM v_criterion_performance
ORDER BY average_score DESC, criterion_name;

-- Ejemplo: detalle de calificaciones para una evaluacion.
-- Cambia 1 por el evaluation_id que quieras consultar.
SELECT c.name AS criterion_name, s.score
FROM scores s
JOIN criteria c ON c.id = s.criterion_id
WHERE s.evaluation_id = 1
ORDER BY c.id;