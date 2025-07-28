-- Fix RLS policies for user_preferences table
-- Allow new users to create their initial preferences

-- Drop existing policies
DROP POLICY IF EXISTS "Users can manage their own preferences" ON public.user_preferences;
DROP POLICY IF EXISTS "Service role has full access" ON public.user_preferences;

-- Create more permissive policies
-- Allow users to insert their own preferences (for new users)
CREATE POLICY "Users can insert their own preferences" ON public.user_preferences
    FOR INSERT WITH CHECK (user_id = auth.uid());

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
COMMENT ON POLICY "Users can insert their own preferences" ON public.user_preferences IS 'Allow new users to create initial preferences';
COMMENT ON POLICY "Users can select their own preferences" ON public.user_preferences IS 'Allow users to read their preferences';
COMMENT ON POLICY "Users can update their own preferences" ON public.user_preferences IS 'Allow users to update their preferences';
COMMENT ON POLICY "Users can delete their own preferences" ON public.user_preferences IS 'Allow users to delete their preferences';
COMMENT ON POLICY "Service role has full access" ON public.user_preferences IS 'Allow service role for background operations'; 