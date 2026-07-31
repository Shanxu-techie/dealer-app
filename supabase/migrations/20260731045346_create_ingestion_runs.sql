CREATE TABLE public.ingestion_runs (
  id UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),

  uploaded_by UUID NOT NULL
    CONSTRAINT ingestion_runs_uploaded_by_fkey
    REFERENCES public.profiles(id),

  uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  effective_date DATE NOT NULL,

  original_filename TEXT NOT NULL,

  bucket_name TEXT NOT NULL,

  storage_path TEXT,

  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (
      status IN (
        'pending',
        'completed',
        'failed',
        'partially_failed'
      )
    ),

  rows_processed INTEGER NOT NULL DEFAULT 0
    CHECK (rows_processed >= 0),

  rows_skipped INTEGER NOT NULL DEFAULT 0
    CHECK (rows_skipped >= 0),

  error_summary JSONB,

  completed_at TIMESTAMPTZ,

  UNIQUE (bucket_name, storage_path),

  CONSTRAINT ingestion_runs_completed_at_check CHECK (
    (status = 'pending' AND completed_at IS NULL)
    OR (status != 'pending' AND completed_at IS NOT NULL)
  )
);

CREATE INDEX ingestion_runs_uploaded_by_idx
  ON public.ingestion_runs (uploaded_by);

CREATE INDEX ingestion_runs_effective_date_idx
  ON public.ingestion_runs (effective_date);

CREATE INDEX ingestion_runs_uploaded_at_idx
  ON public.ingestion_runs (uploaded_at DESC);
