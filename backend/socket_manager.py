import socketio

# Create Socket.IO server
import socketio

sio = socketio.AsyncServer(
    async_mode="asgi",
    cors_allowed_origins=[],
    allow_upgrades=True,
    logger=True,
    engineio_logger=True,
)

# Store online users
connected_users = {}
online_users = {}

# ───────── SOCKET EVENTS ─────────
@sio.event
async def connect(sid, environ, auth):
    print("User connected:", sid)
    
    user_id = auth.get("user_id") if auth else None
    
    if user_id:
        online_users[user_id] = sid
        print(f"User {user_id} is now online")

@sio.event
async def disconnect(sid):
    print("Disconnected:", sid)

    for user_id, stored_sid in list(online_users.items()):
        if stored_sid == sid:
            del online_users[user_id]
            print(f"User {user_id} removed from online list")

@sio.on("user_register")
async def user_register(sid, user_id):
    connected_users[user_id] = sid
    print(f"User registered: {user_id}")

@sio.on("call_invite")
async def call_invite(sid, data):
    receiver_id = data["receiverId"]

    if receiver_id in connected_users:
        receiver_sid = connected_users[receiver_id]
        await sio.emit("call_incoming", data, to=receiver_sid)
        print("Call invite sent")
    else:
        print("Receiver not online")

@sio.on("call_accept")
async def call_accept(sid, data):
    caller_id = data["callerId"]

    if caller_id in connected_users:
        caller_sid = connected_users[caller_id]
        await sio.emit("call_accepted", data, to=caller_sid)

@sio.on("call_reject")
async def call_reject(sid, data):
    caller_id = data["callerId"]

    if caller_id in connected_users:
        caller_sid = connected_users[caller_id]
        await sio.emit("call_rejected", data, to=caller_sid)

@sio.on("call_end")
async def call_end(sid, data):
    other_user_id = data["otherUserId"]

    if other_user_id in connected_users:
        other_sid = connected_users[other_user_id]
        await sio.emit("call_ended", {}, to=other_sid)