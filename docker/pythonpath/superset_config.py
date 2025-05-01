import os
from flask_appbuilder.security.manager import AUTH_DB

# Database connections
SQLALCHEMY_DATABASE_URI = f"postgresql+psycopg2://{os.environ.get('DATABASE_USER')}:{os.environ.get('DATABASE_PASSWORD')}@{os.environ.get('DATABASE_HOST')}:{os.environ.get('DATABASE_PORT')}/{os.environ.get('DATABASE_DB')}"

# Supabase NFL database
ADDITIONAL_DATABASES = {
    'nfl_stats': {
        'sqlalchemy_uri': f"postgresql+psycopg2://{os.environ.get('DATABASE_USER')}:{os.environ.get('DATABASE_PASSWORD')}@{os.environ.get('DATABASE_HOST')}:{os.environ.get('DATABASE_PORT')}/{os.environ.get('DATABASE_DB')}",
        'description': 'NFL Statistics Database'
    }
}

# Redis caching
REDIS_HOST = os.environ.get('REDIS_HOST', 'redis')
REDIS_PORT = os.environ.get('REDIS_PORT', '6379')

# Cache configuration
CACHE_CONFIG = {
    'CACHE_TYPE': 'redis',
    'CACHE_DEFAULT_TIMEOUT': 300,
    'CACHE_KEY_PREFIX': 'superset_',
    'CACHE_REDIS_HOST': REDIS_HOST,
    'CACHE_REDIS_PORT': REDIS_PORT,
}

# Security
SECRET_KEY = os.environ.get('SUPERSET_SECRET_KEY', 'thisISaSECRET_1234')

# Authentication - using built-in DB auth
AUTH_TYPE = AUTH_DB

# Web server settings
SUPERSET_WEBSERVER_TIMEOUT = 300
SUPERSET_ENV = os.environ.get('SUPERSET_ENV', 'production')

# Disable example dashboards in production
SUPERSET_LOAD_EXAMPLES = False