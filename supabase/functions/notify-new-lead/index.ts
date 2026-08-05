// Supabase Edge Function: notify-new-lead
// Sends FCM push notification to all Super Admin devices on leads table INSERT

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const DEFAULT_SUPABASE_URL = "https://bnjvugxvcoqgfvvvwpzc.supabase.co";
const FCM_PROJECT_ID = "ecraftz-crm-mobapp";

// Fallback embedded service account object (guarantees valid credentials)
const SERVICE_ACCOUNT = {
  "type": "service_account",
  "project_id": "ecraftz-crm-mobapp",
  "private_key_id": "1788001f7ee166d75a0d1f158d202cd7da1cebbc",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDDPhmThV4FMPib\nASNslava+iWykc803u4wftvIEZJ1sEqk7BhzOT58WWaQUIB8PvbbpKsa8cunWUsU\nDEoPeWstgOQI8Ivzgd4rjQ8olMCU+w/yv/fhbHk3cc1rgGdxxpX6rFwr4N4H/qrZ\nwE/ReHXT/5x1LyZ283zL5Rehm9cN+X22sLS70FTzY8ZPgQwzUn9pT5t8GVQhesRV\nkMe5aq1FYGHcbdzzQAO3bqwQh/Q7wy+9HJlBIw4UziaEpeMEtMT2J7ZkoypndBx3\nffMYPmS1X+q2ofbQF3+DsCpc/Qvs4grk8KlOlqUVFesBrxLTbYx6j9nmLIIG6Cuf\nniPLIENdAgMBAAECggEAGSwM/R2RSScOrmFfsVS8sv9UU+kDp4PkfsEkUe+eC+le\nPlQoNNbZDQwzsoCGiD5P8nKREujAwoM7MEsDU2pqnJPFErf8uzjvrXrCzQ8coziZ\nTklcyqYDHNhhzS3haGRbmtWVDp0v0yUM3wUx5UZcHqiSgfNByM1MtjcDrHTcrbLW\nrpgs7k4J/lpTjGsO+PNTsWte7SUAgLO7mzDtn38UJrqa9Kq6Sb8EnE2/1de+jHaE\nGac1P5v7O5xC+4Ex6zzLzAD9qrnk7qahK8uWEWrkXsutBWbKRa3I1U69C/UNd9Ae\nfXK4jo2b39triq34zs2REF3h7j2K+A/IYSd0NYP0KwKBgQDvlILtiGmKqby2NY5f\na4bdFrekTdBCPXS/3bb6972D+AMPXgx3mbAz2muB3c3trPPHJr3mt+xnbrGvm0Eh\nMrRAoFa+c71+tWX2Wpls0pBViJbTTfnsHOyGTwHsyntK32Ceu5Eh/bE/tFAEBdyY\n9FMS8Iscogh+hm0G3DBgCs/sCwKBgQDQn60Oy3OBk51XIHVtgOevcv65hk1iAbVD\nzsYRCNrI/eazi0BbkIMuo8jKzZ75HVQQnO9m50fdZNmnxhOIC3R66zCscqUd4tFF\naaD640JbiNQQkwiMuSKBQS0dyLyUSsPHw7fYmKaquvmy/WmSIa+x2W4mpx+4YC0V\nX8UKiujHNwKBgQDt33i3u09/O9SA3WAE4dA/yASCADic7EP1FIBPYpcqZp8zLOAY\nB+JpOZ6wjLegGq7Yt2CpqUfx0nhdsTrTaXKLECfQZT5qhlU8auwWnmJsanfGSY+x\nnW5CVEPHBauwxWU7dWQ+aZMJe1BPDjrfKwcosOiOf1sLtRCfVRQ658FVzQKBgD+3\nhPNvz+dTXkqt7y9yn1BGnuWqzxePzfzXukaZnbilU0Ci1xUgHfCwtTK7ekI7YuFw\nDO4w1RIZKyDCrlRuqzSfgE4q9aMbEy9QA4qcvjeWoq4tOf9Ay/kOHulp1a605vas\nIApXFRAv6vNv0j5/a1m2Pp4vjNCTDzHn/hYqNs4hAoGAfuyWeELh8uudMYgbsPQC\nSBoXgY07yWbOoNDSoAN/7EToTK25/LdjN6BJhz654yQ8jQEyIWCHBbJnwqxfU0ZR\nHJBoJXqSD+xqnb8+FDNl1dDFvPEfAfOEFk7+QOoD8I8MSO43GwdWapF/oqJXOLL+\n4DHPRcTKm6sxvtpw7SB+eHY=\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-fbsvc@ecraftz-crm-mobapp.iam.gserviceaccount.com",
  "client_id": "101825892665051009122"
};

// ── Google OAuth2 token for FCM v1 API ────────────────────────────────────────
async function getGoogleAccessToken(): Promise<string> {
  let sa = SERVICE_ACCOUNT;
  const envSa = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
  if (envSa) {
    try {
      sa = JSON.parse(envSa);
    } catch (_) {
      // Use fallback SERVICE_ACCOUNT if env parse fails
    }
  }

  const header = { alg: "RS256", typ: "JWT" };
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };

  const encode = (obj: unknown) =>
    btoa(JSON.stringify(obj)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");

  const headerEncoded = encode(header);
  const payloadEncoded = encode(payload);
  const signingInput = `${headerEncoded}.${payloadEncoded}`;

  // Import private key (strip headers, footers, escaped newlines)
  const pemBody = sa.private_key
    .replace(/\\n/g, "\n")
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");

  const keyBuffer = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    keyBuffer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const encoder = new TextEncoder();
  const signatureBuffer = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    encoder.encode(signingInput)
  );
  const signature = btoa(String.fromCharCode(...new Uint8Array(signatureBuffer)))
    .replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");

  const jwt = `${signingInput}.${signature}`;

  // Exchange JWT for access token from Google OAuth2
  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  });

  const tokenData = await tokenResponse.json();
  if (!tokenData.access_token) {
    throw new Error(`Failed to get Google access token: ${JSON.stringify(tokenData)}`);
  }
  return tokenData.access_token;
}

// ── Send FCM notification to a single device ──────────────────────────────────
async function sendFcmNotification(
  accessToken: string,
  fcmToken: string,
  title: string,
  body: string,
  data: Record<string, string>
): Promise<void> {
  const url = `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`;

  const message = {
    message: {
      token: fcmToken,
      notification: { title, body },
      android: {
        priority: "high",
        notification: {
          channel_id: "ecraftz_leads_channel",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
      data,
    },
  };

  const res = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(message),
  });

  if (!res.ok) {
    const err = await res.text();
    console.error(`FCM send failed for token ${fcmToken.substring(0, 15)}...: ${err}`);
  } else {
    console.log(`FCM successfully sent to ${fcmToken.substring(0, 15)}...`);
  }
}

// ── Main handler ──────────────────────────────────────────────────────────────
Deno.serve(async (req: Request) => {
  try {
    let body: any = {};
    if (req.method === "POST") {
      try {
        body = await req.json();
      } catch (_) {}
    }

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL") || DEFAULT_SUPABASE_URL;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || 
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJuanZ1Z3h2Y29xZ2Z2dnZ3cHpjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MzMxMDg1MywiZXhwIjoyMDk4ODg2ODUzfQ.pS2JYB0U5HcuJbbEKwNVx3_5FyTnqhKy_beFoYlxbLI";
    const supabase = createClient(supabaseUrl, supabaseKey);

    const record = body.record || {};
    const leadName = record.name || record.lead_name || (record.first_name ? `${record.first_name} ${record.last_name || ''}`.trim() : (record.company || "New Lead"));
    
    // Helper to check if string is a UUID (e.g. b9044aa4-31b8-4bc6-a281-1a4f6efd7c33)
    const isUuid = (str: any) => typeof str === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(str.trim());

    let addedBy = "";
    if (record.created_by_name && !isUuid(record.created_by_name)) {
      addedBy = record.created_by_name;
    } else if (record.bde_name && !isUuid(record.bde_name)) {
      addedBy = record.bde_name;
    } else if (record.bde && !isUuid(record.bde)) {
      addedBy = record.bde;
    }

    const creatorId = record.created_by || record.user_id || record.assigned_to || record.bde;

    if (!addedBy && creatorId && isUuid(creatorId)) {
      try {
        const { data: creatorProfile } = await supabase
          .from("profiles")
          .select("full_name, name, email")
          .eq("id", creatorId)
          .maybeSingle();
        if (creatorProfile) {
          addedBy = creatorProfile.full_name || creatorProfile.name || creatorProfile.email || "";
        }
      } catch (e) {
        console.error("Profile lookup error:", e);
      }
    }

    // Final safety fallback: Never display raw UUID
    if (!addedBy || isUuid(addedBy)) {
      addedBy = "Keerthi";
    }

    const title = `🆕 New Lead Created`;
    const notifBody = `${leadName} was created by ${addedBy}`;


    console.log(`Processing lead notification: "${title}" - "${notifBody}"`);


    // Fetch all device tokens (Super Admin / Admin)
    const { data: tokens, error } = await supabase
      .from("device_tokens")
      .select("fcm_token");

    if (error) {
      console.error("Error fetching device tokens:", error.message);
      return new Response(`DB Error: ${error.message}`, { status: 500 });
    }

    if (!tokens || tokens.length === 0) {
      console.log("No device tokens found — no push notification sent.");
      return new Response(
        JSON.stringify({ success: false, reason: "No device tokens registered in database" }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    console.log(`Sending notification to ${tokens.length} device(s)`);

    // Get FCM access token
    const accessToken = await getGoogleAccessToken();

    // Send to all devices in parallel
    const results = await Promise.allSettled(
      tokens.map((row: { fcm_token: string }) =>
        sendFcmNotification(accessToken, row.fcm_token, title, notifBody, {
          type: "new_lead",
          lead_id: record.id?.toString() || "",
          lead_name: leadName,
          created_by: addedBy,

        })
      )
    );

    return new Response(
      JSON.stringify({ success: true, sent_to: tokens.length }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    console.error("Edge function error:", err);
    return new Response(`Internal error: ${err?.message || err}`, { status: 500 });
  }
});
