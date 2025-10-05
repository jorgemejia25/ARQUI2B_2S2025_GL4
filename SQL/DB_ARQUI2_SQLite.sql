-- ============================================================
-- CREACION BASE Y ESQUEMA IOT (SQLite)
-- ============================================================

-- Crear las tablas principales
CREATE TABLE IF NOT EXISTS Route (
  route_id INTEGER PRIMARY KEY AUTOINCREMENT,
  code     TEXT NOT NULL UNIQUE,
  name     TEXT NULL
);

CREATE TABLE IF NOT EXISTS Stop (
  stop_id INTEGER PRIMARY KEY AUTOINCREMENT,
  name    TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS RouteStop (
  route_id INTEGER NOT NULL,
  stop_id  INTEGER NOT NULL,
  seq      INTEGER NOT NULL,
  PRIMARY KEY (route_id, stop_id),
  FOREIGN KEY (route_id) REFERENCES Route(route_id),
  FOREIGN KEY (stop_id) REFERENCES Stop(stop_id)
);

CREATE TABLE IF NOT EXISTS Bus (
  bus_id   INTEGER PRIMARY KEY AUTOINCREMENT,
  code     TEXT NOT NULL UNIQUE,
  route_id INTEGER NULL,
  FOREIGN KEY (route_id) REFERENCES Route(route_id)
);

CREATE TABLE IF NOT EXISTS AlertType (
  alert_type_id INTEGER PRIMARY KEY AUTOINCREMENT,
  code          TEXT NOT NULL UNIQUE,
  description   TEXT NULL,
  severity_base INTEGER NOT NULL DEFAULT 2
);

-- ============================================================
-- CREACION DE LAS TABLAS PARA SUCESOS CON DETALLE 
-- ============================================================

-- Posiciones de los buses para mostrar en el mapa
CREATE TABLE IF NOT EXISTS BusPosition (
  position_id    INTEGER PRIMARY KEY AUTOINCREMENT,
  ts             DATETIME NOT NULL DEFAULT (datetime('now')),
  bus_id         INTEGER NOT NULL,
  speed_kmh      REAL NULL,
  distance_to_next_stop_m INTEGER NULL,
  FOREIGN KEY (bus_id) REFERENCES Bus(bus_id)
);

-- Tipo de alerta
CREATE TABLE IF NOT EXISTS Alert (
  alert_id       INTEGER PRIMARY KEY AUTOINCREMENT,
  ts             DATETIME NOT NULL DEFAULT (datetime('now')),
  alert_type_id  INTEGER NOT NULL,
  severity       INTEGER NULL,                       
  bus_id         INTEGER NULL,
  stop_id        INTEGER NULL,
  FOREIGN KEY (alert_type_id) REFERENCES AlertType(alert_type_id),
  FOREIGN KEY (bus_id) REFERENCES Bus(bus_id),
  FOREIGN KEY (stop_id) REFERENCES Stop(stop_id)
);

-- Subtipos específicos
CREATE TABLE IF NOT EXISTS TrafficInfraction (
  alert_id       INTEGER PRIMARY KEY,
  signal_color   TEXT NOT NULL,
  FOREIGN KEY (alert_id) REFERENCES Alert(alert_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS PanicEvent (
  alert_id       INTEGER PRIMARY KEY,
  button_id      INTEGER NULL,
  FOREIGN KEY (alert_id) REFERENCES Alert(alert_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS SeismicEvent (
  alert_id       INTEGER PRIMARY KEY,
  intensity_g    REAL NOT NULL,          
  duration_ms    INTEGER NULL,
  FOREIGN KEY (alert_id) REFERENCES Alert(alert_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS GasEvent (
  alert_id       INTEGER PRIMARY KEY,
  ppm            REAL NOT NULL,          
  threshold_ppm  REAL NULL,
  FOREIGN KEY (alert_id) REFERENCES Alert(alert_id) ON DELETE CASCADE
);

-- Series históricas para gráficas
CREATE TABLE IF NOT EXISTS GasMeasurement (
  gas_id         INTEGER PRIMARY KEY AUTOINCREMENT,
  ts             DATETIME NOT NULL DEFAULT (datetime('now')),
  ppm            REAL NOT NULL
);

CREATE TABLE IF NOT EXISTS SeismicMeasurement (
  seis_id        INTEGER PRIMARY KEY AUTOINCREMENT,
  ts             DATETIME NOT NULL DEFAULT (datetime('now')),
  intensity_g    REAL NOT NULL
);

-- Crear índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS IX_BusPosition_BusTime ON BusPosition(bus_id, ts DESC);
CREATE INDEX IF NOT EXISTS IX_Alert_TypeTime ON Alert(alert_type_id, ts DESC);
CREATE INDEX IF NOT EXISTS IX_Gas_Time ON GasMeasurement(ts DESC);
CREATE INDEX IF NOT EXISTS IX_Seis_Time ON SeismicMeasurement(ts DESC);

-- ============================================================
-- NUEVAS TABLAS PARA GRUPOS DE SENSORES Y POSICIONES DE BUSES
-- ============================================================

-- Tabla de grupo de sensores activos para Metro
CREATE TABLE IF NOT EXISTS ActiveSensorGroupMetro (
  sensor_group_metro_id INTEGER PRIMARY KEY AUTOINCREMENT,
  ts                    DATETIME NOT NULL DEFAULT (datetime('now')),
  sensor_name           TEXT NOT NULL
);

-- Tabla de grupo de sensores activos para Urbano
CREATE TABLE IF NOT EXISTS ActiveSensorGroupUrban (
  sensor_group_urban_id INTEGER PRIMARY KEY AUTOINCREMENT,
  ts                    DATETIME NOT NULL DEFAULT (datetime('now')),
  sensor_name           TEXT NOT NULL
);

-- Tabla de posición de buses para Metro
CREATE TABLE IF NOT EXISTS BusPositionMetro (
  position_metro_id     INTEGER PRIMARY KEY AUTOINCREMENT,
  ts                    DATETIME NOT NULL DEFAULT (datetime('now')),
  bus_id                INTEGER NOT NULL,
  speed_kmh             REAL NULL,
  position              TEXT NULL,
  distance_to_next_stop REAL NULL,
  FOREIGN KEY (bus_id) REFERENCES Bus(bus_id)
);

-- Tabla de posición de buses para Urbano
CREATE TABLE IF NOT EXISTS BusPositionUrban (
  position_urban_id     INTEGER PRIMARY KEY AUTOINCREMENT,
  ts                    DATETIME NOT NULL DEFAULT (datetime('now')),
  bus_id                INTEGER NOT NULL,
  speed_kmh             REAL NULL,
  position              TEXT NULL,
  distance_to_next_stop REAL NULL,
  FOREIGN KEY (bus_id) REFERENCES Bus(bus_id)
);

-- Índices para las nuevas tablas
CREATE INDEX IF NOT EXISTS IX_ActiveSensorGroupMetro_Time ON ActiveSensorGroupMetro(ts DESC);
CREATE INDEX IF NOT EXISTS IX_ActiveSensorGroupUrban_Time ON ActiveSensorGroupUrban(ts DESC);
CREATE INDEX IF NOT EXISTS IX_BusPositionMetro_BusTime ON BusPositionMetro(bus_id, ts DESC);
CREATE INDEX IF NOT EXISTS IX_BusPositionUrban_BusTime ON BusPositionUrban(bus_id, ts DESC);

-- ============================================================
-- VISTAS O CONSULTAS PARA EL FRONT
-- ============================================================

-- Feed de alertas recientes (SQLite no soporta CREATE VIEW con TOP, usamos LIMIT)
-- Esta vista se puede crear como una consulta en el código de la aplicación

-- ============================================================
-- SEED/DATOS INICIALES EN EL SISTEMA
-- ============================================================

-- Tipos de alerta
INSERT OR IGNORE INTO AlertType (code, description, severity_base) VALUES
  ('INFRACCION', 'Infracción de tráfico (semáforo)', 3),
  ('PANICO',     'Botón de pánico',                  3),
  ('SISMO',      'Evento sísmico',                   3),
  ('GAS',        'Fuga de gas',                      3);

-- Rutas
INSERT OR IGNORE INTO Route (code, name) VALUES
  ('RUTA_TRANSMETRO',  'Ruta Transmetro'),
  ('RUTA_TRANSURBANO', 'Ruta Transurbano');

-- Paradas
INSERT OR IGNORE INTO Stop (name) VALUES
  ('Parada1_Transmetro'),
  ('Parada2_Transmetro'),
  ('Parada1_Transurbano'),
  ('Parada2_Transurbano');

-- BUS Transmetro con route_id
INSERT OR IGNORE INTO Bus (code, route_id)
SELECT 'BUS_TRANSMETRO', r.route_id
FROM Route r
WHERE r.code = 'RUTA_TRANSMETRO';

-- BUS Transurbano con route_id
INSERT OR IGNORE INTO Bus (code, route_id)
SELECT 'BUS_TRANSURBANO', r.route_id
FROM Route r
WHERE r.code = 'RUTA_TRANSURBANO';

-- Relación rutas hacia paradas con orden
INSERT OR IGNORE INTO RouteStop (route_id, stop_id, seq)
SELECT r.route_id, s.stop_id, v.seq
FROM (SELECT 'RUTA_TRANSMETRO' as route_code, 'Parada1_Transmetro' as stop_name, 1 as seq
      UNION ALL
      SELECT 'RUTA_TRANSMETRO', 'Parada2_Transmetro', 2
      UNION ALL
      SELECT 'RUTA_TRANSURBANO', 'Parada1_Transurbano', 1
      UNION ALL
      SELECT 'RUTA_TRANSURBANO', 'Parada2_Transurbano', 2) AS v
JOIN Route r ON r.code = v.route_code
JOIN Stop  s ON s.name = v.stop_name;

-- Verificar que se crearon las tablas
SELECT name FROM sqlite_master WHERE type='table';
