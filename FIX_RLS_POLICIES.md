# Fix RLS Policies - Run This SQL

The issue is the RLS policy is too strict. We need to allow authenticated users to INSERT their own records.

## Go to Supabase and run this SQL:

### Step 1: Drop existing policies (if they exist)

```sql
DROP POLICY IF EXISTS "Users can view their own data" ON users;
DROP POLICY IF EXISTS "Users can update their own data" ON users;
DROP POLICY IF EXISTS "Users can insert their own data" ON users;
```

### Step 2: Create new policies that allow inserts

```sql
-- Allow users to insert their own record during signup
CREATE POLICY "Users can insert their own data"
  ON users FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- Allow users to view their own data
CREATE POLICY "Users can view their own data"
  ON users FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Allow users to update their own profile
CREATE POLICY "Users can update their own data"
  ON users FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Allow users to delete their own data
CREATE POLICY "Users can delete their own data"
  ON users FOR DELETE
  TO authenticated
  USING (auth.uid() = id);
```

---

## After Running SQL:

1. Go back to VS Code terminal
2. Press `r` to hot reload the app
3. Try signing up with a new email
4. Check Supabase Tables → users to see if the new user appears

This should fix the issue! The RLS policy now explicitly allows INSERT operations.

