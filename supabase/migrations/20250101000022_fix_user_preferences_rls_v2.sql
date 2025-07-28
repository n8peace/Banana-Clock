-- Fix RLS policies for user_preferences table - Version 2
-- More permissive policies to handle new user creation

-- Drop existing policies
DROP POLICY IF EXISTS "Users can insert their own preferences" ON public.user_preferences;
DROP POLICY IF EXISTS "Users can select their own preferences" ON public.user_preferences;
DROP POLICY IF EXISTS "Users can update their own preferences" ON public.user_preferences;
DROP POLICY IF EXISTS "Users can delete their own preferences" ON public.user_preferences;
DROP POLICY IF EXISTS "Service role has full access" ON public.user_preferences;

-- Create more permissive policies
-- Allow any authenticated user to insert preferences (for new users)
CREATE POLICY "Allow authenticated users to insert preferences" ON public.user_preferences
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Allow users to select their own preferences
CREATE POLICY "Users can select their own preferences" ON public.user_preferences
    FOR SELECT USING (user_id = auth.uid());

-- Allow users to update their own preferences
CREATE POLICY "Users can update their own preferences" ON public.user_preferences
    FOR UPDATE USING (user_id = auth.uid());

-- Allow users to delete their own preferences
CREATE POLICY "Users can delete their own preferences" ON public.user_preferences
    FOR DELETE USING (user_id = auth.uid());

-- Service role has full access for background jobs
CREATE POLICY "Service role has full access" ON public.user_preferences
    FOR ALL USING (auth.role() = 'service_role');

-- Add comments for documentation
COMMENT ON POLICY "Allow authenticated users to insert preferences" ON public.user_preferences IS 'Allow any authenticated user to create preferences (for new users)';
COMMENT ON POLICY "Users can select their own preferences" ON public.user_preferences IS 'Allow users to read their preferences';
COMMENT ON POLICY "Users can update their own preferences" ON public.user_preferences IS 'Allow users to update their preferences';
COMMENT ON POLICY "Users can delete their own preferences" ON public.user_preferences IS 'Allow users to delete their preferences';
COMMENT ON POLICY "Service role has full access" ON public.user_preferences IS 'Allow service role for background operations'; 