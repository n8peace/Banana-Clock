-- Fix user_preferences INSERT policy to properly validate user_id
-- The current policy only checks authentication but doesn't validate user_id

-- Drop the problematic INSERT policy
DROP POLICY IF EXISTS "Allow authenticated users to insert preferences" ON public.user_preferences;

-- Create a new INSERT policy that validates both authentication and user_id
CREATE POLICY "Users can insert their own preferences" ON public.user_preferences
    FOR INSERT WITH CHECK (
        auth.role() = 'authenticated' 
        AND user_id = auth.uid()
    );

-- Add comment for documentation
COMMENT ON POLICY "Users can insert their own preferences" ON public.user_preferences IS 'Allow authenticated users to create their own preferences with proper user_id validation'; 