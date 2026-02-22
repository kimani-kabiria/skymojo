-- Create favorite_locations table
CREATE TABLE IF NOT EXISTS favorite_locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_favorite_locations_user_id ON favorite_locations(user_id);
CREATE INDEX IF NOT EXISTS idx_favorite_locations_user_default ON favorite_locations(user_id, is_default);

-- Enable RLS (Row Level Security)
ALTER TABLE favorite_locations ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own favorite locations" ON favorite_locations
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own favorite locations" ON favorite_locations
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own favorite locations" ON favorite_locations
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own favorite locations" ON favorite_locations
    FOR DELETE USING (auth.uid() = user_id);

-- Create trigger for updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_favorite_locations_updated_at 
    BEFORE UPDATE ON favorite_locations 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Ensure only one default location per user (optional constraint)
-- This can be handled in the application logic instead of a complex constraint
