-- Create favorite_locations table (only if it doesn't exist)
CREATE TABLE IF NOT EXISTS favorite_locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes (only if they don't exist)
CREATE INDEX IF NOT EXISTS idx_favorite_locations_user_id ON favorite_locations(user_id);
CREATE INDEX IF NOT EXISTS idx_favorite_locations_user_default ON favorite_locations(user_id, is_default);

-- Enable RLS (only if not already enabled)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_tables 
        WHERE tablename = 'favorite_locations' 
        AND rowsecurity = true
    ) THEN
        ALTER TABLE favorite_locations ENABLE ROW LEVEL SECURITY;
    END IF;
END $$;

-- Create trigger function (only if it doesn't exist)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger (only if it doesn't exist)
DROP TRIGGER IF EXISTS update_favorite_locations_updated_at ON favorite_locations;
CREATE TRIGGER update_favorite_locations_updated_at 
    BEFORE UPDATE ON favorite_locations 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();
