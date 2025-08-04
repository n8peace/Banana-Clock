-- Migration: Transform user_weather_data to shared weather cache by zip code
-- This supports mobile-initiated content generation with fresh weather data

BEGIN;

-- Drop the existing table and cascade dependencies
DROP TABLE IF EXISTS user_weather_data CASCADE;

-- Create new shared weather cache structure
CREATE TABLE user_weather_data (
    location_zip TEXT PRIMARY KEY,
    weather_data JSONB NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    last_updated_by UUID REFERENCES auth.users(id)
);

-- Add index for performance on time-based queries
CREATE INDEX idx_weather_updated_at ON user_weather_data(updated_at);
CREATE INDEX idx_weather_last_updated_by ON user_weather_data(last_updated_by);

-- Enable Row Level Security
ALTER TABLE user_weather_data ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Policy: Anyone can read weather data (needed for content generation)
CREATE POLICY "Public read access for weather data" ON user_weather_data
    FOR SELECT 
    USING (true);

-- Policy: Authenticated users can insert new weather data
CREATE POLICY "Authenticated users can insert weather" ON user_weather_data
    FOR INSERT 
    WITH CHECK (auth.uid() IS NOT NULL);

-- Policy: Authenticated users can update weather data
CREATE POLICY "Authenticated users can update weather" ON user_weather_data
    FOR UPDATE 
    USING (auth.uid() IS NOT NULL)
    WITH CHECK (auth.uid() IS NOT NULL);

-- Create upsert function for atomic weather updates
CREATE OR REPLACE FUNCTION upsert_weather_data(
    p_zip TEXT,
    p_weather JSONB,
    p_user_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
BEGIN
    -- Validate inputs
    IF p_zip IS NULL OR length(p_zip) = 0 THEN
        RAISE EXCEPTION 'Invalid zip code provided';
    END IF;
    
    IF p_weather IS NULL OR p_weather = '{}'::jsonb THEN
        RAISE EXCEPTION 'Invalid weather data provided';
    END IF;

    -- Perform upsert with time-based conflict resolution
    INSERT INTO user_weather_data (location_zip, weather_data, updated_at, last_updated_by)
    VALUES (p_zip, p_weather, NOW(), p_user_id)
    ON CONFLICT (location_zip) 
    DO UPDATE SET 
        weather_data = EXCLUDED.weather_data,
        updated_at = NOW(),
        last_updated_by = p_user_id
    WHERE user_weather_data.updated_at < NOW() - INTERVAL '5 minutes' -- Only update if data is older than 5 minutes
       OR user_weather_data.weather_data IS NULL;
    
    -- Return the current weather data (either newly inserted or existing)
    SELECT row_to_json(w.*) INTO v_result
    FROM user_weather_data w
    WHERE w.location_zip = p_zip;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION upsert_weather_data(TEXT, JSONB, UUID) TO authenticated;

-- Add comment for documentation
COMMENT ON TABLE user_weather_data IS 'Shared weather cache by zip code for AI content generation';
COMMENT ON COLUMN user_weather_data.location_zip IS 'ZIP code as primary key for weather data';
COMMENT ON COLUMN user_weather_data.weather_data IS 'JSON object containing temperature, condition, humidity, etc';
COMMENT ON COLUMN user_weather_data.updated_at IS 'Last update timestamp for cache freshness';
COMMENT ON COLUMN user_weather_data.last_updated_by IS 'User ID who last updated this weather data';

COMMIT;