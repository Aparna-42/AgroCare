# Supabase Storage Setup Guide

## ⚠️ CRITICAL STEP: Create Storage Buckets

Your app needs storage buckets for image uploads. Follow these steps:

---

## Step 1: Go to Supabase Dashboard

1. Open: https://app.supabase.com
2. Select your **AgroCare** project
3. Click **Storage** in the left sidebar

---

## Step 2: Create 3 Storage Buckets

### Bucket 1: plant-images (For Plant Photos)
1. Click **Create new bucket**
2. **Bucket name**: `plant-images`
3. **Make it public**: ✅ Check the "Public bucket" checkbox
4. Click **Create bucket**

### Bucket 2: profile-pictures (For User Avatars)
1. Click **Create new bucket**
2. **Bucket name**: `profile-pictures`
3. **Make it public**: ✅ Check the "Public bucket" checkbox
4. Click **Create bucket**

### Bucket 3: disease-reports (For Analysis Reports)
1. Click **Create new bucket**
2. **Bucket name**: `disease-reports`
3. **Make it public**: ⚠️ Keep it PRIVATE (don't check public)
4. Click **Create bucket**

---

## Step 3: Enable Row Level Security (RLS) on Storage

1. For each bucket, click the **...** (three dots) menu
2. Select **Policies**
3. Click **New policy**
4. Choose **For authenticated users** template
5. Click **Review** then **Save policy**

Repeat for all 3 buckets.

---

## Step 4: Verify Buckets Created

After creating, you should see:
- ✅ plant-images (Public)
- ✅ profile-pictures (Public)
- ✅ disease-reports (Private)

---

## Storage Policies (Copy-Paste SQL)

If you need to create policies manually, go to **SQL Editor** and run:

### For plant-images bucket:
```sql
CREATE POLICY "Users can upload plant images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'plant-images' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Public access to plant images"
ON storage.objects
FOR SELECT
TO anon
USING (bucket_id = 'plant-images');
```

### For profile-pictures bucket:
```sql
CREATE POLICY "Users can upload profile pictures"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'profile-pictures' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Public access to profile pictures"
ON storage.objects
FOR SELECT
TO anon
USING (bucket_id = 'profile-pictures');
```

### For disease-reports bucket:
```sql
CREATE POLICY "Users can upload disease reports"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'disease-reports' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can only see their own disease reports"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'disease-reports' AND auth.uid()::text = (storage.foldername(name))[1]);
```

---

## What These Buckets Do

| Bucket | Purpose | Public? | Used For |
|--------|---------|--------|----------|
| **plant-images** | Store plant photos | ✅ Yes | Users upload photos of their plants |
| **profile-pictures** | Store user avatars | ✅ Yes | User profile pictures |
| **disease-reports** | Store analysis results | ❌ No | Private disease analysis reports |

---

## App Integration Status

✅ **AuthProvider** - Real Supabase authentication enabled  
✅ **PlantProvider** - Connects to `plants` table in Supabase  
✅ **MaintenanceProvider** - Connects to `maintenance_tasks` table  
⏳ **Storage** - Waiting for buckets to be created  

---

## Next Steps After Creating Buckets

1. Create the Supabase database tables (run SQL from `SUPABASE_SETUP.md`)
2. Create storage buckets (THIS FILE - steps above)
3. Run the Flutter app: `flutter run -d chrome`
4. Test signup/login with real Supabase auth
5. Test adding plants (will save to database)

---

## Quick Checklist

- [ ] Go to Supabase Dashboard
- [ ] Click Storage
- [ ] Create `plant-images` bucket (Public)
- [ ] Create `profile-pictures` bucket (Public)
- [ ] Create `disease-reports` bucket (Private)
- [ ] Enable RLS policies on each bucket
- [ ] Verify all 3 buckets appear in Storage section
- [ ] Run app and test signup

**Time needed**: ~5 minutes  
**Difficulty**: Easy - Just clicking buttons  
**Status**: READY TO DO

