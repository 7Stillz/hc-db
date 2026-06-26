# ============================================================
#  hc-db — Imagen versionada de la base de datos (PostgreSQL)
#  Sistema de Historias Clínicas Odontológicas (equipo Vaca Code).
#
#  Empaqueta el esquema completo + datos iniciales DENTRO de la imagen, de modo
#  que `docker run` levante una base de datos lista y reproducible (consistencia
#  dev/prod). El despliegue reutiliza el script maestro del repositorio
#  (deployment/deploy_full.sql), que incluye con \i todo el árbol database/ y
#  seeds/. La versión de la imagen corresponde a la del script (v1.0.0).
#
#  Construir (desde la raíz del repo hc-db):
#     docker build -t hc-db:1.0.0 .
#  Ejecutar:
#     docker run -d --name hc-db -e POSTGRES_PASSWORD=postgres -p 5432:5432 hc-db:1.0.0
#  Verificar el esquema:
#     docker exec -it hc-db psql -U postgres -d historias_clinicas -c "\dt"
# ============================================================
FROM postgres:16-alpine

LABEL org.opencontainers.image.title="hc-db" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.description="Base de datos PostgreSQL del Sistema de Historias Clínicas (esquema + seeds, deploy_full.sql v1.0.0)" \
      org.opencontainers.image.source="https://github.com/7Stillz/hc-db"

# Base de datos que crea el contenedor en el primer arranque.
ENV POSTGRES_DB=historias_clinicas

# Copiamos el repositorio para que los includes relativos (\i ../database/...,
# \i ../seeds/...) de deploy_full.sql resuelvan desde /repo/deployment.
COPY . /repo

# Generamos el script de inicialización DENTRO de la imagen (garantiza LF y
# permisos de ejecución). Se ejecuta en el primer arranque, tras crear la BD:
# entra a deployment/ y corre el deploy maestro contra la base ya creada.
# Nota: se ejecuta igual que el README del repositorio (sin ON_ERROR_STOP), por
# lo que el deploy continúa aunque el script maestro referencie algún archivo
# auxiliar que no existe en el repositorio (2 funciones de conteo de pacientes).
RUN printf '#!/bin/sh\nset -e\necho "==> Desplegando esquema hc-db (deploy_full.sql)..."\ncd /repo/deployment\npsql --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f deploy_full.sql\necho "==> Esquema desplegado."\n' \
      > /docker-entrypoint-initdb.d/10-deploy.sh \
 && chmod +x /docker-entrypoint-initdb.d/10-deploy.sh

EXPOSE 5432
