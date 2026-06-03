import csv
import json
import random
from datetime import datetime, timedelta
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
from firebase_admin import auth

# Initialize Firebase Admin
cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

def upload_to_firebase():
    print("Reading users_dataset.csv...")
    users = []
    with open('users_dataset.csv', 'r', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        for row in reader:
            users.append(row)
            
    print("Reading activities_dataset.csv...")
    activities = []
    with open('activities_dataset.csv', 'r', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        for row in reader:
            activities.append(row)
            
    print(f"Loaded {len(users)} users and {len(activities)} activities.")
    
    # Upload users
    print("Uploading users to Firebase Auth and Firestore...")
    uid_map = {} # Maps CSV user ID to Firebase UID
    
    batch = db.batch()
    batch_count = 0
    total_users_uploaded = 0
    
    for u in users:
        # Create Auth user
        try:
            try:
                auth_user = auth.get_user_by_email(u['email'])
            except auth.UserNotFoundError:
                auth_user = auth.create_user(
                    email=u['email'],
                    password=u['password'],
                    display_name=u['username']
                )
            
            uid = auth_user.uid
            uid_map[u['id']] = uid
            
            # Add to Firestore batch
            user_ref = db.collection('users').document(uid)
            batch.set(user_ref, {
                'username': u['username'],
                'email': u['email'],
                'password': u['password'],
                'role': u['role'],
                'points': int(u['points']),
                'rank': u['rank'],
                'gender': u.get('gender'),
                'age': int(u['age']) if u.get('age') else None,
                'heightCm': float(u['height_cm']) if u.get('height_cm') else None,
                'weightKg': float(u['weight_kg']) if u.get('weight_kg') else None,
                'country': u.get('country'),
                'occupation': u.get('occupation'),
                'createdAt': u['createdAt']
            })
            
            batch_count += 1
            if batch_count >= 500:
                batch.commit()
                batch = db.batch()
                batch_count = 0
                print(f"  Committed batch of users... (total {total_users_uploaded + 500})")
            
            total_users_uploaded += 1
        except Exception as e:
            print(f"Error creating user {u['email']}: {e}".encode('ascii', 'ignore').decode('ascii'))
            
    if batch_count > 0:
        try:
            batch.commit()
            print(f"  Committed final batch of users... (total {total_users_uploaded + batch_count})")
        except Exception as e:
            print(f"Error committing final user batch: {e}".encode('ascii', 'ignore').decode('ascii'))
        batch = db.batch()
        batch_count = 0
        print("Finished users upload.")
        
    print("Uploading activities...")
    total_acts = 0
    for act in activities:
        csv_user_id = act['userId']
        if csv_user_id not in uid_map:
            continue
            
        uid = uid_map[csv_user_id]
        
        act_ref = db.collection('activities').document()
        batch.set(act_ref, {
            'userId': uid,
            'title': act['title'],
            'description': act.get('description', ''),
            'date': act['date'],
            'startTime': act['startTime'],
            'endTime': act.get('endTime', ''),
            'category': act['category'],
            'hasReminder': False,
            'isDone': True if act['isDone'] == '1' else False,
            'createdAt': datetime.now().isoformat()
        })
        
        batch_count += 1
        if batch_count >= 500:
            batch.commit()
            batch = db.batch()
            batch_count = 0
            total_acts += 500
            print(f"  Committed batch of activities... ({total_acts}/{len(activities)})")
            
    if batch_count > 0:
        try:
            batch.commit()
        except Exception as e:
            print(f"Error committing final activities batch: {e}".encode('ascii', 'ignore').decode('ascii'))
        print("Finished activities upload.")
        
    print("Done! Everything is in Firebase now.")

if __name__ == "__main__":
    upload_to_firebase()
