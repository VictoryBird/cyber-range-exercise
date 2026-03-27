"""
LDAP 인증 백엔드 (Mock).
실제 AD 서버(192.168.100.50)가 없는 환경에서는 Django 기본 인증으로 폴백한다.
AD가 구성된 환경에서는 django-auth-ldap의 LDAPBackend을 사용한다.
"""
import logging
from django.contrib.auth.backends import ModelBackend

logger = logging.getLogger('accounts')


class MockLDAPBackend(ModelBackend):
    """
    Mock LDAP 인증 백엔드.
    실제 LDAP 서버를 사용할 수 없는 경우 Django DB 인증으로 대체한다.
    실제 배포 시 django_auth_ldap.backend.LDAPBackend으로 교체한다.
    """

    def authenticate(self, request, username=None, password=None, **kwargs):
        """
        LDAP 인증 시도. LDAP 서버 연결 실패 시 None을 반환하여
        다음 백엔드(ModelBackend)로 폴백한다.
        """
        try:
            # 실제 LDAP 인증 로직 (python-ldap 필요)
            # import ldap
            # from django.conf import settings
            # conn = ldap.initialize(settings.AUTH_LDAP_SERVER_URI)
            # bind_dn = f"uid={username},{settings.AUTH_LDAP_USER_SEARCH_BASE}"
            # conn.simple_bind_s(bind_dn, password)
            # ... LDAP 속성 동기화 ...

            # Mock: LDAP 서버가 없으므로 None 반환하여 ModelBackend으로 폴백
            logger.debug(f"LDAP 인증 시도: {username} (Mock - LDAP 서버 없음, 폴백)")
            return None
        except Exception as e:
            logger.warning(f"LDAP 인증 실패: {username} - {e}")
            return None
