"""
DailyTracker - Dataset Generator
Generates 200 realistic Vietnamese users with full profile + daily activities
Output: users_dataset.csv, activities_dataset.csv
"""

import csv
import random
import hashlib
from datetime import datetime, timedelta

# ─── Data pools ─────────────────────────────────────────────────────────────

FIRST_NAMES_MALE = [
    "Anh", "Bảo", "Cường", "Dũng", "Đức", "Giang", "Hải", "Hiếu", "Hùng",
    "Khải", "Khoa", "Kiên", "Lâm", "Liêm", "Long", "Minh", "Nam", "Nghĩa",
    "Nhân", "Phong", "Phúc", "Quân", "Quang", "Sơn", "Thắng", "Thiện",
    "Trung", "Tuấn", "Tùng", "Việt", "Vũ", "Xuân"
]

FIRST_NAMES_FEMALE = [
    "Anh", "Chi", "Dung", "Giang", "Hà", "Hằng", "Hiền", "Hoa", "Hương",
    "Lan", "Linh", "Loan", "Mai", "My", "Ngân", "Nga", "Nhung", "Phương",
    "Quỳnh", "Tâm", "Thảo", "Thu", "Thủy", "Trang", "Trinh", "Tuyết",
    "Uyên", "Vân", "Xuân", "Yến"
]

LAST_NAMES = [
    "Nguyễn", "Trần", "Lê", "Phạm", "Hoàng", "Huỳnh", "Phan", "Vũ",
    "Võ", "Đặng", "Bùi", "Đỗ", "Hồ", "Ngô", "Dương", "Lý"
]

MIDDLE_NAMES_MALE = ["Văn", "Hữu", "Quốc", "Minh", "Đức", "Thanh", "Hoàng", "Công"]
MIDDLE_NAMES_FEMALE = ["Thị", "Ngọc", "Thu", "Kim", "Mỹ", "Bích", "Thanh", "Phương"]

COUNTRIES = [
    "Việt Nam", "Việt Nam", "Việt Nam", "Việt Nam", "Việt Nam",  # majority VN
    "Mỹ", "Nhật Bản", "Hàn Quốc", "Trung Quốc", "Đức",
    "Pháp", "Úc", "Singapore", "Thái Lan", "Canada"
]

OCCUPATIONS = [
    "Sinh viên", "Lập trình viên", "Kỹ sư phần mềm", "Giáo viên",
    "Bác sĩ", "Y tá", "Kế toán", "Marketing", "Thiết kế đồ họa",
    "Nhân viên văn phòng", "Doanh nhân", "Freelancer", "Kiến trúc sư",
    "Luật sư", "Nhà báo", "Quản lý dự án"
]

RANKS_BY_POINTS = [
    (0,   499,   "iron"),
    (500, 1499,  "bronze"),
    (1500, 3999, "gold"),
    (4000, 7999, "platinum"),
    (8000, 14999,"diamond"),
    (15000, 30000,"master"),
]

ACTIVITY_TEMPLATES = {
    "morning": [
        ("☀️ Thức dậy & kéo giãn cơ", "Khởi động nhẹ 10 phút", "sport", "06:00", "06:15"),
        ("🧘 Thiền buổi sáng", "Thiền định 10-15 phút", "rest", "06:15", "06:30"),
        ("🏃 Chạy bộ buổi sáng", "Chạy bộ 30 phút trong công viên", "sport", "06:00", "06:30"),
        ("🥛 Uống nước sáng", "Uống 1 ly nước ấm sau khi ngủ dậy", "food", "06:30", "06:35"),
        ("🥚 Ăn sáng", "Trứng luộc, bánh mì, sữa tươi", "food", "07:00", "07:30"),
        ("☕ Cà phê sáng", "Cà phê đen không đường", "food", "07:30", "07:45"),
        ("📰 Đọc tin tức", "Xem tin tức buổi sáng 15 phút", "rest", "07:00", "07:15"),
        ("🚿 Tắm và chuẩn bị", "Vệ sinh cá nhân buổi sáng", "rest", "07:00", "07:30"),
        ("💊 Uống vitamin", "Uống vitamin C và D3", "food", "07:30", "07:35"),
        ("🏋️ Tập gym buổi sáng", "Bài tập ngực và tay", "sport", "06:30", "07:30"),
    ],
    "work": [
        ("💻 Làm việc / Học tập", "Tập trung công việc chính", "work", "08:00", "12:00"),
        ("📝 Review email & kế hoạch", "Kiểm tra email và lên kế hoạch ngày", "work", "08:00", "08:30"),
        ("🤝 Họp team", "Họp tiến độ dự án với nhóm", "work", "09:00", "10:00"),
        ("📊 Báo cáo tuần", "Hoàn thành báo cáo tiến độ", "work", "10:00", "11:00"),
        ("📚 Học kỹ năng mới", "Học khóa học online", "work", "08:30", "10:00"),
        ("🎯 Deep work session", "Làm việc tập trung không gián đoạn", "work", "08:00", "11:00"),
    ],
    "lunch": [
        ("🍜 Ăn trưa", "Cơm gà, rau xanh, canh", "food", "12:00", "12:45"),
        ("🥗 Salad trưa", "Salad rau củ với ức gà", "food", "12:00", "12:30"),
        ("💤 Nghỉ trưa", "Ngủ trưa 20-30 phút", "rest", "12:30", "13:00"),
        ("🚶 Đi bộ sau ăn", "Đi bộ nhẹ 15 phút sau bữa trưa", "sport", "12:45", "13:00"),
        ("🍱 Ăn trưa mang theo", "Cơm hộp nấu từ nhà", "food", "12:00", "12:30"),
    ],
    "afternoon": [
        ("💻 Làm việc buổi chiều", "Tiếp tục công việc sau trưa", "work", "13:00", "17:00"),
        ("📞 Gọi điện khách hàng", "Liên lạc và chăm sóc khách hàng", "work", "14:00", "15:00"),
        ("☕ Cà phê chiều", "Uống cà phê giữa buổi chiều", "food", "15:00", "15:15"),
        ("🏊 Bơi lội chiều", "Bơi 1km tại hồ bơi", "sport", "16:00", "17:00"),
        ("🚴 Đạp xe", "Đạp xe đạp 45 phút", "sport", "16:00", "16:45"),
        ("📖 Đọc sách", "Đọc sách phát triển bản thân", "rest", "15:30", "16:00"),
    ],
    "evening": [
        ("🏋️ Tập gym buổi tối", "Workout 60-90 phút", "sport", "17:30", "19:00"),
        ("🍖 Ăn tối", "Cơm gia đình hoặc nấu ăn", "food", "18:30", "19:30"),
        ("🎮 Giải trí", "Chơi game hoặc xem phim", "rest", "20:00", "21:00"),
        ("📱 Mạng xã hội", "Kiểm tra mạng xã hội 30 phút", "rest", "20:00", "20:30"),
        ("👨‍👩‍👧 Thời gian gia đình", "Dành thời gian cho gia đình", "rest", "19:00", "20:00"),
        ("🎸 Sở thích cá nhân", "Đàn guitar hoặc vẽ tranh", "rest", "20:00", "21:00"),
        ("📚 Học buổi tối", "Ôn bài hoặc học thêm kỹ năng", "work", "19:00", "21:00"),
        ("🧹 Dọn dẹp nhà", "Vệ sinh nhà cửa", "rest", "18:30", "19:00"),
        ("😴 Chuẩn bị ngủ", "Vệ sinh, đọc sách nhẹ trước ngủ", "rest", "21:30", "22:00"),
        ("🌙 Ngủ", "Ngủ đủ 7-8 tiếng", "rest", "22:00", "06:00"),
    ]
}


def get_rank(points: int) -> str:
    for lo, hi, rank in RANKS_BY_POINTS:
        if lo <= points <= hi:
            return rank
    return "master"


def gen_email(name: str, idx: int) -> str:
    cleaned = name.lower().replace(" ", "").replace("ă","a").replace("â","a")\
        .replace("đ","d").replace("ê","e").replace("ô","o").replace("ơ","o")\
        .replace("ư","u").replace("à","a").replace("á","a").replace("ả","a")\
        .replace("ã","a").replace("ạ","a").replace("ề","e").replace("ế","e")\
        .replace("ệ","e").replace("ỉ","i").replace("ị","i").replace("ồ","o")\
        .replace("ố","o").replace("ộ","o").replace("ờ","o").replace("ớ","o")\
        .replace("ợ","o").replace("ừ","u").replace("ứ","u").replace("ự","u")\
        .replace("ỳ","y").replace("ý","y").replace("ị","i").replace("ắ","a")\
        .replace("ặ","a").replace("ầ","a").replace("ấ","a").replace("ậ","a")\
        .replace("ằ","a")
    domains = ["gmail.com", "yahoo.com", "outlook.com", "hotmail.com"]
    return f"{cleaned}{idx}@{random.choice(domains)}"


def gen_bmi_stats(gender: str, age: int):
    if gender == "Nam":
        height = random.randint(162, 182)
        weight_base = 55 + (height - 162) * 0.8
        weight = round(weight_base + random.uniform(-8, 12), 1)
    else:
        height = random.randint(152, 170)
        weight_base = 45 + (height - 152) * 0.7
        weight = round(weight_base + random.uniform(-6, 10), 1)
    return height, weight


def gen_activities_for_user(user_id: int, date_str: str, gender: str,
                             occupation: str, points: int) -> list:
    acts = []
    is_active = points > 1000  # more active users have more activities

    # Morning slot
    morning_pool = ACTIVITY_TEMPLATES["morning"]
    n_morning = random.randint(2, 4) if is_active else random.randint(1, 2)
    for item in random.sample(morning_pool, min(n_morning, len(morning_pool))):
        acts.append({
            "userId": user_id,
            "title": item[0],
            "description": item[1],
            "category": item[2],
            "startTime": item[3],
            "endTime": item[4],
            "date": date_str,
            "isDone": random.choice([0, 1]),
        })

    # Work slot
    work_pool = ACTIVITY_TEMPLATES["work"]
    acts.append({
        "userId": user_id,
        **dict(zip(["title","description","category","startTime","endTime"],
                   random.choice(work_pool))),
        "date": date_str,
        "isDone": 1,
    })

    # Lunch
    lunch_pool = ACTIVITY_TEMPLATES["lunch"]
    for item in random.sample(lunch_pool, random.randint(1, 2)):
        acts.append({
            "userId": user_id,
            "title": item[0], "description": item[1],
            "category": item[2], "startTime": item[3], "endTime": item[4],
            "date": date_str,
            "isDone": random.choice([0, 1]),
        })

    # Afternoon
    aft_pool = ACTIVITY_TEMPLATES["afternoon"]
    for item in random.sample(aft_pool, random.randint(1, 2)):
        acts.append({
            "userId": user_id,
            "title": item[0], "description": item[1],
            "category": item[2], "startTime": item[3], "endTime": item[4],
            "date": date_str,
            "isDone": random.choice([0, 1]),
        })

    # Evening
    eve_pool = ACTIVITY_TEMPLATES["evening"]
    for item in random.sample(eve_pool, random.randint(2, 4)):
        acts.append({
            "userId": user_id,
            "title": item[0], "description": item[1],
            "category": item[2], "startTime": item[3], "endTime": item[4],
            "date": date_str,
            "isDone": random.choice([0, 1]),
        })

    return acts


def generate_dataset(n_users: int = 200):
    users = []
    all_activities = []

    today = datetime.now()

    for i in range(1, n_users + 1):
        gender = random.choice(["Nam", "Nữ"])
        first_name_pool = FIRST_NAMES_MALE if gender == "Nam" else FIRST_NAMES_FEMALE
        middle_pool = MIDDLE_NAMES_MALE if gender == "Nam" else MIDDLE_NAMES_FEMALE

        last = random.choice(LAST_NAMES)
        middle = random.choice(middle_pool)
        first = random.choice(first_name_pool)
        username = f"{last} {middle} {first}"

        age = random.randint(18, 45)
        height, weight = gen_bmi_stats(gender, age)
        bmi = round(weight / ((height / 100) ** 2), 1)

        points = random.choices(
            population=[
                random.randint(0, 499),
                random.randint(500, 1499),
                random.randint(1500, 3999),
                random.randint(4000, 7999),
                random.randint(8000, 14999),
                random.randint(15000, 30000),
            ],
            weights=[20, 30, 25, 12, 8, 5],
            k=1
        )[0]

        rank = get_rank(points)
        country = random.choice(COUNTRIES)
        occupation = random.choice(OCCUPATIONS)
        email = gen_email(f"{last}{first}", i)
        created_ago = today - timedelta(days=random.randint(1, 365))

        user = {
            "id": i,
            "username": username,
            "email": email,
            "password": "user123",
            "role": "user",
            "points": points,
            "rank": rank,
            "gender": gender,
            "age": age,
            "height_cm": height,
            "weight_kg": weight,
            "bmi": bmi,
            "country": country,
            "occupation": occupation,
            "createdAt": created_ago.strftime("%Y-%m-%dT%H:%M:%S"),
        }
        users.append(user)

        # Generate activities for the last 7 days
        for day_offset in range(7):
            date = today - timedelta(days=day_offset)
            date_str = date.strftime("%Y-%m-%d")
            day_acts = gen_activities_for_user(i, date_str, gender, occupation, points)
            all_activities.extend(day_acts)

    # ── Write users CSV ──────────────────────────────────────────
    users_file = "users_dataset.csv"
    with open(users_file, "w", newline="", encoding="utf-8-sig") as f:
        fieldnames = [
            "id", "username", "email", "password", "role", "points", "rank",
            "gender", "age", "height_cm", "weight_kg", "bmi",
            "country", "occupation", "createdAt"
        ]
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        w.writerows(users)

    print("[OK] Generated %d users -> %s" % (len(users), users_file))

    # -- Write activities CSV
    acts_file = "activities_dataset.csv"
    with open(acts_file, "w", newline="", encoding="utf-8-sig") as f:
        fieldnames = [
            "userId", "title", "description", "category",
            "startTime", "endTime", "date", "isDone"
        ]
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        for act in all_activities:
            w.writerow({k: act[k] for k in fieldnames if k in act})

    print("[OK] Generated %d activities -> %s" % (len(all_activities), acts_file))
    print("\n[Stats]")
    print("   Users          : %d" % n_users)
    print("   Activities     : %d" % len(all_activities))
    print("   Avg acts/user  : %d" % (len(all_activities) // n_users))

    import sqlite3
    db_file = "dailytracker_v5.db"
    conn = sqlite3.connect(db_file)
    c = conn.cursor()
    c.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'user',
        points INTEGER NOT NULL DEFAULT 0,
        rank TEXT NOT NULL DEFAULT 'iron',
        avatarUrl TEXT,
        createdAt TEXT NOT NULL,
        gender TEXT,
        age INTEGER,
        heightCm REAL,
        weightKg REAL,
        country TEXT,
        occupation TEXT
      )
    ''')
    c.execute('''
      CREATE TABLE IF NOT EXISTS activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT,
        category TEXT NOT NULL,
        color TEXT,
        hasReminder INTEGER NOT NULL DEFAULT 0,
        reminderTime TEXT,
        isDone INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(id)
      )
    ''')

    # Seed users
    for user in users:
        c.execute('''
          INSERT OR REPLACE INTO users (id, username, email, password, role, points, rank, gender, age, heightCm, weightKg, country, occupation, createdAt)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            user["id"], user["username"], user["email"], user["password"], user["role"],
            user["points"], user["rank"], user.get("gender"), user.get("age"),
            user.get("height_cm"), user.get("weight_kg"), user.get("country"),
            user.get("occupation"), user["createdAt"]
        ))
    
    # Seed activities
    for act in all_activities:
        c.execute('''
          INSERT INTO activities (userId, title, description, date, startTime, endTime, category, isDone, createdAt)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            act["userId"], act["title"], act["description"], act["date"],
            act["startTime"], act["endTime"], act["category"], act["isDone"],
            datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
        ))

    conn.commit()
    conn.close()
    print(f"[OK] Generated SQLite database -> {db_file}")

    from collections import Counter
    rank_dist = Counter(u["rank"] for u in users)
    print("\n[Rank distribution]")
    for rank in ["iron","bronze","gold","platinum","diamond","master"]:
        print("   %-12s: %d" % (rank, rank_dist.get(rank, 0)))

    return users_file, acts_file


if __name__ == "__main__":
    generate_dataset(1000)
