# Alternative Solution: Auto-create User Records with Trigger

If you still want an easier solution, use this Postgres trigger that AUTOMATICALLY creates a user record when someone signs up.

## Advantage
✅ No RLS policy issues  
✅ Automatic user record creation  
✅ No code changes needed  

## Go to Supabase SQL Editor and run this:

```sql
-- Create a function to handle new user signups
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', 'New User')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
```

---

## What This Does

When a new user signs up:
1. ✅ Supabase creates auth record
2. ✅ Trigger automatically creates `users` table record
3. ✅ User data includes: id, email, name

---

## Test It

1. Run the SQL above
2. Press `r` in Flutter to hot reload
3. Sign up with new email
4. Check Supabase Tables → users
5. New user should appear automatically!

---

## If You Used This Instead of RLS Fix

You can REMOVE the signup database insert code from auth_provider.dart:

```dart
// Remove this part from signup():
try {
  await _supabase.from('users').insert({...});
} catch (dbError) {...}
```

The trigger handles it automatically!

---

## Which Solution to Use?

| Approach | Best For | Difficulty |
|----------|----------|-----------|
| **Fix RLS Policies** | Learning RLS + Production | Easy ⭐ |
| **Postgres Trigger** | Automatic handling | Very Easy ⭐⭐ |

**Recommendation**: Use the Postgres Trigger approach - it's simpler!

