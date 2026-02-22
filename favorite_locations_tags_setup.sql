-- Add tags column to favorite_locations table
ALTER TABLE favorite_locations ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';

-- Create index for faster tag queries
CREATE INDEX IF NOT EXISTS idx_favorite_locations_tags ON favorite_locations USING GIN(tags);

-- Update existing records to have empty tags array
UPDATE favorite_locations SET tags = '{}' WHERE tags IS NULL;
