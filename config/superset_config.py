import os
from datetime import timedelta
from celery.schedules import crontab

# Configuracion de Secret Key (Se espera que se lea desde una variable de entorno en prod)
SECRET_KEY = os.getenv("SUPERSET_SECRET_KEY", "DEVELOPMENT_SECRET_KEY_CHANGE_ME")

# Conexion a la BD de Metadatos de Superset (El contenedor 'db' de Postgres 18)
SQLALCHEMY_DATABASE_URI = 'postgresql+psycopg2://superset:superset_password@db:5432/superset'

# Habilitar opciones de Redis para Celery (Workers)
class CeleryConfig:
    broker_url = "redis://redis:6379/0"
    imports = ("superset.sql_lab",)
    result_backend = "redis://redis:6379/0"
    worker_prefetch_multiplier = 1
    task_acks_late = False
    beat_schedule = {
        "reports.scheduler": {
            "task": "reports.scheduler",
            "schedule": crontab(minute="*", hour="*"),
        },
        "reports.prune_log": {
            "task": "reports.prune_log",
            "schedule": crontab(minute=10, hour=0),
        },
    }

CELERY_CONFIG = CeleryConfig

# Configuracion de la Cache de Datos Generales (Data Cache)
DATA_CACHE_CONFIG = {
    'CACHE_TYPE': 'RedisCache',
    'CACHE_DEFAULT_TIMEOUT': 86400, # 1 dia de cache por defecto
    'CACHE_KEY_PREFIX': 'superset_data_cache_',
    'CACHE_REDIS_URL': 'redis://redis:6379/1'
}

# Configuracion de la Cache de Componentes del Dashboard y Filtros
FILTER_STATE_CACHE_CONFIG = {
    'CACHE_TYPE': 'RedisCache',
    'CACHE_DEFAULT_TIMEOUT': 86400,
    'CACHE_KEY_PREFIX': 'superset_filter_cache_',
    'CACHE_REDIS_URL': 'redis://redis:6379/2'
}

EXPLORE_FORM_DATA_CACHE_CONFIG = {
    'CACHE_TYPE': 'RedisCache',
    'CACHE_DEFAULT_TIMEOUT': 86400,
    'CACHE_KEY_PREFIX': 'superset_explore_cache_',
    'CACHE_REDIS_URL': 'redis://redis:6379/3'
}

# Feature Flags
FEATURE_FLAGS = {
    "DASHBOARD_CROSS_FILTERS": True,    # Permite a los graficos funcionar como filtros para el resto del dashboard
    "ENABLE_TEMPLATE_PROCESSING": True, # Permite el uso de Jinja en las consultas SQL Lab
    "DRILL_TO_DETAIL": True,
    "HORIZONTAL_FILTER_BAR": True,
}

# Configurar Timeouts mas altos para consultas de inventario pesadas
SQLLAB_TIMEOUT = 300 # Seteado a 5 minutos
SUPERSET_WEBSERVER_TIMEOUT = 300

# Reducir el logging a advertencias para evitar llenar el disco de LXC innecesariamente
LOG_LEVEL = 'WARN'
