# 🚀 Quick Start: Plant Maintenance Scheduler

## ⚡ 3-Minute Setup

### Step 1: Database Setup (1 minute)
1. Open [Supabase Dashboard](https://app.supabase.com)
2. Go to **SQL Editor**
3. Run this SQL:

```sql
CREATE TABLE IF NOT EXISTS public.user_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    available_days_per_week INTEGER DEFAULT 3 CHECK (available_days_per_week >= 1 AND available_days_per_week <= 7),
    preferred_days TEXT[] DEFAULT ARRAY['Monday', 'Wednesday', 'Friday'],
    preferred_time_of_day TEXT,
    enable_notifications BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE(user_id)
);

ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own settings" ON public.user_settings
    FOR ALL USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_user_settings_user_id ON public.user_settings(user_id);
```

✅ **Done!** Table created with security enabled.

---

### Step 2: Add Plants (30 seconds)
1. Open app → Go to **"My Plants"**
2. Tap **+** button
3. Add at least one plant (use camera or manual entry)

✅ **Done!** You have plants to maintain.

---

### Step 3: Generate Tasks (30 seconds)
1. Open **"Maintenance Schedule"** from bottom nav
2. Tap **⚙️ Settings** → Set days per week (default: 3)
3. Tap **"Generate Tasks"** button (⭐)
4. Wait 5-10 seconds for AI to create schedule

✅ **Done!** Weekly tasks generated automatically.

---

### Step 4: Complete Tasks (Ongoing)
1. View tasks for **Today**
2. Complete a task → Tap **checkbox** ✅
3. See progress bar update
4. Navigate to tomorrow's tasks

✅ **Done!** You're maintaining your plants like a pro!

---

## 📱 App Navigation

```
Bottom Navigation:
├── Home (Dashboard)
├── My Plants (Add/View plants)
├── Maintenance (This feature!)
└── Profile (Settings)

Top Bar (Maintenance Screen):
├── "Maintenance Schedule" (Title)
└── ⚙️ Settings (Configure days/week)
```

---

## 🎯 Daily Workflow

### Morning Routine:
```
1. Open app
2. Go to Maintenance Schedule
3. View "Today" (already selected)
4. See your tasks:
   ✅ Water Tomato Plant
   ✅ Check Rose for Pests
5. Complete each task → Check ✅
6. Close app
```

**Time: 2-5 minutes to review + actual task time**

---

## 🤖 What the AI Does

When you tap "Generate Tasks", the AI:
1. ✅ Analyzes **each plant** (species, health, age)
2. ✅ Checks **current weather** (temp, rain, humidity)
3. ✅ Considers **your location**
4. ✅ Creates **personalized tasks**:
   - 💧 Watering (adjusted for rain)
   - 🌱 Fertilizing (growth stage specific)
   - ✂️ Pruning (seasonal timing)
   - 🐛 Pest control (weather-based risks)
5. ✅ Distributes across **your available days**

**Result:** Smart, weather-aware care schedule that fits your time!

---

## 💡 Pro Tips

### 1. **Set Realistic Days/Week**
- **New to plants?** Start with **2-3 days**
- **Experienced?** Try **4-5 days**
- **Plant enthusiast?** Go for **6-7 days**

### 2. **Regenerate Weekly**
- Weather changes → Care needs change
- Tap "Generate Tasks" every **Sunday evening**
- Fresh schedule for the week ahead

### 3. **Complete Morning Tasks First**
- Best time to water: **6-9 AM**
- Plants absorb water better
- Reduces disease risk

### 4. **Read AI Notes**
- Each task has recommendations
- Shows fertilizer types, watering amounts
- Tap task to see full details

---

## 📊 Understanding the UI

### Day Selector (Top)
```
[Mon] [Tue] [Wed] [Thu] [Fri] [Sat] [Sun]
  17    18    19    20    21    22    23
                    Today
```
- Tap any day to view tasks
- "Today" badge shows current day
- Green = selected day

### Task Card
```
┌─────────────────────────────────┐
│ 🌱 Tomato Plant                │ ← Plant name
│ 2 of 3 tasks completed ■■■□ 67%│ ← Progress
├─────────────────────────────────┤
│ ✅ 💧 WATERING                  │ ← Task 1 (done)
│    Water deeply in morning      │
│                                 │
│ ✅ 🐛 PEST CONTROL              │ ← Task 2 (done)
│    Check for aphids on leaves   │
│                                 │
│ ☐ 🌱 FERTILIZING               │ ← Task 3 (pending)
│    Apply balanced NPK 10-10-10  │
│    Type: Balanced fertilizer    │ ← AI note
└─────────────────────────────────┘
```

---

## ⚠️ Troubleshooting

### "No plants found"
**Solution:** Add plants in "My Plants" first

### Tasks not generating
**Solution:** 
- Check internet connection
- Verify API keys in `API_KEYS_SETUP.md`
- Wait 30 seconds and try again

### Settings won't save
**Solution:**
- Run database SQL (Step 1 above)
- Check Supabase is connected
- Log out and back in

### Weather data missing
**Solution:**
- Go to "Weather Advisory"
- Search your city or use GPS
- Return to generate tasks

---

## 📝 Example: First Time User

**Alex just installed the app:**

1. ✅ Adds 2 plants: Basil and Tomato
2. ✅ Opens Maintenance Schedule
3. ✅ Sees empty state: "No tasks scheduled"
4. ✅ Taps Settings → Selects "3 days/week"
5. ✅ Taps "Generate Tasks"
6. ✅ Waits 10 seconds
7. ✅ Success! Sees this week's schedule:
   - **Monday**: Water Basil, Check Tomato
   - **Wednesday**: Fertilize Tomato
   - **Friday**: Water both plants
8. ✅ Completes Monday tasks → 100% progress
9. ✅ Returns Wednesday for next tasks

**Total setup time: 3 minutes**
**Daily time: 2 minutes to check + task time**

---

## 🎉 You're All Set!

Your maintenance scheduler is ready. The app will:
- ✅ Track all your plants
- ✅ Generate smart care schedules
- ✅ Adapt to weather conditions
- ✅ Remind you what to do each day
- ✅ Help you build consistent care habits

**Questions?** Check [MAINTENANCE_GUIDE.md](MAINTENANCE_GUIDE.md) for detailed docs.

**Happy Gardening! 🌱**

---

## 🔗 Related Files

- **Detailed Guide:** [MAINTENANCE_GUIDE.md](MAINTENANCE_GUIDE.md)
- **Database Setup:** [USER_SETTINGS_TABLE.md](USER_SETTINGS_TABLE.md)
- **Implementation Details:** [MAINTENANCE_IMPLEMENTATION_SUMMARY.md](MAINTENANCE_IMPLEMENTATION_SUMMARY.md)
- **API Configuration:** [API_KEYS_SETUP.md](API_KEYS_SETUP.md)
