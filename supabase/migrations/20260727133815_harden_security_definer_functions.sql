-- Fix 1: trigger function was missing search_path hardening
ALTER FUNCTION public.update_updated_at() SET search_path = '';

-- Fix 2: move helper functions out of the exposed public schema
CREATE SCHEMA IF NOT EXISTS private;

CREATE OR REPLACE FUNCTION private.is_publisher()
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

CREATE OR REPLACE FUNCTION private.get_dealer_code()
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

-- authenticated needs USAGE on the schema, not just EXECUTE on the function
GRANT USAGE ON SCHEMA private TO authenticated;

REVOKE EXECUTE ON FUNCTION private.is_publisher() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION private.is_publisher() TO authenticated;

REVOKE EXECUTE ON FUNCTION private.get_dealer_code() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION private.get_dealer_code() TO authenticated;

-- Repoint every policy at the new location
DROP POLICY "Publishers can view all profiles" ON public.profiles;
CREATE POLICY "Publishers can view all profiles"
ON public.profiles FOR SELECT TO authenticated
USING (private.is_publisher());

DROP POLICY "Dealers can view own prices" ON public.dealer_prices;
CREATE POLICY "Dealers can view own prices"
ON public.dealer_prices FOR SELECT TO authenticated
USING (dealer_code = private.get_dealer_code());

DROP POLICY "Publishers can view all prices" ON public.dealer_prices;
CREATE POLICY "Publishers can view all prices"
ON public.dealer_prices FOR SELECT TO authenticated
USING (private.is_publisher());

DROP POLICY "Publishers can insert dealer prices" ON public.dealer_prices;
CREATE POLICY "Publishers can insert dealer prices"
ON public.dealer_prices FOR INSERT TO authenticated
WITH CHECK (private.is_publisher());

DROP POLICY "Publishers can update dealer prices" ON public.dealer_prices;
CREATE POLICY "Publishers can update dealer prices"
ON public.dealer_prices FOR UPDATE TO authenticated
USING (private.is_publisher())
WITH CHECK (private.is_publisher());

-- Old public-schema versions no longer needed
DROP FUNCTION public.is_publisher();
DROP FUNCTION public.get_dealer_code();