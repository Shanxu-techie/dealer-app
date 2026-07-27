CREATE TABLE public.profiles (
    id UUID PRIMARY KEY
        REFERENCES auth.users(id)
        ON DELETE CASCADE,

    dealer_code BIGINT UNIQUE,

    role TEXT NOT NULL
        CHECK (role IN ('dealer', 'publisher')),

    name TEXT NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CHECK (
        (role = 'dealer' AND dealer_code IS NOT NULL)
        OR
        (role = 'publisher' AND dealer_code IS NULL)
    )
);

CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

CREATE TRIGGER profiles_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at();

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Dealers can view their own profile"
ON public.profiles
FOR SELECT
TO authenticated
USING (
    auth.uid() = id
);

CREATE OR REPLACE FUNCTION public.is_publisher()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = ''
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE id = auth.uid()
          AND role = 'publisher'
    );
$$;

REVOKE EXECUTE ON FUNCTION public.is_publisher() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_publisher() TO authenticated;

CREATE POLICY "Publishers can view all profiles"
ON public.profiles
FOR SELECT
TO authenticated
USING (
    public.is_publisher()
);
