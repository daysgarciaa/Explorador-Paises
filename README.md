# World Explorer

Consulta geográfica y climática de países en tiempo real usando APIs públicas (sin API key obligatoria).

## Stakeholder y propuesta de valor

**Stakeholder:** Viajero profesional o analista geográfico que necesita datos consolidados de un país (moneda, clima, idioma) desde una sola herramienta portable y reproducible.

**Problema:** Consultar datos de múltiples fuentes implica acceder a varios sitios manualmente. No existe una herramienta CLI unificada.

**Solución:** Script Python contenerizado que, dado el nombre de un país, consulta [RestCountries](https://restcountries.com) y [Open-Meteo](https://open-meteo.com) y entrega un reporte por consola.

## APIs utilizadas

| API | URL | Key requerida |
|-----|-----|:---:|
| RestCountries v3.1 | https://restcountries.com | No |
| Open-Meteo | https://api.open-meteo.com | No |

## Variables de entorno

Toda la configuración sensible o parametrizable se lee con `os.getenv` en `app.py` (no hay tokens hardcodeados).

| Variable | Descripción | Default |
|----------|-------------|---------|
| `COUNTRY_NAME` | País a consultar | `Chile` |
| `REQUEST_TIMEOUT` | Timeout HTTP (segundos) | `10` |

## Ejecución local (sin Docker)

```bash
pip install -r requirements.txt
python app.py
```

En Windows (PowerShell), si `python` no está en el PATH:

```powershell
py -m pip install -r requirements.txt
py app.py
```

Opcional:

```powershell
$env:COUNTRY_NAME = "Japan"
py app.py
```

## Docker: construir y ejecutar

El script `build.sh` (estilo automatización tipo sample-app) **genera el `Dockerfile`**, construye la imagen, ejecuta el contenedor nombrado `samplerunning` y escribe **`output.txt`** con la salida de `docker ps -a` y los logs de la aplicación.

En Linux, macOS o Git Bash:

```bash
chmod +x build.sh
COUNTRY_NAME="Chile" REQUEST_TIMEOUT="10" ./build.sh
```

Comandos equivalentes a mano (tras tener `Dockerfile` y dependencias):

```bash
docker build -t world-explorer .
docker rm -f samplerunning 2>/dev/null || true
docker run --name samplerunning -e COUNTRY_NAME="Chile" -e REQUEST_TIMEOUT="10" world-explorer
docker ps -a
docker logs samplerunning
```

El archivo **`output.txt`** queda en la raíz del proyecto con `docker ps -a` completo, el filtro por contenedor y `docker logs samplerunning` (datos reales devueltos por las APIs cuando hay red). Si abres el repo antes de correr Docker, puede incluir una nota y logs de ejemplo: **vuelve a ejecutar `./build.sh` con Docker activo** y haz commit del `output.txt` actualizado antes de entregar.

## Errores manejados en `app.py`

| Tipo | Situación |
|------|-----------|
| `ConnectionError` | Sin red o servidor caído |
| `Timeout` | Tiempo de espera agotado |
| `HTTPError` 404 | País no encontrado |
| `HTTPError` 401 | Credenciales inválidas (API) |
| `HTTPError` 429 | Rate limit |
| Otros `HTTPError` | Códigos HTTP no esperados |
| `ValueError` / `KeyError` | Datos o JSON inesperados |

## Jenkins

- **BuildAppJob:** job freestyle que clona el repo (credenciales en Jenkins) y ejecuta `./build.sh`. La consola debe mostrar el build de Docker y la salida de la app con datos de API. Guía: `evidencias/jenkins/BuildAppJob-notas.txt`.
- **SamplePipeline:** pipeline en dos etapas (*Preparation* con `catchError`, *Build* invocando `BuildAppJob`). Copia el script del archivo `evidencias/jenkins/SamplePipeline-inline.groovy` en *Pipeline script* de la UI de Jenkins (Stage View mostrará cada etapa en verde/rojo con su duración).

Instrucciones y nombres sugeridos para capturas: `evidencias/jenkins/README.md`. Plantilla de bitácora: `evidencias/jenkins/bitacora-errores.md`.
