CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE public.dealer_prices (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    dealer_code BIGINT NOT NULL,
    effective_date date NOT NULL,
    product_name text NOT NULL
        CHECK (product_name IN ('MS', 'HSD')),
    indent_price numeric(10,2) NOT NULL,
    fixed_selling_price numeric(10,2) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT dealer_prices_unique
        UNIQUE (dealer_code, effective_date, product_name)
);

ALTER TABLE public.dealer_prices ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.get_dealer_code()
RETURNS bigint
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT dealer_code
    FROM public.profiles
    WHERE id = auth.uid();
$$;

REVOKE EXECUTE ON FUNCTION public.get_dealer_code() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_dealer_code() TO authenticated;

CREATE POLICY "Dealers can view own prices"
ON public.dealer_prices
FOR SELECT
TO authenticated
USING (
    dealer_code = public.get_dealer_code()
);

CREATE POLICY "Publishers can view all prices"
ON public.dealer_prices
FOR SELECT
TO authenticated
USING (
    public.is_publisher()
);