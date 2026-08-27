// Bynovix AI — Edge Function: Respond to Threat
// Real implementation: matches audit events to playbooks, creates threats,
// executes or queues security actions based on governance policies.
// Free-tier compatible: pure database operations.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const { audit_event_id, org_id } = await req.json();

    if (!audit_event_id || !org_id) {
      return new Response(
        JSON.stringify({ error: "audit_event_id and org_id are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 1. Fetch the audit event
    const { data: event, error: evtErr } = await supabase
      .from("audit_events")
      .select("*")
      .eq("id", audit_event_id)
      .single();

    if (evtErr || !event) {
      return new Response(
        JSON.stringify({ error: "Audit event not found", detail: evtErr?.message }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Fetch governance policies
    const { data: policies } = await supabase
      .from("org_policies")
      .select("*")
      .eq("organization_id", org_id)
      .single();

    const confidenceGate = policies?.ai_confidence_gate ?? 90;
    const requiresHumanApproval = policies?.critical_requires_human_approval ?? true;

    // 3. Find matching active playbooks by trigger event type
    const { data: playbooks } = await supabase
      .from("playbooks")
      .select("*")
      .eq("organization_id", org_id)
      .eq("is_active", true);

    // Match by trigger_event_type (if the event type matches a playbook trigger)
    const matchingPlaybooks = (playbooks || []).filter(
      (p) => !p.trigger_event_type || p.trigger_event_type === event.event_type || p.trigger_event_type === "any"
    );

    if (matchingPlaybooks.length === 0) {
      return new Response(
        JSON.stringify({
          success: true,
          message: "No matching playbooks for this event type",
          event_type: event.event_type,
          active_playbooks: playbooks?.length ?? 0,
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const results = [];

    for (const playbook of matchingPlaybooks) {
      // 4. Create threat record
      const { data: threat } = await supabase
        .from("threats")
        .insert({
          organization_id: org_id,
          title: `Threat detected: ${event.title || event.event_type}`,
          description: `Automated threat detection from audit event "${event.title}" via playbook "${playbook.name}".`,
          severity: event.severity || "medium",
          status: "investigating",
          source_audit_event_id: audit_event_id,
          confidence: playbook.auto_execute_threshold || confidenceGate,
        })
        .select()
        .single();

      if (!threat) continue;

      // 5. Create lineage: audit_event → threat
      await supabase.from("lineage_edges").insert({
        organization_id: org_id,
        source_entity_type: "audit_event",
        source_entity_id: audit_event_id,
        target_entity_type: "threat",
        target_entity_id: threat.id,
        edge_type: "triggered_by",
      });

      // 6. Create lineage: threat → playbook
      await supabase.from("lineage_edges").insert({
        organization_id: org_id,
        source_entity_type: "threat",
        source_entity_id: threat.id,
        target_entity_type: "playbook",
        target_entity_id: playbook.id,
        edge_type: "governed_by",
      });

      // 7. Evaluate: should we auto-execute?
      const threatConfidence = threat.confidence || 0;
      const shouldAutoExecute = threatConfidence >= (playbook.auto_execute_threshold || confidenceGate);
      const isCritical = event.severity === "critical" || event.severity === "high";
      const needsApproval = isCritical && requiresHumanApproval;

      if (shouldAutoExecute && !needsApproval) {
        // 8a. Execute security action directly
        const { data: secAction } = await supabase
          .from("security_actions")
          .insert({
            organization_id: org_id,
            threat_id: threat.id,
            playbook_id: playbook.id,
            action_type: "block_ip",
            status: "executed",
            executed_at: new Date().toISOString(),
            executed_by: "system",
          })
          .select()
          .single();

        if (secAction) {
          // Create lineage: playbook → security_action
          await supabase.from("lineage_edges").insert({
            organization_id: org_id,
            source_entity_type: "playbook",
            source_entity_id: playbook.id,
            target_entity_type: "security_action",
            target_entity_id: secAction.id,
            edge_type: "produced_by",
          });

          // 9. Create audit entry
          const { data: auditEntry } = await supabase
            .from("audit_entries")
            .insert({
              organization_id: org_id,
              security_action_id: secAction.id,
              action: `Security action executed: ${secAction.action_type}`,
              entity_type: "security_action",
              entity_id: secAction.id,
            })
            .select()
            .single();

          if (auditEntry) {
            // Create lineage: security_action → audit_entry
            await supabase.from("lineage_edges").insert({
              organization_id: org_id,
              source_entity_type: "security_action",
              source_entity_id: secAction.id,
              target_entity_type: "audit_entry",
              target_entity_id: auditEntry.id,
              edge_type: "recorded_in",
            });
          }

          // Update threat status
          await supabase
            .from("threats")
            .update({ status: "resolved" })
            .eq("id", threat.id);

          results.push({
            threat_id: threat.id,
            playbook: playbook.name,
            action: "auto_executed",
            security_action_id: secAction.id,
          });
        }
      } else {
        // 8b. Requires human approval — create approval request
        const { data: approval } = await supabase
          .from("approvals")
          .insert({
            organization_id: org_id,
            security_action_id: null,
            requester_id: null,
            decision: "pending",
            reason: needsApproval
              ? `Critical event requires human approval per governance policy`
              : `Confidence ${threatConfidence}% below auto-execute threshold`,
          })
          .select()
          .single();

        // Update threat status
        await supabase
          .from("threats")
          .update({ status: "pending_approval" })
          .eq("id", threat.id);

        results.push({
          threat_id: threat.id,
          playbook: playbook.name,
          action: "pending_approval",
          reason: needsApproval ? "critical_requires_human_approval" : "below_confidence_threshold",
        });
      }
    }

    // 10. Log audit event for the response (matches schema)
    await supabase.from("audit_events").insert({
      organization_id: org_id,
      event_type: "threat_response_executed",
      module: "Security",
      severity: "medium",
      status: "successful",
      change_payload: {
        source_event_id: audit_event_id,
        playbooks_matched: matchingPlaybooks.length,
        results,
      },
    });

    return new Response(
      JSON.stringify({
        success: true,
        audit_event_id,
        playbooks_matched: matchingPlaybooks.length,
        results,
        governance: {
          confidence_gate: confidenceGate,
          requires_human_approval: requiresHumanApproval,
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
