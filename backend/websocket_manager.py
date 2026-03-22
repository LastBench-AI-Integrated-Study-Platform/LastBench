import json
from typing import Dict, List, Any
from fastapi import WebSocket

class ConnectionManager:
    def __init__(self):
        # Maps user emails to a list of active WebSockets (allows multiple devices per user)
        self.active_connections: Dict[str, List[WebSocket]] = {}

    async def connect(self, email: str, websocket: WebSocket):
        await websocket.accept()
        if email not in self.active_connections:
            self.active_connections[email] = []
        self.active_connections[email].append(websocket)

    def disconnect(self, email: str, websocket: WebSocket):
        if email in self.active_connections:
            try:
                self.active_connections[email].remove(websocket)
                if not self.active_connections[email]:
                    del self.active_connections[email]
            except ValueError:
                pass

    async def send_personal_message(self, message: str, email: str):
        """Send a direct JSON message to a specific user"""
        if email in self.active_connections:
            for connection in self.active_connections[email]:
                try:
                    await connection.send_text(message)
                except Exception:
                    # Connection might be closed unexpectedly
                    pass

    async def notify_users(self, emails: List[str], event_type: str, data: Any):
        """Broadcast a structured event to a list of users"""
        payload = json.dumps({
            "type": event_type,
            "data": data
        })
        for email in emails:
            await self.send_personal_message(payload, email)

manager = ConnectionManager()
