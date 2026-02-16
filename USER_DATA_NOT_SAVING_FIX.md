# ⚠️ CRITICAL FIX: User Data Not Saving to Database

## The Problem

When users sign up, they get authenticated but their data is NOT being saved to the `users` table because of **Row Level Security (RLS) policies** that are too restrictive.

Error: `new row violates row-level security policy for table "users"`

---

## Solution: Fix RLS Policies

### Step 1: Open Supabase Dashboard

1. Go to: https://app.supabase.com
2. Select your **AgroCare** project
3. Click **SQL Editor** in the left sidebar
4. Click **New query**

### Step 2: Drop Old Policies

Copy and paste this SQL and click **Run**:

```sql
-- Remove old restrictive policies
DROP POLICY IF EXISTS "Users can view their own data" ON users;
DROP POLICY IF EXISTS "Users can update their own data" ON users;
DROP POLICY IF EXISTS "Users can insert their own data" ON users;
```

### Step 3: Create New Policies with INSERT Permission

Copy and paste this SQL and click **Run**:

```sql
-- Allow authenticated users to INSERT their own record
CREATE POLICY "Users can insert their own data"
  ON users FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- Allow authenticated users to SELECT their own data
CREATE POLICY "Users can view their own data"
  ON users FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Allow authenticated users to UPDATE their own data
CREATE POLICY "Users can update their own data"
  ON users FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Allow authenticated users to DELETE their own data
CREATE POLICY "Users can delete their own data"
  ON users FOR DELETE
  TO authenticated
  USING (auth.uid() = id);
```

### Step 4: Verify in Supabase

1. Go to **Tables** section
2. Click on **users** table
3. You should see **Policies** with 4 new policies:
   - ✅ Users can insert their own data
   - ✅ Users can view their own data
   - ✅ Users can update their own data
   - ✅ Users can delete their own data

---

## Step 5: Test in Flutter App

1. In VS Code terminal (where Flutter is running), press `r` for hot reload
2. In the app, click **Sign Up**
3. Create a new account with any email/password
4. After signup is successful, go to Supabase Dashboard
5. Click **Tables** → **users**
6. You should see your new user in the table! ✅

---

## Expected Result After Fix

When you signup with:
- Email: `test@example.com`
- Password: `password123`
- Name: `Test User`

You should see in Supabase `users` table:
| id | email | name | created_at |
|----|-------|------|-----------|
| 1cc47c2f-70d7-... | test@example.com | Test User | 2026-01-14 04:45:09 |

---

## Troubleshooting

### Still getting RLS error?
- Make sure you **dropped** the old policies first
- Make sure you **created** all 4 new policies
- Wait 10 seconds after creating policies
- Press `r` in terminal to hot reload app

### User data still not appearing?
- Check that the user ID in the policy matches: `auth.uid() = id`
- Verify the user is actually authenticated (check terminal for "signedIn")
- Go to **Tables** → **users** → **Policies** and click each one to verify they exist

### Need to see all policies?
1. Supabase Dashboard
2. Tables → users
3. Click the **Policies** tab
4. All 4 policies should be listed

---

## Success Checklist

- [ ] Ran SQL to drop old policies
- [ ] Ran SQL to create new policies
- [ ] See 4 policies in Supabase user table policies
- [ ] Pressed `r` to hot reload Flutter app
- [ ] Signed up with new account
- [ ] New user appears in Supabase users table
- [ ] User data shows: id, email, name, created_at

---

## If Still Having Issues

If users are still not being saved after fixing RLS:

### Option 1: Check server logs
In Flutter terminal, look for error messages that start with "Error saving user"

### Option 2: Disable database insert temporarily
The app will still work without the database insert. Users can login and use the app, they just won't have a profile record yet.

### Option 3: Use Supabase UI to manually insert
1. Supabase Dashboard
2. Tables → users
3. Click **Insert** button
4. Add user data manually

---

## Time Required

⏱️ **~3 minutes** to fix RLS policies

**Status**: 🔴 **MUST FIX - But easy to fix!**

