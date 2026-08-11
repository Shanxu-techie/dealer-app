import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "npm:@supabase/server";
import { create } from "https://deno.land/x/djwt@v3.0.2/mod.ts";

type FirebaseServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
};

function getServiceAccount(): FirebaseServiceAccount {
  const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");

  if (!raw) {
    throw new Error("FIREBASE_SERVICE_ACCOUNT secret is not configured.");
  }

  try {
    return JSON.parse(raw) as FirebaseServiceAccount;
  } catch {
    throw new Error("FIREBASE_SERVICE_ACCOUNT contains invalid JSON.");
  }
}

async function getGoogleAccessToken(
  serviceAccount: FirebaseServiceAccount,
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);

  const header = {
    alg: "RS256",
    typ: "JWT",
  };

  const payload = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };

  const privateKey = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(serviceAccount.private_key),
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"],
  );

  const jwt = await create(header, payload, privateKey);

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`Failed to obtain Google access token: ${body}`);
  }

  const data = await response.json();

  return data.access_token;
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const base64 = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");

  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);

  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }

  return bytes.buffer;
}

async function sendFcmNotification(
  accessToken: string,
  projectId: string,
  deviceToken: string,
  dealerCode: number,
  effectiveDate: string,
): Promise<void> {
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: deviceToken,
          notification: {
            title: "Price Update",
            body: `New fuel prices are available for dealer ${dealerCode}.`,
          },
          data: {
            dealer_code: String(dealerCode),
            effective_date: effectiveDate,
          },
        },
      }),
    },
  );

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`FCM request failed: ${body}`);
  }
}

Deno.serve(
  withSupabase(
    { auth: ["secret"] },
    async (_req, ctx) => {
      const supabase = ctx.supabaseAdmin;

      try {
        const serviceAccount = getServiceAccount();
        const accessToken = await getGoogleAccessToken(serviceAccount);

        const now = new Date().toISOString();

        const { data: events, error: eventsError } = await supabase
          .from("price_notification_events")
          .select("id, dealer_code, effective_date, scheduled_for")
          .eq("status", "pending")
          .lte("scheduled_for", now)
          .order("scheduled_for", { ascending: true });

        if (eventsError) {
          throw new Error(
            `Failed to fetch notification events: ${eventsError.message}`,
          );
        }

        if (!events || events.length === 0) {
          return Response.json({
            processed: 0,
            sent: 0,
            failed: 0,
            message: "No pending notifications are due.",
          });
        }

        let sent = 0;
        let failed = 0;

        for (const event of events) {
          try {
            const { data: profile, error: profileError } = await supabase
              .from("profiles")
              .select("id")
              .eq("dealer_code", event.dealer_code)
              .eq("role", "dealer")
              .maybeSingle();

            if (profileError) {
              throw new Error(
                `Failed to find dealer profile: ${profileError.message}`,
              );
            }

            if (!profile) {
              throw new Error(
                `No dealer profile found for dealer ${event.dealer_code}.`,
              );
            }

            const { data: tokens, error: tokensError } = await supabase
              .from("device_tokens")
              .select("id, token")
              .eq("user_id", profile.id);

            if (tokensError) {
              throw new Error(
                `Failed to fetch device tokens: ${tokensError.message}`,
              );
            }

            if (!tokens || tokens.length === 0) {
              throw new Error(
                `No FCM device tokens found for dealer ${event.dealer_code}.`,
              );
            }

            for (const token of tokens) {
              await sendFcmNotification(
                accessToken,
                serviceAccount.project_id,
                token.token,
                event.dealer_code,
                event.effective_date,
              );
            }

            const { error: updateError } = await supabase
              .from("price_notification_events")
              .update({
                status: "sent",
                sent_at: new Date().toISOString(),
              })
              .eq("id", event.id)
              .eq("status", "pending");

            if (updateError) {
              throw new Error(
                `Notification sent but event update failed: ${updateError.message}`,
              );
            }

            sent++;
          } catch (error) {
            console.error(
              `Failed to process notification event ${event.id}:`,
              error,
            );

            await supabase
              .from("price_notification_events")
              .update({
                status: "failed",
              })
              .eq("id", event.id)
              .eq("status", "pending");

            failed++;
          }
        }

        return Response.json({
          processed: events.length,
          sent,
          failed,
        });
      } catch (error) {
        console.error("Price notification function failed:", error);

        return Response.json(
          {
            error: error instanceof Error
              ? error.message
              : "Unknown error",
          },
          { status: 500 },
        );
      }
    },
  ),
);