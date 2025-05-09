import os
from celery.schedules import crontab
from flask_appbuilder.security.manager import AUTH_DB

# Handle environment variables more safely
def get_env_variable(var_name, default=None):
    """Get the environment variable or return default value"""
    try:
        return os.environ[var_name]
    except KeyError:
        if default is not None:
            return default
        raise RuntimeError(
            f"The environment variable {var_name} is required but not set."
        )

# Database connections - handle port as integer
DB_USER = get_env_variable('DATABASE_USER')
DB_PASSWORD = get_env_variable('DATABASE_PASSWORD')
DB_HOST = get_env_variable('DATABASE_HOST')
DB_PORT = int(get_env_variable('DATABASE_PORT', '5432'))  # Changed to 5432 for session mode
DB_NAME = get_env_variable('DATABASE_DB', 'postgres')

# Use SQLite for Superset's metadata
SQLALCHEMY_DATABASE_URI = 'sqlite:////app/superset_home/superset.db'

# Supabase NFL database with session mode connection
DATABASES = {
    'nfl_stats': {
        'allow_csv_upload': False,
        'allow_ctas': False,
        'allow_cvas': False,
        'database_name': 'NFL Statistics',
        'extra': {
            'metadata_params': {},
            'engine_params': {
                'connect_args': {
                    'options': '-c search_path=nfl_stats',
                    'application_name': 'superset',
                    'connect_timeout': 10,
                    'sslmode': 'require'
                }
            },
            'metadata_cache_timeout': {},
            'schemas_allowed_for_csv_upload': []
        },
        'sqlalchemy_uri': f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}",
        'tables': []
    }
}

# Redis configuration - make more resilient
REDIS_HOST = get_env_variable('REDIS_HOST', 'localhost')
REDIS_PORT = int(get_env_variable('REDIS_PORT', '6379'))
REDIS_CELERY_DB = 0
REDIS_RESULTS_DB = 1
REDIS_CACHE_DB = 2

# Cache configuration
CACHE_CONFIG = {
    'CACHE_TYPE': 'redis',
    'CACHE_DEFAULT_TIMEOUT': 300,
    'CACHE_KEY_PREFIX': 'superset_',
    'CACHE_REDIS_HOST': REDIS_HOST,
    'CACHE_REDIS_PORT': REDIS_PORT,
    'CACHE_REDIS_DB': REDIS_CACHE_DB,
}

# Data cache for query results
DATA_CACHE_CONFIG = {
    'CACHE_TYPE': 'redis',
    'CACHE_DEFAULT_TIMEOUT': 3600,
    'CACHE_KEY_PREFIX': 'superset_data_',
    'CACHE_REDIS_HOST': REDIS_HOST,
    'CACHE_REDIS_PORT': REDIS_PORT,
    'CACHE_REDIS_DB': REDIS_CACHE_DB,
}

# Filter state cache
FILTER_STATE_CACHE_CONFIG = {
    'CACHE_TYPE': 'RedisCache',
    'CACHE_DEFAULT_TIMEOUT': 86400,
    'CACHE_KEY_PREFIX': 'superset_filter_',
    'CACHE_REDIS_HOST': REDIS_HOST,
    'CACHE_REDIS_PORT': REDIS_PORT,
    'CACHE_REDIS_DB': REDIS_CACHE_DB,
}

# Explore form data cache
EXPLORE_FORM_DATA_CACHE_CONFIG = {
    'CACHE_TYPE': 'RedisCache',
    'CACHE_DEFAULT_TIMEOUT': 86400,
    'CACHE_KEY_PREFIX': 'superset_explore_',
    'CACHE_REDIS_HOST': REDIS_HOST,
    'CACHE_REDIS_PORT': REDIS_PORT,
    'CACHE_REDIS_DB': REDIS_CACHE_DB,
}

# Celery configuration
class CeleryConfig:
    broker_url = f'redis://{REDIS_HOST}:{REDIS_PORT}/{REDIS_CELERY_DB}'
    imports = (
        'superset.sql_lab',
        'superset.tasks.cache',
        'superset.tasks.scheduler',
    )
    result_backend = f'redis://{REDIS_HOST}:{REDIS_PORT}/{REDIS_RESULTS_DB}'
    worker_prefetch_multiplier = 1
    task_acks_late = False
    beat_schedule = {
        'cache-warmup-hourly': {
            'task': 'cache-warmup',
            'schedule': crontab(minute=0, hour='*'),
        },
        'report-scheduler': {
            'task': 'reports.scheduler',
            'schedule': crontab(minute='*', hour='*'),
        },
    }

CELERY_CONFIG = CeleryConfig

# Security
SECRET_KEY = get_env_variable('SUPERSET_SECRET_KEY', 'thisISaSECRET_1234')
AUTH_TYPE = AUTH_DB

# Web server settings
SUPERSET_WEBSERVER_TIMEOUT = 300
SUPERSET_ENV = get_env_variable('SUPERSET_ENV', 'production')
SUPERSET_WEBSERVER_PROTOCOL = 'https'

# Feature flags
FEATURE_FLAGS = {
    'ALERT_REPORTS': True,
    'DASHBOARD_CACHE': True,
    'DASHBOARD_NATIVE_FILTERS': True,
    'EMBEDDED_SUPERSET': False,
    'ENABLE_TEMPLATE_PROCESSING': False,
    'TAGGING_SYSTEM': True,
    'SQLLAB_BACKEND_PERSISTENCE': True,
}

# Disable example dashboards in production
SUPERSET_LOAD_EXAMPLES = False

# Security configurations
TALISMAN_ENABLED = True
ENABLE_PROXY_FIX = True
PROXY_FIX_CONFIG = {'x_for': 1, 'x_proto': 1, 'x_host': 1, 'x_port': 1, 'x_prefix': 1}

# Health check endpoint configuration
HEALTH_CHECK_ENDPOINT = '/health'