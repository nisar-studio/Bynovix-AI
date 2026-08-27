// Bynovix AI — Edge Function: Generate AI Insight
// Real implementation: analyzes analytical results, computes confidence,
// creates insight with lineage, checks governance policies.
// Free-tier compatible: local scoring, no Groq dependency.
// Groq integration will be added in Phase 9.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

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
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

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

    // 2. Determine confidence score
    let confidence = input.confidence ?? 0;
    if (input.analytical_result_id && !input.confidence) {
      // Compute confidence from analytical result metrics
      const { data: result } = await supabase
        .from("analytical_results")
        .select("*")
        .eq("id", input.analytical_result_id)
        .single();

      if (result?.metrics) {
        const metrics = typeof result.metrics === "string"
          ? JSON.parse(result.metrics)
          : result.metrics;

        // Local confidence scoring: based on data completeness and variance
        const completeness = metrics.data_completeness || 85;
        const variance = metrics.variance_percent || 0;
        const sampleSize = metrics.sample_size || 1000;

        // Higher confidence with more data, higher variance, better completeness
        confidence = Math.min(99, Math.round(
          (completeness * 0.3) +
          (Math.min(Math.abs(variance) * 2, 40)) +
          (Math.min(sampleSize / 100, 30))
        ));
      }
    }

    // 3. Enforce governance: confidence gate
    if (confidence < confidenceGate) {
      return new Response(
        JSON.stringify({
          success: false,
          message: `Confidence ${confidence}% is below governance gate of ${confidenceGate}%. Insight not created.`,
          confidence,
          confidence_gate: confidenceGate,
          governance_blocked: true,
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 4. Enforce governance: explainability
    if (explainabilityRequired && !input.explanation) {
      return new Response(
        JSON.stringify({
          success: false,
          message: "Explainability required by governance policy but no explanation provided.",
          governance_blocked: true,
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 5. Create the insight
    const insightData = {
      organization_id: input.org_id,
      title: input.title || "AI-Generated Insight",
      type: input.type || "anomaly",
      severity: input.severity || (confidence >= 95 ? "critical" : confidence >= 85 ? "high" : "medium"),
      confidence,
      explanation: input.explanation || `Automated insight generated from analytical data. Confidence: ${confidence}%`,
      status: "active",
      source_data: input.source_data || {},
      supporting_metrics: input.supporting_metrics || {},
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

    // 6. Create lineage edge if analytical_result provided
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

    // 7. Log audit event
    await supabase.from("audit_events").insert({
      organization_id: input.org_id,
      event_type: "insight_generated",
      title: `AI Insight created: ${insight.title}`,
      severity: insight.severity === "critical" ? "high" : "low",
      module: "AI Insights",
      metadata: {
        insight_id: insight.id,
        confidence,
        confidence_gate: confidenceGate,
        type: insight.type,
      },
    });

    return new Response(
      JSON.stringify({
        success: true,
        insight,
        governance: {
          confidence_gate: confidenceGate,
          confidence_met: confidence >= confidenceGate,
          explainability_required: explainabilityRequired,
          explanation_provided: !!input.explanation,
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
