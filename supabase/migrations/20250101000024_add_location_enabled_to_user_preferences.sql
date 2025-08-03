-- Add location_enabled column to user_preferences table
-- This field will control whether location-based content is enabled

ALTER TABLE public.user_preferences 
ADD COLUMN location_enabled BOOLEAN DEFAULT false;

-- Add constraint for the new column
ALTER TABLE public.user_preferences 
ADD CONSTRAINT user_preferences_location_enabled_check CHECK (location_enabled IS NOT NULL);

-- Create index for the new column
CREATE INDEX idx_user_preferences_location_enabled ON public.user_preferences(location_enabled);

-- Add comment for documentation
COMMENT ON COLUMN public.user_preferences.location_enabled IS 'Whether location-based content is enabled for AI wake-up';