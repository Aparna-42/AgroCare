# Fix RLS Policy for Plants Table

## Error
```
Error saving plant: StorageException(message: new row violates row-level security policy, statusCode: 403, error: Unauthorized)
```

## Solution
Run this SQL in your Supabase SQL Editor:

```sql
-- Enable RLS on plants table
ALTER TABLE plants ENABLE ROW LEVEL SECURITY;

-- Drop old policies if they exist
DROP POLICY IF EXISTS "Users can view own plants" ON plants;
DROP POLICY IF EXISTS "Users can insert own plants" ON plants;
DROP POLICY IF EXISTS "Users can update own plants" ON plants;
DROP POLICY IF EXISTS "Users can delete own plants" ON plants;

-- Allow users to see only their own plants
CREATE POLICY "Users can view own plants"
ON plants FOR SELECT
USING (auth.uid() = user_id);

-- Allow users to insert their own plants
CREATE POLICY "Users can insert own plants"
ON plants FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Allow users to update their own plants
CREATE POLICY "Users can update own plants"
ON plants FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Allow users to delete their own plants
CREATE POLICY "Users can delete own plants"
ON plants FOR DELETE
USING (auth.uid() = user_id);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_plants_user_id ON plants(user_id);
```

## How to Run

1. **Go to Supabase Dashboard**: https://app.supabase.com
2. **Select your project**
3. **Click "SQL Editor"** (left sidebar)
4. **Click "New Query"**
5. **Copy and paste the SQL above**
6. **Click "Run"** ▶️
7. **Success!** ✅ You should see "Success. No rows returned"

## What This Does

- ✅ Enables Row Level Security on `plants` table
- ✅ Allows users to INSERT their own plants
- ✅ Allows users to VIEW only their own plants
- ✅ Allows users to UPDATE only their own plants
- ✅ Allows users to DELETE only their own plants
- ✅ Creates an index for faster queries

## Verify RLS is Enabled

1. Go to **Supabase Dashboard → Tables**
2. Click on **`plants`** table
3. Look for a **🔒 lock icon** in the header - it should be blue/enabled
4. If it's gray, click it to enable RLS

## Test

After running the SQL, restart the app and try adding a plant again. It should now work! ✅

---

**Note**: The `auth.uid()` function compares the current authenticated user's ID with the `user_id` column. This ensures users can only access their own plants.
