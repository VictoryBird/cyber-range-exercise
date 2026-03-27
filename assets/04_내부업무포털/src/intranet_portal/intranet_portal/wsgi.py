"""
WSGI config for intranet_portal project.
"""

import os

from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'intranet_portal.settings')

application = get_wsgi_application()
