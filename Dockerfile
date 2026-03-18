FROM apache/superset:latest-dev

# Cambiar a usuario root temporalmente para instalar librerías de sistema operativo (Debian/Ubuntu)
USER root

# Actualizar repositorios e instalar el cliente nativo de Firebird (C++) obligatorio para que python pueda conectarse
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends libfbclient2 firebird-dev && \
    rm -rf /var/lib/apt/lists/*

# Descargar e instalar los "dialectos" y drivers compatibles con SQLAlchemy 1.4 de Superset
# Versiones fijadas tras análisis de compatibilidad (Pip list actual):
RUN pip install --no-cache-dir \
    "sqlalchemy-firebird==0.7.6" \
    "fdb==2.0.4" \
    "firebird-driver==1.10.11"

# Volver al usuario seguro de Superset
USER superset
