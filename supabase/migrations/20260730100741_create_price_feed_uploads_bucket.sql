INSERT INTO storage.buckets (id, name, public)
VALUES ('price-feed-uploads', 'price-feed-uploads', false)
ON CONFLICT (id) DO NOTHING;