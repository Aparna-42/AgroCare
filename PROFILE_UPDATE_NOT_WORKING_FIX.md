# 🔧 Fix: Profile Update Not Working - Complete Guide

Your profile updates are not saving because the `users` table in Supabase either **doesn't exist** or has **RLS policies blocking updates**.

## ⚠️ STEP 1: Verify Users Table Exists (CRITICAL)

Follow these steps:

1. Open: https://app.supabase.com
2. Select your **AgroCare** project
3. In the left sidebar, click **"SQL Editor"**
4. Click the blue **"New query"** button
5. Copy and paste this query:

```sql
SELECT * FROM users LIMIT 1;
```

6. Click **Run**

### ✅ If you see a table with columns (id, email, name, location, etc.)
→ Go to **STEP 2** below

### ❌ If you get an error like "relation 'users' does not exist"
→ You need to create the tables. **FOLLOW THESE STEPS:**

1. In the SQL Editor, click **New query**
2. Go to this file in your project: `SUPABASE_CREATE_TABLES.md`
3. Copy ALL the SQL code from that file
4. Paste it into the SQL Editor
5. Click **Run**
6. Wait for it to complete successfully
7. Then go to **STEP 2**

---

## ⚠️ STEP 2: Fix RLS Policies (CRITICAL)

The `users` table needs proper RLS policies for UPDATE operations.

1. In Supabase SQL Editor, click **New query**
2. Copy and paste ALL of this SQL:

```sql
-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own data" ON users;
DROP POLICY IF EXISTS "Users can update their own data" ON users;
DROP POLICY IF EXISTS "Users can insert their own data" ON users;
DROP POLICY IF EXISTS "Users can delete their own data" ON users;

-- Create new policies
CREATE POLICY "Users can insert their own data"
  ON users FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can view their own data"
  ON users FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own data"
  ON users FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can delete their own data"
  ON users FOR DELETE
  TO authenticated
  USING (auth.uid() = id);
```

3. Click **Run**
4. You should see: `Query executed successfully` ✅

---

## ⚠️ STEP 3: Enable RLS on Users Table (IMPORTANT)

1. In Supabase, go to **Authentication** → **Policies** in the left sidebar
2. Select the **users** table
3. Make sure **"RLS is ON"** (toggle should be blue/enabled)
4. You should see the 4 policies we just created listed

---

## ⚠️ STEP 4: Test Profile Update

Now test if profile updates work:

1. Go back to your Flutter app in VS Code
2. Press `r` to hot reload (or restart the app)
3. Log in with your account
4. Click **"Edit Profile"**
5. Change your name and/or location
6. Click **"Save"**
7. You should see: ✅ **Profile updated successfully**

### ✅ If it works:
- Open Supabase dashboard
- Go to **Tables** → **users**
- Click on your user row
- You should see your updated name and location! 🎉

### ❌ If it still doesn't work:
Check your browser console for error messages:
1. Open Browser DevTools: **F12**
2. Click the **Console** tab
3. Try updating profile again
4. Look for any red error messages
5. Share the error message with me

---

## 📋 Checklist

Complete this checklist in order:

- [ ] Step 1: Verified users table exists in Supabase
- [ ] Step 2: Ran RLS policy SQL in SQL Editor
- [ ] Step 3: Confirmed RLS is enabled on users table
- [ ] Step 4: Tested profile update in app
- [ ] ✅ Profile update now works!

---

## 🆘 Troubleshooting

### Problem: "relation 'users' does not exist"
**Solution:** Run the CREATE TABLE SQL from `SUPABASE_CREATE_TABLES.md`

### Problem: "new row violates row-level security policy"
**Solution:** The RLS policies didn't apply correctly. Re-run Step 2 (the DROP and CREATE POLICY statements)

### Problem: Update shows success but data doesn't save
**Solution:** RLS policies might be blocking. Check that you ran Step 2 correctly with `USING (auth.uid() = id)` and `WITH CHECK (auth.uid() = id)`

### Problem: Can't find SQL Editor in Supabase
**Solution:** 
1. Go to https://app.supabase.com
2. Click your project
3. In left sidebar under "DEVELOPMENT" you'll see "SQL Editor"

---

## 💡 How Profile Updates Work

1. **Frontend (Flutter)**: User enters new name/location in dialog → calls `authProvider.updateProfile()`
2. **Backend (Supabase)**: `updateProfile()` runs this query:
   ```sql
   UPDATE users SET name = '...', location = '...', updated_at = NOW()
   WHERE id = 'user-id'
   ```
3. **RLS Policy**: Supabase checks if the authenticated user has permission to UPDATE this row
   - Policy: `auth.uid() = id` means "only if the user's ID matches the row ID"
   - If it matches ✅ update is allowed
   - If it doesn't match ❌ update is blocked with error

**That's why Step 2 is critical!** Without the RLS UPDATE policy, Supabase blocks all updates.

---

## 📞 If You're Still Stuck

1. Verify ALL of Step 1-4 is complete
2. Check browser console (F12 → Console) for actual errors
3. Share the error message or what you see in Supabase Dashboard
