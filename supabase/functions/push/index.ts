// Sends queued push notifications through Firebase Cloud Messaging (HTTP v1).
//
// Called by a Database Webhook on inserts into public.push_queue (and safe to
// call on a schedule as a fallback): every call drains what is still unsent.
//
// Secrets (supabase secrets set …):
//   FIREBASE_SERVICE_ACCOUNT  the Firebase service account key, as JSON
//   PUSH_WEBHOOK_SECRET       shared with the webhook's x-webhook-secret header
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided by Supabase.

import { createClient } from "npm:@supabase/supabase-js@2";

type ServiceAccount = { project_id: string; client_email: string; private_key: string };
type Queued = { id: number; user_id: string; title: string; body: string; data: Record<string, string> };
type Token = { user_id: string; token: string; updated_at: string };

const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

function b64url(bytes: Uint8Array | string): string {
  const raw = typeof bytes === "string" ? new TextEncoder().encode(bytes) : bytes;
  let s = "";
  for (const b of raw) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

/// An OAuth token for FCM from the service account (signed JWT, RS256).
async function accessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = b64url(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));
  const pem = sa.private_key.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = new Uint8Array(
    await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(`${header}.${claims}`)),
  );
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${header}.${claims}.${b64url(signature)}`,
    }),
  });
  if (!res.ok) throw new Error(`OAuth failed: ${res.status} ${await res.text()}`);
  return (await res.json()).access_token;
}

Deno.serve(async (req) => {
  const secret = Deno.env.get("PUSH_WEBHOOK_SECRET");
  if (secret && req.headers.get("x-webhook-secret") !== secret) {
    return new Response("forbidden", { status: 403 });
  }

  const { data: queued, error } = await supabase
    .from("push_queue")
    .select("id, user_id, title, body, data")
    .is("sent_at", null)
    .order("created_at")
    .limit(500);
  if (error) return new Response(error.message, { status: 500 });
  if (!queued?.length) return Response.json({ sent: 0 });

  // Mark first, so two calls at once never send the same notification twice.
  const ids = queued.map((q: Queued) => q.id);
  await supabase.from("push_queue").update({ sent_at: new Date().toISOString() }).in("id", ids);

  const users = [...new Set(queued.map((q: Queued) => q.user_id))];
  const { data: rows } = await supabase.from("push_tokens").select("user_id, token, updated_at").in("user_id", users);
  // A phone that switched accounts keeps only its latest owner.
  const owner = new Map<string, Token>();
  const { data: same } = await supabase
    .from("push_tokens")
    .select("user_id, token, updated_at")
    .in("token", (rows ?? []).map((t: Token) => t.token));
  for (const t of (same ?? []) as Token[]) {
    const seen = owner.get(t.token);
    if (!seen || t.updated_at > seen.updated_at) owner.set(t.token, t);
  }
  const tokensOf = (user: string) =>
    ((rows ?? []) as Token[]).filter((t) => t.user_id === user && owner.get(t.token)?.user_id === user);

  const sa: ServiceAccount = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!);
  const bearer = await accessToken(sa);
  const url = `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`;
  let sent = 0;
  const dead: Token[] = [];

  for (const q of queued as Queued[]) {
    for (const t of tokensOf(q.user_id)) {
      const res = await fetch(url, {
        method: "POST",
        headers: { authorization: `Bearer ${bearer}`, "content-type": "application/json" },
        body: JSON.stringify({
          message: {
            token: t.token,
            notification: { title: q.title, body: q.body },
            data: Object.fromEntries(Object.entries(q.data ?? {}).map(([k, v]) => [k, String(v)])),
            apns: { payload: { aps: { sound: "default" } } },
            android: { priority: "high" },
          },
        }),
      });
      if (res.ok) {
        sent++;
      } else if (res.status === 404 || (await res.text()).includes("UNREGISTERED")) {
        dead.push(t);
      }
    }
  }
  for (const t of dead) {
    await supabase.from("push_tokens").delete().eq("user_id", t.user_id).eq("token", t.token);
  }
  return Response.json({ queued: queued.length, sent, removed: dead.length });
});
