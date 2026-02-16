# Database Schema for User Settings

## Add this SQL to your Supabase database:

### User Settings Table
```sql
-- Create user_settings table
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

-- Enable Row Level Security
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

-- Create policies for user_settings
CREATE POLICY "Users can view their own settings"
    ON public.user_settings
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own settings"
    ON public.user_settings
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own settings"
    ON public.user_settings
    FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own settings"
    ON public.user_settings
    FOR DELETE
    USING (auth.uid() = user_id);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_user_settings_user_id ON public.user_settings(user_id);

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for user_settings
DROP TRIGGER IF EXISTS update_user_settings_updated_at ON public.user_settings;
CREATE TRIGGER update_user_settings_updated_at
    BEFORE UPDATE ON public.user_settings
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();
```

## Instructions:
1. Go to your Supabase project dashboard
2. Navigate to SQL Editor
3. Copy and paste the SQL above
4. Click "Run" to create the table and policies

This table stores:
- **available_days_per_week**: How many days user can care for plants (1-7)
- **preferred_days**: Array of preferred days (e.g., ['Monday', 'Wednesday', 'Friday'])
- **preferred_time_of_day**: When user prefers to do maintenance (morning/afternoon/evening)
- **enable_notifications**: Whether to send reminders
- **Row Level Security (RLS)**: Ensures users can only access their own settings
