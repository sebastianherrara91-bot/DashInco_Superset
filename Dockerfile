FROM apache/superset:latest-dev

# Cambiar a usuario root temporalmente para instalar librerías de sistema operativo (Debian/Ubuntu)
USER root

# Actualizar repositorios e instalar el cliente nativo de Firebird (C++) obligatorio para que python pueda conectarse
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends libfbclient2 firebird-dev && \
    rm -rf /var/lib/apt/lists/*

# Volver al usuario seguro de Superset
USER superset

# Descargar e instalar los "dialectos" y drivers de interconexión para Python/SQLAlchemy
RUN pip install --no-cache-dir sqlalchemy-firebird fdb firebird-driver
