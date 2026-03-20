# backend/services/call_service.py
import os
import time


def generate_agora_token(channel_name: str, uid: int, expire_seconds: int = 3600) -> dict:
    app_id   = os.getenv('AGORA_APP_ID', '')
    app_cert = os.getenv('AGORA_APP_CERTIFICATE', '')

    if not app_id or not app_cert:
        raise ValueError('AGORA_APP_ID and AGORA_APP_CERTIFICATE not set in .env')

    privilege_time = int(time.time()) + expire_seconds

    # Try Role_Publisher (older versions of agora-token-builder)
    try:
        from agora_token_builder import RtcTokenBuilder, Role_Publisher
        token = RtcTokenBuilder.buildTokenWithUid(
            app_id, app_cert, channel_name, uid, Role_Publisher, privilege_time
        )
        return {'token': token, 'app_id': app_id, 'channel': channel_name}
    except ImportError:
        pass

    # Try RtcRole.PUBLISHER (newer versions)
    try:
        from agora_token_builder import RtcTokenBuilder, RtcRole
        token = RtcTokenBuilder.buildTokenWithUid(
            app_id, app_cert, channel_name, uid, RtcRole.PUBLISHER, privilege_time
        )
        return {'token': token, 'app_id': app_id, 'channel': channel_name}
    except (ImportError, AttributeError):
        pass

    # Fallback: use raw int 1 (publisher role, works on all versions)
    try:
        from agora_token_builder import RtcTokenBuilder
        token = RtcTokenBuilder.buildTokenWithUid(
            app_id, app_cert, channel_name, uid, 1, privilege_time
        )
        return {'token': token, 'app_id': app_id, 'channel': channel_name}
    except Exception as e:
        raise RuntimeError(
            f'Agora token generation failed: {e}\n'
            'Run:  pip install agora-token-builder'
        )