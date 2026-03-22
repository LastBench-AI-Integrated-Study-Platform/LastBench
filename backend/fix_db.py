import pymongo

try:
    client = pymongo.MongoClient('mongodb+srv://induja0220_db_user:LastBench@lastbench.fntba2l.mongodb.net/?appName=LastBench')
    db = client['lastbench']
    res = db['doubts'].update_many({'author': 'You'}, {'$set': {'author': 'test'}})
    print(f'Modified {res.modified_count} doubts.')
except Exception as e:
    print(f'Error: {e}')
