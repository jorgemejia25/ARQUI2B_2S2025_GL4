# Grafana para IoT ARQUI2

Este folder levanta Grafana con:
- Provisión automática de datasource SQLite (frser-sqlite-datasource)
- Provisión automática de dashboards desde `infra/grafana/dashboards`
- Montaje de la base de datos en `/var/lib/grafana/databases`

## Requisitos
- Docker y Docker Compose
- El archivo de base de datos SQLite llamado `iot.db` dentro de `../../data` (ruta relativa a este folder).
  - En tiempo de ejecución se monta como `/var/lib/grafana/databases/iot.db`

## Levantar

```bash
# Desde infra/grafana
docker compose up -d
```

Accede a http://localhost:3000 (usuario y contraseña: `admin` / `admin`).

## Cómo se garantiza que el dashboard sea igual para todos
- El datasource se crea vía provisioning con nombre `SQLite` y es default (credentials y ruta fijas).
- Los dashboards se importan automáticamente desde archivos JSON con UID estable.
- El JSON del dashboard fija `timezone=utc`, `refresh=10s`, `editable=false` y `time=now-24h..now`.

## Estructura relevante
- `provisioning/datasources/sqlite.yaml`: Datasource SQLite apuntando a `/var/lib/grafana/databases/iot.db`.
- `provisioning/dashboards/dashboards.yaml`: Proveedor de dashboards apuntando a `/var/lib/grafana/dashboards`.
- `dashboards/iot_overview.json`: Dashboard principal con UID `iot-overview`.

## Notas
- Asegúrate de colocar `iot.db` en `ARQUI2B_2S2025_GL4/data/` antes de levantar.
- Si cambias el nombre o ubicación del archivo `.db`, actualiza `sqlite.yaml` y el volumen en `docker-compose.yml`.
