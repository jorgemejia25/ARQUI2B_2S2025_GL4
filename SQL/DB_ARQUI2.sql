/* ============================================================
   CREACION BASE Y ESQUEMA IOT
   ============================================================ */
IF DB_ID('ARQUI_2') IS NULL
BEGIN
  CREATE DATABASE SmartCity;
END
GO
USE ARQUI_2;
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name='iot')
  EXEC('CREATE SCHEMA iot');
GO

/* ============================================================
   CREACION DE TABLAS PRINCIPALES
   ============================================================ */
CREATE TABLE iot.Route (
  route_id INT IDENTITY PRIMARY KEY,
  code     NVARCHAR(40) NOT NULL UNIQUE,
  name     NVARCHAR(120) NULL
);

CREATE TABLE iot.Stop (
  stop_id INT IDENTITY PRIMARY KEY,
  name    NVARCHAR(120) NOT NULL,
);

CREATE TABLE iot.RouteStop (
  route_id INT NOT NULL REFERENCES iot.Route(route_id),
  stop_id  INT NOT NULL REFERENCES iot.Stop(stop_id),
  seq      INT NOT NULL,
  PRIMARY KEY (route_id, stop_id)
);

CREATE TABLE iot.Bus (
  bus_id   INT IDENTITY PRIMARY KEY,
  code     NVARCHAR(40) NOT NULL UNIQUE,
  route_id INT NULL REFERENCES iot.Route(route_id)
);

CREATE TABLE iot.AlertType (
  alert_type_id INT IDENTITY PRIMARY KEY,
  code          NVARCHAR(40) NOT NULL UNIQUE,
  description   NVARCHAR(200) NULL,
  severity_base TINYINT NOT NULL DEFAULT 2
);

/* ============================================================
   CREACION DE LAS TABLAS PARA SUCESOS CON DETALLE 
   ============================================================ */

-- Posiciones de los buses para mostrar en el mapa
CREATE TABLE iot.BusPosition (
  position_id    BIGINT IDENTITY PRIMARY KEY,
  ts             DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  bus_id         INT NOT NULL REFERENCES iot.Bus(bus_id),
  speed_kmh      DECIMAL(10,3) NULL,
  distance_to_next_stop_m INT NULL
);
CREATE INDEX IX_BusPosition_BusTime ON iot.BusPosition(bus_id, ts DESC);

-- Tipo de alerta
CREATE TABLE iot.Alert (
  alert_id       BIGINT IDENTITY PRIMARY KEY,
  ts             DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  alert_type_id  INT NOT NULL REFERENCES iot.AlertType(alert_type_id),
  severity       TINYINT NULL,                       
  bus_id         INT NULL REFERENCES iot.Bus(bus_id),
  stop_id        INT NULL REFERENCES iot.Stop(stop_id),
);
CREATE INDEX IX_Alert_TypeTime ON iot.Alert(alert_type_id, ts DESC);

-- Subtipos específicos
CREATE TABLE iot.TrafficInfraction (
  alert_id       BIGINT PRIMARY KEY REFERENCES iot.Alert(alert_id) ON DELETE CASCADE,
  signal_color   NVARCHAR(10) NOT NULL,             
);

CREATE TABLE iot.PanicEvent (
  alert_id       BIGINT PRIMARY KEY REFERENCES iot.Alert(alert_id) ON DELETE CASCADE,
  button_id      INT NULL
);

CREATE TABLE iot.SeismicEvent (
  alert_id       BIGINT PRIMARY KEY REFERENCES iot.Alert(alert_id) ON DELETE CASCADE,
  intensity_g    DECIMAL(8,4) NOT NULL,          
  duration_ms    INT NULL
);

CREATE TABLE iot.GasEvent (
  alert_id       BIGINT PRIMARY KEY REFERENCES iot.Alert(alert_id) ON DELETE CASCADE,
  ppm            DECIMAL(10,2) NOT NULL,          
  threshold_ppm  DECIMAL(10,2) NULL
);

-- Series históricas para gráficas
CREATE TABLE iot.GasMeasurement (
  gas_id         BIGINT IDENTITY PRIMARY KEY,
  ts             DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  ppm            DECIMAL(10,2) NOT NULL,
);
CREATE INDEX IX_Gas_Time ON iot.GasMeasurement(ts DESC);

CREATE TABLE iot.SeismicMeasurement (
  seis_id        BIGINT IDENTITY PRIMARY KEY,
  ts             DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  intensity_g    DECIMAL(8,4) NOT NULL,
);
CREATE INDEX IX_Seis_Time ON iot.SeismicMeasurement(ts DESC);


/* ============================================================
   VISTAS O CONSULTAS PARA EL FRONT
   ============================================================ */

-- Feed de alertas recientes
CREATE OR ALTER VIEW iot.v_RecentAlerts AS
SELECT TOP (1000)
  a.alert_id, a.ts,
  at.code AS alert_code,
  COALESCE(a.severity, at.severity_base) AS severity,
  b.code  AS bus_code, 
  s.name  AS stop_name
FROM iot.Alert a
LEFT JOIN iot.AlertType at ON a.alert_type_id = at.alert_type_id
LEFT JOIN iot.Bus       b  ON a.bus_id = b.bus_id
LEFT JOIN iot.Stop      s  ON a.stop_id = s.stop_id
WHERE a.ts >= DATEADD(DAY, -1, SYSUTCDATETIME())
ORDER BY a.ts DESC;
GO

-- Series de gas para graficas
CREATE OR ALTER VIEW iot.v_GasTimeSeries AS
SELECT ts, ppm
FROM iot.GasMeasurement;
GO

-- Series de sismo para graficas
CREATE OR ALTER VIEW iot.v_SeismicTimeSeries AS
SELECT ts, intensity_g
FROM iot.SeismicMeasurement;
GO

/* ============================================================
   SEED/DATOS INICIALES EN EL SISTEMA
   ============================================================ */

-- Tipos de alerta
MERGE iot.AlertType AS t
USING (VALUES
  (N'INFRACCION', N'Infracción de tráfico (semáforo)', 3),
  (N'PANICO',     N'Botón de pánico',                  3),
  (N'SISMO',      N'Evento sísmico',                   3),
  (N'GAS',        N'Fuga de gas',                      3)
) AS s(code, description, severity_base)
ON t.code = s.code
WHEN NOT MATCHED THEN
  INSERT(code, description, severity_base) VALUES(s.code, s.description, s.severity_base);
GO

-- Rutas
MERGE iot.Route AS t
USING (VALUES
  (N'RUTA_TRANSMETRO',  N'Ruta Transmetro'),
  (N'RUTA_TRANSURBANO', N'Ruta Transurbano')
) AS s(code, name)
ON t.code = s.code
WHEN NOT MATCHED THEN
  INSERT(code, name) VALUES(s.code, s.name);
GO

-- Paradas
MERGE iot.Stop AS t
USING (VALUES
  (N'Parada1_Transmetro'),
  (N'Parada2_Transmetro'),
  (N'Parada1_Transurbano'),
  (N'Parada2_Transurbano')
) AS s(name)
ON t.name = s.name
WHEN NOT MATCHED THEN
  INSERT(name) VALUES(s.name);
GO

-- BUS Transmetro con route_id
IF NOT EXISTS (SELECT 1 FROM iot.Bus WHERE code = N'BUS_TRANSMETRO')
BEGIN
  INSERT INTO iot.Bus(code, route_id)
  SELECT N'BUS_TRANSMETRO', r.route_id
  FROM iot.Route r
  WHERE r.code = N'RUTA_TRANSMETRO';
END

-- BUS Transurbano con route_id
IF NOT EXISTS (SELECT 1 FROM iot.Bus WHERE code = N'BUS_TRANSURBANO')
BEGIN
  INSERT INTO iot.Bus(code, route_id)
  SELECT N'BUS_TRANSURBANO', r.route_id
  FROM iot.Route r
  WHERE r.code = N'RUTA_TRANSURBANO';
END
GO

UPDATE b
SET b.route_id = r.route_id
FROM iot.Bus b
JOIN iot.Route r ON
       (b.code = N'BUS_TRANSMETRO'  AND r.code = N'RUTA_TRANSMETRO')
    OR (b.code = N'BUS_TRANSURBANO' AND r.code = N'RUTA_TRANSURBANO');



-- Relación rutas hacia paradas con orden
INSERT INTO iot.RouteStop(route_id, stop_id, seq)
SELECT r.route_id, s.stop_id, v.seq
FROM (VALUES
  (N'RUTA_TRANSMETRO',  N'Parada1_Transmetro',   1),
  (N'RUTA_TRANSMETRO',  N'Parada2_Transmetro',   2),
  (N'RUTA_TRANSURBANO', N'Parada1_Transurbano',  1),
  (N'RUTA_TRANSURBANO', N'Parada2_Transurbano',  2)
) AS v(route_code, stop_name, seq)
JOIN iot.Route r ON r.code = v.route_code
JOIN iot.Stop  s ON s.name = v.stop_name
WHERE NOT EXISTS (
  SELECT 1 FROM iot.RouteStop rs
  WHERE rs.route_id = r.route_id AND rs.stop_id = s.stop_id
);
GO
