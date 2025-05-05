import os
import json
from celery.schedules import crontab
from flask_appbuilder.security.manager import AUTH_DB

# Database connections
SQLALCHEMY_DATABASE_URI = f"postgresql+psycopg2://{os.environ.get('DATABASE_USER')}:{os.environ.get('DATABASE_PASSWORD')}@{os.environ.get('DATABASE_HOST')}:{os.environ.get('DATABASE_PORT')}/{os.environ.get('DATABASE_DB')}"

# Supabase NFL database
DATABASES = {
    'nfl_stats': {
        'allow_csv_upload': False,
        'allow_ctas': False,
        'allow_cvas': False,
        'database_name': 'NFL Statistics',
        'extra': {
            'metadata_params': {},
            'engine_params': {},
            'metadata_cache_timeout': {},
            'schemas_allowed_for_csv_upload': []
        },
        'sqlalchemy_uri': f"postgresql+psycopg2://{os.environ.get('DATABASE_USER')}:{os.environ.get('DATABASE_PASSWORD')}@{os.environ.get('DATABASE_HOST')}:{os.environ.get('DATABASE_PORT')}/{os.environ.get('DATABASE_DB')}",
        'tables': []
    }
}

# Redis configuration with fallback
REDIS_HOST = os.environ.get('REDIS_HOST', '')
REDIS_PORT = os.environ.get('REDIS_PORT', '')
REDIS_CELERY_DB = 0
REDIS_RESULTS_DB = 1
REDIS_CACHE_DB = 2

# Parse environment variables with fallback
def parse_env_config(env_var, default):
    if env_var in os.environ:
        try:
            return json.loads(os.environ[env_var])
        except json.JSONDecodeError:
            pass
    return default

# Cache configuration with fallback
DEFAULT_CACHE = {
    'CACHE_TYPE': 'NullCache',
    'CACHE_DEFAULT_TIMEOUT': 300,
}

# Use Redis if available, otherwise NullCache
if REDIS_HOST and REDIS_PORT:
    CACHE_CONFIG = parse_env_config('CACHE_CONFIG', {
        'CACHE_TYPE': 'redis',
        'CACHE_DEFAULT_TIMEOUT': 300,
        'CACHE_KEY_PREFIX': 'superset_',
        'CACHE_REDIS_HOST': REDIS_HOST,
        'CACHE_REDIS_PORT': REDIS_PORT,
        'CACHE_REDIS_DB': REDIS_CACHE_DB,
    })

    DATA_CACHE_CONFIG = parse_env_config('DATA_CACHE_CONFIG', {
        'CACHE_TYPE': 'redis',
        'CACHE_DEFAULT_TIMEOUT': 3600,
        'CACHE_KEY_PREFIX': 'superset_data_',
        'CACHE_REDIS_HOST': REDIS_HOST,
        'CACHE_REDIS_PORT': REDIS_PORT,
        'CACHE_REDIS_DB': REDIS_CACHE_DB,
    })

    FILTER_STATE_CACHE_CONFIG = parse_env_config('FILTER_STATE_CACHE_CONFIG', {
        'CACHE_TYPE': 'RedisCache',
        'CACHE_DEFAULT_TIMEOUT': 86400,
        'CACHE_KEY_PREFIX': 'superset_filter_',
        'CACHE_REDIS_HOST': REDIS_HOST,
        'CACHE_REDIS_PORT': REDIS_PORT,
        'CACHE_REDIS_DB': REDIS_CACHE_DB,
    })

    EXPLORE_FORM_DATA_CACHE_CONFIG = parse_env_config('EXPLORE_FORM_DATA_CACHE_CONFIG', {
        'CACHE_TYPE': 'RedisCache',
        'CACHE_DEFAULT_TIMEOUT': 86400,
        'CACHE_KEY_PREFIX': 'superset_explore_',
        'CACHE_REDIS_HOST': REDIS_HOST,
        'CACHE_REDIS_PORT': REDIS_PORT,
        'CACHE_REDIS_DB': REDIS_CACHE_DB,
    })
else:
    # Fallback to NullCache when Redis is not available
    CACHE_CONFIG = DEFAULT_CACHE
    DATA_CACHE_CONFIG = DEFAULT_CACHE
    FILTER_STATE_CACHE_CONFIG = DEFAULT_CACHE
    EXPLORE_FORM_DATA_CACHE_CONFIG = DEFAULT_CACHE

# Celery configuration
class CeleryConfig:
    broker_url = f'redis://{REDIS_HOST}:{REDIS_PORT}/{REDIS_CELERY_DB}' if REDIS_HOST and REDIS_PORT else None
    imports = (
        'superset.sql_lab',
        'superset.tasks.cache',
        'superset.tasks.scheduler',
    )
    result_backend = f'redis://{REDIS_HOST}:{REDIS_PORT}/{REDIS_RESULTS_DB}' if REDIS_HOST and REDIS_PORT else None
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

CELERY_CONFIG = CeleryConfig if REDIS_HOST and REDIS_PORT else None

# Security
SECRET_KEY = os.environ.get('SUPERSET_SECRET_KEY', 'thisISaSECRET_1234')
AUTH_TYPE = AUTH_DB

# Web server settings
SUPERSET_WEBSERVER_TIMEOUT = 300
SUPERSET_ENV = os.environ.get('SUPERSET_ENV', 'production')
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