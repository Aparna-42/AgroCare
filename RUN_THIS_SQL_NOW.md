# 🚀 JUST RUN THIS SQL - Profile Update Fix

**COPY EVERYTHING BELOW THIS LINE** and paste into Supabase SQL Editor. This fixes profile updates not working.

---

## How to Use:

1. Open: https://app.supabase.com
2. Click your **AgroCare** project
3. Click **SQL Editor** (left sidebar)
4. Click **New query**
5. **COPY** all the SQL below (starting from `-- STEP 1` to `-- DONE!`)
6. **PASTE** into the SQL Editor
7. Click the blue **Run** button
8. Wait for: ✅ `Query executed successfully`
9. Go back to VS Code and press `r` to reload the app
10. Try updating your profile - it should work! ✅

---

```sql
-- ============================================
-- STEP 1: Create users table (if it doesn't exist)
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
-- STEP 2: Enable RLS on users table
-- ============================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- ============================================
-- STEP 3: Drop existing policies (to avoid conflicts)
-- ============================================
DROP POLICY IF EXISTS "Users can view their own data" ON users;
DROP POLICY IF EXISTS "Users can update their own data" ON users;
DROP POLICY IF EXISTS "Users can insert their own data" ON users;
DROP POLICY IF EXISTS "Users can delete their own data" ON users;

-- ============================================
-- STEP 4: Create new RLS policies
-- ============================================

-- Allow users to INSERT their own record during signup
CREATE POLICY "Users can insert their own data"
  ON users FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- Allow users to VIEW their own data
CREATE POLICY "Users can view their own data"
  ON users FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Allow users to UPDATE their own profile (THIS IS THE KEY FIX!)
CREATE POLICY "Users can update their own data"
  ON users FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Allow users to DELETE their own data
CREATE POLICY "Users can delete their own data"
  ON users FOR DELETE
  TO authenticated
  USING (auth.uid() = id);

-- ============================================
-- DONE!
-- ============================================
-- Your users table is now properly configured!
-- You can now:
-- ✅ Update your profile (name, location)
-- ✅ Change your password
-- ✅ View your user data
-- 
-- Go back to VS Code and press 'r' to reload the app
-- Then try editing your profile - it should work!
```

---

## What This SQL Does:

| Step | Action | Why |
|------|--------|-----|
| 1 | Creates `users` table | Stores user profile data |
| 2 | Enables RLS | Security - prevents unauthorized access |
| 3 | Drops old policies | Removes conflicting rules |
| 4 | Creates 4 new policies | Allows authenticated users to modify their own data |

---

## After Running SQL:

1. ✅ Your app can now UPDATE user profiles
2. ✅ Profile changes will save to database
3. ✅ Data persists after app refresh
4. ✅ Security is maintained (users can only modify their own data)

---

## Troubleshooting

### ❌ Error: "relation 'users' does not exist"
- Your users table doesn't exist
- Make sure you're pasting the ENTIRE SQL including "STEP 1"
- Run the SQL again

### ❌ Error: "duplicate key value violates unique constraint"
- You already have users with this email
- That's fine! Just means the table already exists
- Profiles will still update correctly

### ❌ Error: "role is not a member of role"
- Permissions issue with Supabase
- Try running the SQL again in a new query
- If it persists, check your Supabase project settings

### ✅ Success: "Query executed successfully"
- Perfect! The SQL ran correctly
- Go back to VS Code and reload the app
- Try updating your profile

---

## Verify It Worked:

After running the SQL:

1. Press `r` in Flutter terminal to reload
2. In your app, go to Profile → Edit Profile
3. Change your name to something different
4. Click "Save"
5. Should see: ✅ "Profile updated successfully!"
6. Open Supabase dashboard
7. Go to Tables → users → Find your row
8. Check the `name` column - it should show your new name! ✅

---

**That's it! Happy farming with AgroCare! 🌾🚀**
