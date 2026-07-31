ALTER TABLE public.ingestion_runs
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Publishers can view ingestion runs"
ON public.ingestion_runs
FOR SELECT
TO authenticated
USING (
    private.is_publisher()
);

CREATE POLICY "Publishers can insert ingestion runs"
ON public.ingestion_runs
FOR INSERT
TO authenticated
WITH CHECK (
    private.is_publisher()
    AND uploaded_by = auth.uid()
);

CREATE POLICY "Publishers can update ingestion runs"
ON public.ingestion_runs
FOR UPDATE
TO authenticated
USING (
    private.is_publisher()
)
WITH CHECK (
    private.is_publisher()
);

CREATE POLICY "Publishers manage price feed uploads"
ON storage.objects
FOR ALL
TO authenticated
USING (
    bucket_id = 'price-feed-uploads'
    AND private.is_publisher()
)
WITH CHECK (
    bucket_id = 'price-feed-uploads'
    AND private.is_publisher()
);

-- No DELETE policy on ingestion_runs.
-- Audit records are intentionally not deletable through the application.