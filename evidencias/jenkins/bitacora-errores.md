# Bitácora de errores (plantilla)

| Fecha | Etapa | Error observado | Causa probable | Solución |
|-------|--------|-----------------|----------------|----------|
| _ej._ | Docker build | `COPY failed: file not found` | Faltaba `requirements.txt` en el repo | Se añadió `requirements.txt` con la dependencia `requests`. |
| _ej._ | Jenkins | `docker: not found` | Agente sin Docker en PATH | Instalar Docker en el nodo o usar agente con label `docker`. |

Completa las filas con los incidentes reales de tu despliegue y sustituye los ejemplos cuando corresponda.
