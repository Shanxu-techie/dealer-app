CREATE OR REPLACE FUNCTION public.protect_ingestion_run_audit_fields()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  -- Immutable audit fields
  IF NEW.uploaded_by IS DISTINCT FROM OLD.uploaded_by THEN
    RAISE EXCEPTION 'uploaded_by cannot be modified';
  END IF;

  IF NEW.uploaded_at IS DISTINCT FROM OLD.uploaded_at THEN
    RAISE EXCEPTION 'uploaded_at cannot be modified';
  END IF;

  IF NEW.effective_date IS DISTINCT FROM OLD.effective_date THEN
    RAISE EXCEPTION 'effective_date cannot be modified';
  END IF;

  IF NEW.original_filename IS DISTINCT FROM OLD.original_filename THEN
    RAISE EXCEPTION 'original_filename cannot be modified';
  END IF;

  IF NEW.bucket_name IS DISTINCT FROM OLD.bucket_name THEN
    RAISE EXCEPTION 'bucket_name cannot be modified';
  END IF;

  -- storage_path is write-once
  IF OLD.storage_path IS NOT NULL
     AND NEW.storage_path IS DISTINCT FROM OLD.storage_path THEN
    RAISE EXCEPTION 'storage_path cannot be modified once set';
  END IF;

  RETURN NEW;
END;
$$;

-- Protect immutable audit fields.
-- Any correction to these fields must be performed manually by a DBA,
-- not through the application.

CREATE TRIGGER protect_ingestion_run_audit_fields
BEFORE UPDATE
ON public.ingestion_runs
FOR EACH ROW
EXECUTE FUNCTION public.protect_ingestion_run_audit_fields();