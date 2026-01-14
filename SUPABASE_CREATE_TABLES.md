# ⚠️ CRITICAL: Create Supabase Database Tables

You MUST run these SQL queries in Supabase for the app to work! Without these tables, user data and plants cannot be saved.

## Steps to Create Tables:

1. Go to: https://app.supabase.com
2. Select your **AgroCare** project
3. Click **SQL Editor** in the left sidebar
4. Click **New query**
5. Copy and paste ALL the SQL below
6. Click **Run**

---

## Complete SQL for All Tables

```sql
-- ============================================
-- CREATE USERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT auth.uid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  location VARCHAR(255),
  profile_image_url TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- CREATE PLANTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS plants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(100) NOT NULL,
  image_url TEXT,
  planted_date DATE NOT NULL,
  health_status VARCHAR(50) DEFAULT 'healthy',
  symptoms TEXT,
  disease VARCHAR(255),
  location VARCHAR(255),
  days_grown INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- CREATE MAINTENANCE_TASKS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS maintenance_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  plant_id UUID NOT NULL REFERENCES plants(id) ON DELETE CASCADE,
  task_type VARCHAR(50) NOT NULL,
  description TEXT,
  scheduled_date DATE NOT NULL,
  is_completed BOOLEAN DEFAULT FALSE,
  completed_date DATE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- CREATE WEATHER_DATA TABLE (Optional)
-- ============================================
CREATE TABLE IF NOT EXISTS weather_data (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  location VARCHAR(255) NOT NULL,
  temperature FLOAT,
  humidity FLOAT,
  rainfall FLOAT,
  weather_condition VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- ENABLE ROW LEVEL SECURITY
-- ============================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE plants ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE weather_data ENABLE ROW LEVEL SECURITY;

-- ============================================
-- ROW LEVEL SECURITY POLICIES FOR USERS
-- ============================================

-- Users can view their own profile
CREATE POLICY "Users can view their own data"
  ON users FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update their own data"
  ON users FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

-- ============================================
-- ROW LEVEL SECURITY POLICIES FOR PLANTS
-- ============================================

-- Users can view only their own plants
CREATE POLICY "Users can view their own plants"
  ON plants FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Users can insert their own plants
CREATE POLICY "Users can insert their own plants"
  ON plants FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own plants
CREATE POLICY "Users can update their own plants"
  ON plants FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own plants
CREATE POLICY "Users can delete their own plants"
  ON plants FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- ============================================
-- ROW LEVEL SECURITY POLICIES FOR MAINTENANCE_TASKS
-- ============================================

-- Users can view only their own tasks
CREATE POLICY "Users can view their own tasks"
  ON maintenance_tasks FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Users can insert their own tasks
CREATE POLICY "Users can insert their own tasks"
  ON maintenance_tasks FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own tasks
CREATE POLICY "Users can update their own tasks"
  ON maintenance_tasks FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own tasks
CREATE POLICY "Users can delete their own tasks"
  ON maintenance_tasks FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- ============================================
-- ROW LEVEL SECURITY POLICIES FOR WEATHER_DATA
-- ============================================

-- Users can view only their own weather data
CREATE POLICY "Users can view their own weather data"
  ON weather_data FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Users can insert their own weather data
CREATE POLICY "Users can insert their own weather data"
  ON weather_data FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- ============================================
-- CREATE INDEXES FOR BETTER PERFORMANCE
-- ============================================
CREATE INDEX idx_plants_user_id ON plants(user_id);
CREATE INDEX idx_maintenance_tasks_user_id ON maintenance_tasks(user_id);
CREATE INDEX idx_maintenance_tasks_plant_id ON maintenance_tasks(plant_id);
CREATE INDEX idx_weather_data_user_id ON weather_data(user_id);
```

---

## ✅ What This Does

| Table | Purpose | RLS Enabled |
|-------|---------|-------------|
| **users** | Store user profiles | ✅ Yes |
| **plants** | Store user plants | ✅ Yes |
| **maintenance_tasks** | Store plant care tasks | ✅ Yes |
| **weather_data** | Store weather information | ✅ Yes |

---

## 🔐 Security Features

- ✅ **Row Level Security (RLS)**: Users can ONLY see and modify their own data
- ✅ **Automatic User ID Linking**: All data is automatically tied to the logged-in user
- ✅ **Cascading Deletes**: Deleting a user also deletes their plants and tasks
- ✅ **Foreign Key Constraints**: Data integrity is maintained

---

## 📋 Verification Checklist

After running the SQL:

- [ ] Go to **Tables** section in Supabase
- [ ] Verify you see: `users`, `plants`, `maintenance_tasks`, `weather_data`
- [ ] Each table shows the correct columns
- [ ] RLS is enabled (lock icon visible)
- [ ] All 4 tables have RLS policies

---

## 🚀 Next Steps

1. **Run the SQL above** in Supabase SQL Editor
2. **Hot reload the app**: Press `r` in the terminal
3. **Test signup**: Create a new account
4. **Check Supabase**: User data should appear in the `users` table
5. **Add a plant**: Plant should appear in the `plants` table

---

## Troubleshooting

### Error: "Table already exists"
- The table already exists - this is fine, the SQL uses `IF NOT EXISTS`

### Error: "Could not find the table"
- Make sure you ran the SQL successfully
- Check that you're in the correct project
- Wait 5 seconds and reload the app

### Data not appearing in tables
- Make sure RLS policies are enabled
- Check that `auth.uid()` matches the logged-in user ID
- Verify no RLS policy is blocking the insert

---

## Time Required

⏱️ **~2 minutes** to run all SQL queries

**Status**: 🔴 **CRITICAL - Must be done to use the app**

