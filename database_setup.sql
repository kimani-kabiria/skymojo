-- SkyMojo Database Schema
-- Run this in Supabase SQL Editor

-- 1. User Profiles Table
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  username TEXT UNIQUE,
  full_name TEXT,
  avatar_url TEXT,
  default_location TEXT, -- Default location for weather
  temperature_unit TEXT DEFAULT 'celsius', -- celsius or fahrenheit
  theme_preference TEXT DEFAULT 'auto' -- light, dark, auto
);

-- 2. Favorite Locations Table
CREATE TABLE IF NOT EXISTS favorite_locations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  city TEXT,
  country TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_default BOOLEAN DEFAULT false,
  UNIQUE(user_id, latitude, longitude)
);

-- 3. Weather Cache Table
CREATE TABLE IF NOT EXISTS weather_cache (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  weather_data JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  UNIQUE(latitude, longitude)
);

-- 4. Weather Alerts Table
CREATE TABLE IF NOT EXISTS weather_alerts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  location_id UUID REFERENCES favorite_locations(id) ON DELETE CASCADE,
  alert_type TEXT NOT NULL, -- 'temperature', 'rain', 'wind', 'uv'
  threshold_value DECIMAL(5, 2),
  condition TEXT, -- 'above', 'below', 'equals'
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. User Settings Table
CREATE TABLE IF NOT EXISTS user_settings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  push_notifications BOOLEAN DEFAULT true,
  email_alerts BOOLEAN DEFAULT true,
  weather_refresh_interval INTEGER DEFAULT 30, -- minutes
  auto_location BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_favorite_locations_user_id ON favorite_locations(user_id);
CREATE INDEX IF NOT EXISTS idx_weather_cache_coords ON weather_cache(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_weather_cache_expires ON weather_cache(expires_at);
CREATE INDEX IF NOT EXISTS idx_weather_alerts_user_id ON weather_alerts(user_id);
CREATE INDEX IF NOT EXISTS idx_weather_alerts_active ON weather_alerts(is_active);

-- Function to automatically create user profile
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, full_name)
  VALUES (new.id, new.raw_user_meta_data->>'full_name');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_user_settings_updated_at
  BEFORE UPDATE ON user_settings
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Row Level Security (RLS)
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorite_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE weather_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Users can view their own profile
CREATE POLICY "Users can view own profile" ON user_profiles
  FOR SELECT USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON user_profiles
  FOR UPDATE USING (auth.uid() = id);

-- Users can view their own favorite locations
CREATE POLICY "Users can view own favorite locations" ON favorite_locations
  FOR SELECT USING (auth.uid() = user_id);

-- Users can manage their own favorite locations
CREATE POLICY "Users can manage own favorite locations" ON favorite_locations
  FOR ALL USING (auth.uid() = user_id);

-- Users can view their own weather alerts
CREATE POLICY "Users can view own weather alerts" ON weather_alerts
  FOR SELECT USING (auth.uid() = user_id);

-- Users can manage their own weather alerts
CREATE POLICY "Users can manage own weather alerts" ON weather_alerts
  FOR ALL USING (auth.uid() = user_id);

-- Users can view their own settings
CREATE POLICY "Users can view own settings" ON user_settings
  FOR SELECT USING (auth.uid() = user_id);

-- Users can update their own settings
CREATE POLICY "Users can update own settings" ON user_settings
  FOR UPDATE USING (auth.uid() = user_id);

-- Weather cache is readable by all authenticated users
CREATE POLICY "Authenticated users can view weather cache" ON weather_cache
  FOR SELECT USING (auth.role() = 'authenticated');

-- Only service role can insert/update weather cache
CREATE POLICY "Service role can manage weather cache" ON weather_cache
  FOR ALL USING (auth.role() = 'service_role');
