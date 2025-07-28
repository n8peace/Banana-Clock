-- Add AI preference columns to user_preferences table
-- These fields will store user preferences for AI wake-up content

ALTER TABLE public.user_preferences 
ADD COLUMN weather_enabled BOOLEAN DEFAULT false,
ADD COLUMN headlines_categories JSONB DEFAULT '["business", "technology"]',
ADD COLUMN sports_categories JSONB DEFAULT '["football", "basketball"]',
ADD COLUMN last_sync_at TIMESTAMP WITH TIME ZONE;

-- Add constraints for the new columns
ALTER TABLE public.user_preferences 
ADD CONSTRAINT user_preferences_headlines_categories_check CHECK (headlines_categories IS NOT NULL),
ADD CONSTRAINT user_preferences_sports_categories_check CHECK (sports_categories IS NOT NULL);

-- Create indexes for the new columns
CREATE INDEX idx_user_preferences_weather_enabled ON public.user_preferences(weather_enabled);
CREATE INDEX idx_user_preferences_headlines_categories ON public.user_preferences USING GIN (headlines_categories);
CREATE INDEX idx_user_preferences_sports_categories ON public.user_preferences USING GIN (sports_categories);
CREATE INDEX idx_user_preferences_last_sync_at ON public.user_preferences(last_sync_at);

-- Add comments for documentation
COMMENT ON COLUMN public.user_preferences.weather_enabled IS 'Whether weather content is enabled for AI wake-up';
COMMENT ON COLUMN public.user_preferences.headlines_categories IS 'Array of headlines categories for AI wake-up content';
COMMENT ON COLUMN public.user_preferences.sports_categories IS 'Array of sports categories for AI wake-up content';
COMMENT ON COLUMN public.user_preferences.last_sync_at IS 'Last time preferences were synced from iOS app'; 