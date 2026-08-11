CREATE TABLE public.price_notification_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    dealer_code BIGINT NOT NULL,

    effective_date DATE NOT NULL,

    scheduled_for TIMESTAMPTZ NOT NULL,

    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'sent', 'failed')),

    sent_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT price_notification_events_unique
        UNIQUE (dealer_code, effective_date),

    CONSTRAINT price_notification_events_sent_at_check
        CHECK (
            (status = 'sent' AND sent_at IS NOT NULL)
            OR
            (status IN ('pending', 'failed') AND sent_at IS NULL)
        )
);

CREATE INDEX price_notification_events_pending_idx
    ON public.price_notification_events (scheduled_for)
    WHERE status = 'pending';

CREATE INDEX price_notification_events_created_at_idx
    ON public.price_notification_events (created_at DESC);


CREATE OR REPLACE FUNCTION public.create_price_notification_event()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    notification_time TIMESTAMPTZ;
BEGIN
    /*
     * Only create notification events for today's or future
     * effective dates. Historical price changes do not notify.
     */

    IF NEW.effective_date < CURRENT_DATE THEN
        RETURN NEW;
    END IF;

    /*
     * Today's price:
     * notify immediately.
     *
     * Future price:
     * notify at 12:00 AM Asia/Karachi on the effective date.
     */
    IF NEW.effective_date = CURRENT_DATE THEN
        notification_time := now();
    ELSE
        notification_time :=
            (
                NEW.effective_date::timestamp
                AT TIME ZONE 'Asia/Karachi'
            );
    END IF;

    /*
     * INSERT:
     * A new price row is available.
     */
    IF TG_OP = 'INSERT' THEN

        INSERT INTO public.price_notification_events (
            dealer_code,
            effective_date,
            scheduled_for
        )
        VALUES (
            NEW.dealer_code,
            NEW.effective_date,
            notification_time
        )
        ON CONFLICT (dealer_code, effective_date)
        DO NOTHING;

        RETURN NEW;
    END IF;

    /*
     * UPDATE:
     * Only notify when an actual price value changes.
     */
    IF TG_OP = 'UPDATE'
       AND (
            NEW.indent_price IS DISTINCT FROM OLD.indent_price
            OR NEW.fixed_selling_price IS DISTINCT FROM OLD.fixed_selling_price
       )
    THEN

        INSERT INTO public.price_notification_events (
            dealer_code,
            effective_date,
            scheduled_for
        )
        VALUES (
            NEW.dealer_code,
            NEW.effective_date,
            notification_time
        )
        ON CONFLICT (dealer_code, effective_date)
        DO NOTHING;

    END IF;

    RETURN NEW;
END;
$$;


CREATE TRIGGER dealer_prices_create_notification_event
AFTER INSERT OR UPDATE
ON public.dealer_prices
FOR EACH ROW
EXECUTE FUNCTION public.create_price_notification_event();


ALTER TABLE public.price_notification_events
ENABLE ROW LEVEL SECURITY;