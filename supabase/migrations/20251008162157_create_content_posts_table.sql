/*
  # Create content_posts table

  1. New Tables
    - `content_posts`
      - `id` (uuid, primary key, auto-generated)
      - `title` (varchar 255)
      - `content` (text, required)
      - `content_type` (varchar 50, must be 'create_post' or 'lead_magnet')
      - `status` (varchar 20, defaults to 'draft', must be 'draft', 'scheduled', 'published', or 'archived')
      - `source_data` (jsonb, defaults to empty object)
      - `original_content` (text)
      - `edit_history` (jsonb, defaults to empty array)
      - `scheduled_date` (timestamp with timezone)
      - `platform` (varchar 50)
      - `tags` (text array)
      - `created_at` (timestamp with timezone, defaults to now)
      - `updated_at` (timestamp with timezone, defaults to now)

  2. Security
    - Enable RLS on `content_posts` table
    - Add policy for all operations (temporary until auth is implemented)

  3. Performance
    - Index on `content_type` for filtering by type
    - Index on `status` for filtering by status
    - Index on `scheduled_date` for calendar queries
    - Index on `created_at` (descending) for recent posts

  4. Automation
    - Function `update_updated_at_column()` to auto-update timestamps
    - Trigger to call this function before updates
*/

-- Create content_posts table
CREATE TABLE IF NOT EXISTS public.content_posts (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  title VARCHAR(255),
  content TEXT NOT NULL,
  content_type VARCHAR(50) NOT NULL CHECK (content_type IN ('create_post', 'lead_magnet')),
  status VARCHAR(20) NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'scheduled', 'published', 'archived')),
  source_data JSONB NOT NULL DEFAULT '{}',
  original_content TEXT,
  edit_history JSONB NOT NULL DEFAULT '[]',
  scheduled_date TIMESTAMP WITH TIME ZONE,
  platform VARCHAR(50),
  tags TEXT[],
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE public.content_posts ENABLE ROW LEVEL SECURITY;

-- Create policy to allow all operations (since no auth is implemented yet)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'content_posts' 
    AND policyname = 'Allow all operations on content_posts'
  ) THEN
    CREATE POLICY "Allow all operations on content_posts" 
    ON public.content_posts 
    FOR ALL 
    USING (true) 
    WITH CHECK (true);
  END IF;
END $$;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_content_posts_content_type ON public.content_posts(content_type);
CREATE INDEX IF NOT EXISTS idx_content_posts_status ON public.content_posts(status);
CREATE INDEX IF NOT EXISTS idx_content_posts_scheduled_date ON public.content_posts(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_content_posts_created_at ON public.content_posts(created_at DESC);

-- Create function to automatically update updated_at
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for automatic timestamp updates
DROP TRIGGER IF EXISTS update_content_posts_updated_at ON public.content_posts;
CREATE TRIGGER update_content_posts_updated_at
  BEFORE UPDATE ON public.content_posts
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();