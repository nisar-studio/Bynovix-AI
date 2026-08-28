// Bynovix AI — Edge Function: AI Analyst Chat
// Accepts a natural language question, enriches it with business context from the database,
// and returns a structured AI response via Groq. No confidence gate — this is a Q&A interface.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const GROQ_ENDPOINT = "https://api.groq.com/openai/v1/chat/completions";
const GROQ_MODEL = "qwen/qwen3.8-27b";

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const groqApiKey = Deno.env.get("GROQ_API_KEY") ?? "";

    if (!groqApiKey) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "AI is not configured. Groq API key is not set.",
          response: "I'm sorry, the AI service is not currently available. Please try again later.",
          source: "fallback"
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    let body: any;
    try {
      body = await req.json();
    } catch (e) {
      return new Response(
        JSON.stringify({ success: false, error: "Invalid JSON body" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const question: string = body.question || "";
    const orgId: string = body.org_id || "";

    if (!question.trim()) {
      return new Response(
        JSON.stringify({ success: false, error: "question is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!orgId) {
      return new Response(
        JSON.stringify({ success: false, error: "org_id is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // ─── Gather Business Context ──────────────────────────────────
    let forecasts: any[] = [];
    let insights: any[] = [];
    let actions: any[] = [];
    let sources: any[] = [];
    let analytics: any[] = [];

    try {
      const [f, i, a, s, an] = await Promise.all([
        supabase.from("forecasts").select("forecast_value, confidence, period, scenario, forecast_type").eq("organization_id", orgId).limit(5),
        supabase.from("insights").select("title, type, severity, confidence, explanation, status").eq("organization_id", orgId).limit(10),
        supabase.from("actions").select("title, description, priority, status, expected_impact").eq("organization_id", orgId).limit(5),
        supabase.from("source_connections").select("name, type, status, records_count").eq("organization_id", orgId).limit(5),
        supabase.from("analytical_results").select("title, result_type, description, metrics").eq("organization_id", orgId).limit(5),
      ]);
      forecasts = f.data || [];
      insights = i.data || [];
      actions = a.data || [];
      sources = s.data || [];
      analytics = an.data || [];
    } catch (e) {
      console.warn("Context gathering partial failure:", e);
    }

    const totalRecords = sources.reduce((sum: number, s: any) => sum + (s.records_count || 0), 0);

    // ─── Build Groq Prompt ────────────────────────────────────────
    const contextStr = JSON.stringify({
      forecasts: forecasts.slice(0, 5),
      insights: insights.slice(0, 10),
      actions: actions.slice(0, 5),
      data_sources: sources.slice(0, 5),
      analytics: analytics.slice(0, 5),
    });

    const systemPrompt = `You are the AI Analyst for Bynovix AI, an enterprise intelligence platform.
You answer business questions using the company's actual data provided below.
Be concise, specific, and reference actual numbers from the data.
Use a professional, analytical tone. Structure responses with clear sections.
If the data doesn't contain enough information to answer, say so honestly.
Always reference specific data points, not generic statements.

CURRENT BUSINESS DATA:
- Total processed records: ${(totalRecords / 1e6).toFixed(1)}M
- Forecasts: ${forecasts.map((f: any) => `$${(f.forecast_value / 1e6).toFixed(1)}M (${f.confidence}%, ${f.period || "N/A"})`).join(", ")}
- Active insights: ${insights.map((i: any) => `${i.title} [${i.severity}, ${i.confidence}%]`).join(", ")}
- Actions: ${actions.map((a: any) => `${a.title} [${a.priority}, ${a.status}]`).join(", ")}
- Data sources: ${sources.map((s: any) => `${s.name} (${s.status}, ${s.records_count} records)`).join(", ")}
- Analytics: ${analytics.map((a: any) => `${a.title} (${a.result_type})`).join(", ")}

GOVERNANCE:
- AI Confidence Gate: 90%
- Explainability: Required
- Always explain your reasoning`;

    // ─── Call Groq ────────────────────────────────────────────────
    const startTime = Date.now();
    const response = await fetch(GROQ_ENDPOINT, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${groqApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: GROQ_MODEL,
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: question },
        ],
        temperature: 0.4,
        max_completion_tokens: 1024,
      }),
    });

    const latencyMs = Date.now() - startTime;

    if (!response.ok) {
      const errText = await response.text();
      console.error(`Groq API error: ${response.status} ${errText}`);
      return new Response(
        JSON.stringify({
          success: false,
          error: `AI service error: ${response.status}`,
          response: "I encountered an error processing your question. Please try again.",
          source: "error"
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const data = await response.json();
    const aiResponse = data.choices?.[0]?.message?.content || "No response generated.";

    // ─── Log audit event ──────────────────────────────────────────
    try {
      await supabase.from("audit_events").insert({
        organization_id: orgId,
        event_type: "ai_chat_query",
        module: "AI Analyst",
        severity: "low",
        status: "successful",
        change_payload: {
          question: question.substring(0, 200),
          model: GROQ_MODEL,
          latency_ms: latencyMs,
          tokens_used: data.usage?.total_tokens || 0,
        },
      });
    } catch (e) {
      console.warn("Audit log failed:", e);
    }

    return new Response(
      JSON.stringify({
        success: true,
        response: aiResponse,
        source: "groq",
        model: GROQ_MODEL,
        latency_ms: latencyMs,
        tokens_used: data.usage?.total_tokens || 0,
        context_summary: {
          forecasts: forecasts.length,
          insights: insights.length,
          actions: actions.length,
          sources: sources.length,
        },
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error: any) {
    console.error("chat-ask error:", error);
    return new Response(
      JSON.stringify({ success: false, error: error.message || String(error), response: "An unexpected error occurred." }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
