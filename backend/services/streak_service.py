from datetime import datetime, timedelta
from db.connection import db

def get_user_streak_data(email: str, trigger_update: bool = False):
    """
    Fetch streak data for a user. 
    If trigger_update is True, it will increment/start the streak if it's a new day.
    """
    user = db.users.find_one({"email": email})
    if not user:
        return None
        
    today_str = datetime.now().strftime("%Y-%m-%d")
    yesterday_str = (datetime.now() - timedelta(days=1)).strftime("%Y-%m-%d")
    
    last_study_date = user.get("last_study_date")
    current_streak = user.get("current_streak", 0)
    study_dates = user.get("study_dates", [])
    
    # Check for streak break (missed yesterday and haven't studied today yet)
    if last_study_date and last_study_date != today_str and last_study_date != yesterday_str:
        # Missed more than 1 day, reset current_streak to 0 in memory (actual reset to 1 happens on update)
        current_streak = 0
        db.users.update_one(
            {"email": email},
            {"$set": {"current_streak": 0}}
        )

    if trigger_update:
        if last_study_date == today_str:
            # Already logged today, no change to streak count
            pass
        elif last_study_date == yesterday_str:
            # Logged yesterday, increment streak
            current_streak += 1
            last_study_date = today_str
            if today_str not in study_dates:
                study_dates.append(today_str)
        else:
            # First login ever OR streak was broken (already reset to 0 above)
            current_streak = 1
            last_study_date = today_str
            if today_str not in study_dates:
                study_dates.append(today_str)
        
        # Save updates
        db.users.update_one(
            {"email": email},
            {"$set": {
                "current_streak": current_streak,
                "last_study_date": last_study_date,
                "study_dates": study_dates
            }}
        )
            
    return {
        "current_streak": current_streak,
        "last_study_date": last_study_date,
        "study_dates": study_dates
    }

def update_user_streak(email: str):
    """Explicitly update user streak (e.g., after an action)."""
    return get_user_streak_data(email, trigger_update=True)
