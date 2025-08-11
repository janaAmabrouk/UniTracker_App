import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

console.log("Function cold start");

serve(async (req) => {
  try {
    const { onesignal_id, title, body } = await req.json();
    console.log(`Received request for onesignal_id: ${onesignal_id}`);

    const onesignalAppId = Deno.env.get('ff8d1b56-045a-470c-bb92-4d0c921d0b56');
    const onesignalApiKey = Deno.env.get('os_v2_app_76grwvqeljdqzo4sjugjehilkzzhgomu4yuu4gmnzsumaqlnqpdtf6u4gqqwqmgotqv3tohiupm3ibkoyr6nxcztfrki4afl3hgyncy');

    if (!onesignalAppId || !onesignalApiKey) {
      console.error("OneSignal environment variables not set!");
      return new Response('Server configuration error', { status: 500 });
    }
    
    console.log("Sending notification to OneSignal API...");

    const response = await fetch('https://onesignal.com/api/v1/notifications', {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${onesignalApiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        app_id: onesignalAppId,
        include_player_ids: [onesignal_id],
        headings: { en: title },
        contents: { en: body }
      })
    });
    
    const responseBody = await response.json();
    console.log("OneSignal API Response:", JSON.stringify(responseBody));

    if (!response.ok) {
      console.error('Failed to send push:', response.status, responseBody);
      return new Response(JSON.stringify(responseBody), { status: response.status });
    }

    console.log("Push sent successfully!");
    return new Response(JSON.stringify(responseBody), { status: 200 });

  } catch (error) {
    console.error('Error processing request:', error);
    return new Response('Internal Server Error', { status: 500 });
  }
});