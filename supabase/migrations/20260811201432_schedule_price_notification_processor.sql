select cron.schedule(
    'process-price-notifications',
    '* * * * *',
    $$
    select net.http_post(
        url := 'https://cdtuylwgszefbbppsqjy.supabase.co/functions/v1/process-price-notifications',
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'apikey', (
                select decrypted_secret
                from vault.decrypted_secrets
                where name = 'price_notification_cron_key'
            )
        ),
        body := '{}'::jsonb,
        timeout_milliseconds := 10000
    );
    $$
);