CREATE TABLE public.device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL
        REFERENCES auth.users(id)
        ON DELETE CASCADE,

    token TEXT NOT NULL,

    platform TEXT NOT NULL
        CHECK (platform IN ('android', 'ios')),

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT device_tokens_user_token_unique
        UNIQUE (user_id, token)
);

CREATE TRIGGER device_tokens_updated_at
BEFORE UPDATE ON public.device_tokens
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at();

ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own device tokens"
ON public.device_tokens
FOR SELECT
TO authenticated
USING (
    auth.uid() = user_id
);

CREATE POLICY "Users can insert their own device tokens"
ON public.device_tokens
FOR INSERT
TO authenticated
WITH CHECK (
    auth.uid() = user_id
);

CREATE POLICY "Users can update their own device tokens"
ON public.device_tokens
FOR UPDATE
TO authenticated
USING (
    auth.uid() = user_id
)
WITH CHECK (
    auth.uid() = user_id
);

CREATE POLICY "Users can delete their own device tokens"
ON public.device_tokens
FOR DELETE
TO authenticated
USING (
    auth.uid() = user_id
);