# backend/models/call_model.py
from datetime import datetime
from bson import ObjectId


def create_call_log(db, caller_id: str, receiver_id: str, channel: str, call_type: str = 'video') -> str:
    doc = {
        'caller_id':   caller_id,
        'receiver_id': receiver_id,
        'channel':     channel,
        'call_type':   call_type,
        'status':      'ringing',
        'started_at':  datetime.utcnow(),
        'ended_at':    None,
    }
    result = db['call_logs'].insert_one(doc)
    return str(result.inserted_id)


def update_call_status(db, log_id: str, status: str, ended: bool = False):
    update = {'$set': {'status': status}}
    if ended:
        update['$set']['ended_at'] = datetime.utcnow()
    try:
        db['call_logs'].update_one({'_id': ObjectId(log_id)}, update)
    except Exception:
        pass


def get_call_history(db, user_id: str, limit: int = 20):
    logs = db['call_logs'].find(
        {'$or': [{'caller_id': user_id}, {'receiver_id': user_id}]}
    ).sort('started_at', -1).limit(limit)
    result = []
    for log in logs:
        log['_id'] = str(log['_id'])
        result.append(log)
    return result