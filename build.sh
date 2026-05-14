#!/usr/bin/env bash
# Genera Dockerfile, construye la imagen, ejecuta el contenedor y escribe output.txt
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

IMAGE_NAME="world-explorer"
CONTAINER_NAME="samplerunning"
OUT_FILE="output.txt"
COUNTRY="${COUNTRY_NAME:-Chile}"
REQ_TIMEOUT="${REQUEST_TIMEOUT:-10}"

echo "════════════════════════════════════════════════════════"
echo "  World Explorer — Build & Run"
echo "  País: $COUNTRY | timeout: ${REQ_TIMEOUT}s"
echo "════════════════════════════════════════════════════════"

echo ""
echo "▶  [0/4] Limpiando contenedor previo (si existe)..."
docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
echo "   Listo."

echo ""
echo "▶  [1/4] Generando Dockerfile..."
cat > Dockerfile <<'EOF'
FROM python:3.11-slim
LABEL description="World Explorer: consulta geográfica y climática de países."
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
ENV COUNTRY_NAME=Chile
ENV REQUEST_TIMEOUT=10
CMD ["python", "app.py"]
EOF
echo "   Dockerfile generado."

echo ""
echo "▶  [2/4] Construyendo imagen Docker..."
docker build -t "$IMAGE_NAME" .
echo "   Imagen construida."

echo ""
echo "▶  [3/4] Ejecutando contenedor..."
docker run --name "$CONTAINER_NAME" \
  -e COUNTRY_NAME="$COUNTRY" \
  -e REQUEST_TIMEOUT="$REQ_TIMEOUT" \
  "$IMAGE_NAME"

echo ""
echo "▶  [4/4] Escribiendo ${OUT_FILE} (docker ps -a + logs)..."
{
  echo "========== Registro generado: $(date -u +"%Y-%m-%dT%H:%M:%SZ") (UTC) =========="
  echo ""
  echo "========== docker ps -a =========="
  docker ps -a
  echo ""
  echo "========== filtro name=${CONTAINER_NAME} =========="
  docker ps -a --filter "name=${CONTAINER_NAME}" \
    --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
  echo ""
  echo "========== docker logs ${CONTAINER_NAME} =========="
  docker logs "$CONTAINER_NAME" 2>&1
} | tee "$OUT_FILE"

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Contenedor (resumen):"
docker ps -a --filter "name=${CONTAINER_NAME}" \
  --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
echo "  Salida completa también en: ${OUT_FILE}"
echo "════════════════════════════════════════════════════════"
