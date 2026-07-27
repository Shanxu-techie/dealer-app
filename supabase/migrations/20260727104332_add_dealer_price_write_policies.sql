ALTER TABLE public.dealer_prices
ADD CONSTRAINT positive_prices
CHECK (
  indent_price > 0
  AND fixed_selling_price > 0
);

CREATE POLICY "Publishers can insert dealer prices"
ON public.dealer_prices
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_publisher()
);

CREATE POLICY "Publishers can update dealer prices"
ON public.dealer_prices
FOR UPDATE
TO authenticated
USING (
  public.is_publisher()
)
WITH CHECK (
  public.is_publisher()
);