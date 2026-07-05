-- DM Auto OS - Supabase Storage buckets and RLS policies
-- Run after migrations 001-004

-- ---------------------------------------------------------------------------
-- Storage buckets
-- ---------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'documents',
  'documents',
  FALSE,
  52428800,
  ARRAY[
    'application/pdf',
    'image/jpeg',
    'image/png',
    'image/webp',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  ]
)
ON CONFLICT (id) DO UPDATE SET
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'vehicle-photos',
  'vehicle-photos',
  FALSE,
  10485760,
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- ---------------------------------------------------------------------------
-- Storage RLS — documents bucket
-- ---------------------------------------------------------------------------
CREATE POLICY "Authenticated users can read documents bucket"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'documents');

CREATE POLICY "Authenticated users can upload to documents bucket"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'documents'
    AND auth.uid() IS NOT NULL
  );

CREATE POLICY "Authenticated users can update own documents bucket files"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'documents' AND owner = auth.uid())
  WITH CHECK (bucket_id = 'documents');

CREATE POLICY "Administrators can delete documents bucket files"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'documents'
    AND (
      owner = auth.uid()
      OR public.is_administrator()
    )
  );

-- ---------------------------------------------------------------------------
-- Storage RLS — vehicle-photos bucket
-- ---------------------------------------------------------------------------
CREATE POLICY "Authenticated users can read vehicle photos"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'vehicle-photos');

CREATE POLICY "Authenticated users can upload vehicle photos"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'vehicle-photos'
    AND auth.uid() IS NOT NULL
  );

CREATE POLICY "Authenticated users can update own vehicle photos"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'vehicle-photos' AND owner = auth.uid())
  WITH CHECK (bucket_id = 'vehicle-photos');

CREATE POLICY "Administrators can delete vehicle photos"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'vehicle-photos'
    AND (
      owner = auth.uid()
      OR public.is_administrator()
    )
  );
