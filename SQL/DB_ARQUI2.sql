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
  lat     DECIMAL(10,7) NULL,
  lon     DECIMAL(10,7) NULL
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
  lat            DECIMAL(10,7) NOT NULL,
  lon            DECIMAL(10,7) NOT NULL,
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
  lat            DECIMAL(10,7) NULL,
  lon            DECIMAL(10,7) NULL
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
  lat            DECIMAL(10,7) NULL,
  lon            DECIMAL(10,7) NULL
);
CREATE INDEX IX_Gas_Time ON iot.GasMeasurement(ts DESC);

CREATE TABLE iot.SeismicMeasurement (
  seis_id        BIGINT IDENTITY PRIMARY KEY,
  ts             DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
  intensity_g    DECIMAL(8,4) NOT NULL,
  lat            DECIMAL(10,7) NULL,
  lon            DECIMAL(10,7) NULL
);
CREATE INDEX IX_Seis_Time ON iot.SeismicMeasurement(ts DESC);
