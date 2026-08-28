// Bynovix AI — Edge Function: Generate AI Insight
// Phase 9: Groq AI integration with fallback to local scoring.
// When GROQ_API_KEY is configured, uses Groq LLM for intelligent insight generation.
// When not configured, falls back to existing local confidence scoring.
// All governance controls are enforced regardless of insight source.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// ─── Groq Configuration ────────────────────────────────────────────
const GROQ_ENDPOINT = "https://api.groq.com/openai/v1/chat/completions";
const GROQ_MODEL = "qwen/qwen3.8-27b"; // Free-tier: qwen3.8-27b supports JSON mode on Groq

interface InsightInput {
  analytical_result_id?: string;
  org_id: string;
  title?: string;
  type?: string;
  severity?: string;
  explanation?: string;
  source_data?: Record<string, unknown>;
  supporting_metrics?: Record<string, unknown>;
  confidence?: number;
  use_groq?: boolean; // opt-in to Groq AI generation
}

interface GroqInsightResponse {
  title: string;
  type: string;
  severity: string;
  confidence: number;
  explanation: string;
  supporting_evidence: string[];
  recommended_actions: string[];
  risk_factors: string[];
}

// ─── Groq AI Generation ────────────────────────────────────────────
async function generateWithGroq(
  apiKey: string,
  analyticalData: Record<string, unknown>,
  orgPolicies: Record<string, unknown>
): Promise<GroqInsightResponse | null> {
  try {
    const systemPrompt = `You are an enterprise AI analytics engine for Bynovix AI, an enterprise intelligence platform.
You analyze business data and produce structured insights with high confidence.

RESPONSE FORMAT: You MUST respond with valid JSON only. No markdown, no explanation outside JSON.

Schema:
{
  "title": "string — concise insight title (max 80 chars)",
  "type": "one of: anomaly, trend, risk, opportunity, recommendation, forecast_deviation",
  "severity": "one of: critical, high, medium, low",
  "confidence": number 0-100,
  "explanation": "string — 2-3 sentence explanation of the insight with reasoning",
  "supporting_evidence": ["string array of supporting data points"],
  "recommended_actions": ["string array of suggested next steps"],
  "risk_factors": ["string array of risks or caveats"]
}

RULES:
- confidence must be based on data quality, sample size, and statistical significance
- severity must reflect business impact: critical=immediate revenue loss, high=significant, medium=notable, low=informational
- explanation must reference specific data points from the input
- Never fabricate data — only reference what is provided in the analytical context
- Be concise and actionable`;

    const userPrompt = `Analyze the following business data and produce a structured insight:

ANALYTICAL DATA:
${JSON.stringify(analyticalData, null, 2)}

ORGANIZATION GOVERNANCE:
- AI Confidence Gate: ${orgPolicies.ai_confidence_gate || 90}%
- Explainability Required: ${orgPolicies.explainability_required !== false}
- Required insight types: anomaly, trend, risk, opportunity, recommendation, forecast_deviation

Produce a single JSON insight object based on this data.`;

    const response = await fetch(GROQ_ENDPOINT, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: GROQ_MODEL,
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userPrompt },
        ],
        temperature: 0.3,
        max_completion_tokens: 1024,
        response_format: { type: "json_object" },
      }),
    });

    if (!response.ok) {
      console.error(`Groq API error: ${response.status} ${response.statusText}`);
      return null;
    }

    const data = await response.json();
    const content = data.choices?.[0]?.message?.content;

    if (!content) {
      console.error("Groq returned empty content");
      return null;
    }

    // Parse the JSON response — Groq with json_object mode returns valid JSON
    const parsed = JSON.parse(content) as GroqInsightResponse;

    // Validate required fields
    if (!parsed.title || typeof parsed.confidence !== "number") {
      console.error("Groq response missing required fields:", Object.keys(parsed));
      return null;
    }

    // Clamp confidence to valid range
    parsed.confidence = Math.max(0, Math.min(100, Math.round(parsed.confidence)));

    return parsed;
  } catch (err) {
    console.error("Groq generation failed:", err.message);
    return null;
  }
}

// ─── Local Confidence Scoring (fallback) ───────────────────────────
function computeLocalConfidence(metrics: Record<string, unknown>): number {
  const completeness = (metrics.data_completeness as number) || 85;
  const variance = (metrics.variance_percent as number) || 0;
  const sampleSize = (metrics.sample_size as number) || 1000;

  return Math.min(
    99,
    Math.round(
      completeness * 0.3 +
        Math.min(Math.abs(variance) * 2, 40) +
        Math.min(sampleSize / 100, 30)
    )
  );
}

// ─── Main Handler ──────────────────────────────────────────────────
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
    const groqAvailable = !!groqApiKey;

    const input: InsightInput = await req.json();

    if (!input.org_id) {
      return new Response(
        JSON.stringify({ error: "org_id is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 1. Fetch governance policies
    const { data: policies } = await supabase
      .from("org_policies")
      .select("*")
      .eq("organization_id", input.org_id)
      .single();

    const confidenceGate = policies?.ai_confidence_gate ?? 90;
    const explainabilityRequired = policies?.explainability_required ?? true;

    // 2. Fetch analytical result context (if provided)
    let analyticalResult: Record<string, unknown> | null = null;
    if (input.analytical_result_id) {
      const { data: result } = await supabase
        .from("analytical_results")
        .select("*")
        .eq("id", input.analytical_result_id)
        .single();
      analyticalResult = result;
    }

    // 3. Determine insight generation method
    let insightSource: "groq" | "local" = "local";
    let groqInsight: GroqInsightResponse | null = null;
    let confidence = input.confidence ?? 0;

    // Try Groq if: API key available AND caller opted in OR analytical data provided
    if (groqAvailable && (input.use_groq || input.analytical_result_id)) {
      const analyticalContext = analyticalResult
        ? {
            ...(typeof analyticalResult.metrics === "string"
              ? JSON.parse(analyticalResult.metrics)
              : analyticalResult.metrics || {}),
            title: analyticalResult.title,
            description: analyticalResult.description,
            result_type: analyticalResult.result_type,
          }
        : input.source_data || {};

      groqInsight = await generateWithGroq(groqApiKey, analyticalContext, policies || {});

      if (groqInsight) {
        insightSource = "groq";
        confidence = groqInsight.confidence;
      }
    }

    // Fallback to local scoring if Groq not used or failed
    if (insightSource === "local") {
      if (input.analytical_result_id && analyticalResult) {
        const metrics =
          typeof analyticalResult.metrics === "string"
            ? JSON.parse(analyticalResult.metrics)
            : (analyticalResult as Record<string, unknown>).metrics || {};
        confidence = computeLocalConfidence(metrics as Record<string, unknown>);
      }
    }

    // 4. Enforce governance: confidence gate
    if (confidence < confidenceGate) {
      return new Response(
        JSON.stringify({
          success: false,
          message: `Confidence ${confidence}% is below governance gate of ${confidenceGate}%. Insight not created.`,
          confidence,
          confidence_gate: confidenceGate,
          governance_blocked: true,
          insight_source: insightSource,
          groq_available: groqAvailable,
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 5. Build insight data from Groq or local
    let title: string;
    let type: string;
    let severity: string;
    let explanation: string;
    let sourceData: Record<string, unknown>;
    let supportingMetrics: Record<string, unknown>;

    if (groqInsight) {
      title = groqInsight.title;
      type = groqInsight.type || "anomaly";
      severity = groqInsight.severity || (confidence >= 95 ? "critical" : confidence >= 85 ? "high" : "medium");
      explanation = groqInsight.explanation;
      sourceData = {
        groq_model: GROQ_MODEL,
        supporting_evidence: groqInsight.supporting_evidence,
        recommended_actions: groqInsight.recommended_actions,
        risk_factors: groqInsight.risk_factors,
        ...(input.source_data || {}),
      };
      supportingMetrics = {
        groq_confidence: groqInsight.confidence,
        groq_severity: groqInsight.severity,
        ...(input.supporting_metrics || {}),
      };
    } else {
      title = input.title || "AI-Generated Insight";
      type = input.type || "anomaly";
      severity = input.severity || (confidence >= 95 ? "critical" : confidence >= 85 ? "high" : "medium");
      explanation =
        input.explanation ||
        `Automated insight generated from analytical data. Confidence: ${confidence}%`;
      sourceData = input.source_data || {};
      supportingMetrics = input.supporting_metrics || {};
    }

    // 6. Enforce governance: explainability
    if (explainabilityRequired && !explanation) {
      return new Response(
        JSON.stringify({
          success: false,
          message:
            "Explainability required by governance policy but no explanation provided.",
          governance_blocked: true,
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 7. Create the insight
    const insightData = {
      organization_id: input.org_id,
      title,
      type,
      severity,
      confidence,
      explanation,
      status: "active",
      source_data: sourceData,
      supporting_metrics: supportingMetrics,
    };

    const { data: insight, error: insErr } = await supabase
      .from("insights")
      .insert(insightData)
      .select()
      .single();

    if (insErr) {
      return new Response(
        JSON.stringify({ error: "Failed to create insight", detail: insErr.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 8. Create lineage edge if analytical_result provided
    if (input.analytical_result_id && insight) {
      await supabase.from("lineage_edges").insert({
        organization_id: input.org_id,
        source_entity_type: "analytical_result",
        source_entity_id: input.analytical_result_id,
        target_entity_type: "insight",
        target_entity_id: insight.id,
        edge_type: "derived_from",
      });
    }

    // 9. Log audit event
    await supabase.from("audit_events").insert({
      organization_id: input.org_id,
      event_type: "insight_generated",
      module: "AI Insights",
      severity: insight.severity === "critical" ? "high" : "low",
      status: "successful",
      change_payload: {
        insight_id: insight.id,
        confidence,
        confidence_gate: confidenceGate,
        type: insight.type,
        insight_source: insightSource,
        groq_available: groqAvailable,
      },
    });

    return new Response(
      JSON.stringify({
        success: true,
        insight,
        insight_source: insightSource,
        groq_available: groqAvailable,
        governance: {
          confidence_gate: confidenceGate,
          confidence_met: confidence >= confidenceGate,
          explainability_required: explainabilityRequired,
          explanation_provided: !!explanation,
        },
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
