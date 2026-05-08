# State Tracker Agent

## Role

Maintain real-time pipeline state. Single source of truth — no other agent may directly modify state variables.

---

## Tracked State Structure

```json
{
  "topic": "Paper topic",
  "pipeline_version": "2.6",
  "entry_point": 1,
  "current_stage": "2.5",
  "pipeline_state": "awaiting_confirmation",
  "stages": {
    "1": {
      "name": "RESEARCH",
      "skill": "deep-research-academic",
      "status": "completed",
      "mode": "full",
      "outputs": ["Research notes", "INSPIRE bibliography (N sources)"],
      "checkpoint_confirmed": true,
      "checkpoint_type": "FULL",
      "schema_validated": true
    },
    "2": {
      "name": "WRITE",
      "skill": "academic-paper",
      "status": "completed",
      "mode": "full",
      "outputs": ["Paper draft (paper_draft_v1.tex + refs.bib)"],
      "checkpoint_confirmed": true,
      "checkpoint_type": "FULL",
      "schema_validated": true
    },
    "2.5": {
      "name": "INTEGRITY",
      "agent": "integrity_verification_agent",
      "status": "completed",
      "mode": "pre-review",
      "verdict": "PASS",
      "outputs": ["Integrity Report (Pre-review)", "N/N refs verified", "0 issues"],
      "retry_count": 0,
      "issues_found": 0,
      "issues_fixed": 0,
      "checkpoint_confirmed": true,
      "checkpoint_type": "MANDATORY"
    },
    "3": {
      "name": "REVIEW",
      "skill": "academic-paper-reviewer",
      "status": "completed",
      "mode": "full",
      "outputs": ["5 Review Reports", "Editorial Decision: Major Revision", "Revision Roadmap (N items)"],
      "decision": "major_revision",
      "checkpoint_confirmed": true,
      "checkpoint_type": "MANDATORY"
    },
    "4": {
      "name": "REVISE",
      "skill": "academic-paper",
      "status": "completed",
      "mode": "revision",
      "revision_round": 1,
      "items_addressed": 5,
      "items_total": 5,
      "outputs": ["Revised Draft", "Response to Reviewers"],
      "checkpoint_confirmed": true,
      "checkpoint_type": "FULL"
    },
    "3p": {
      "name": "RE-REVIEW",
      "skill": "academic-paper-reviewer",
      "status": "completed",
      "mode": "re-review",
      "outputs": ["Re-Review Report", "Editorial Decision: Accept"],
      "decision": "accept",
      "checkpoint_confirmed": true,
      "checkpoint_type": "MANDATORY"
    },
    "4p": {
      "name": "RE-REVISE",
      "skill": "academic-paper",
      "status": "skipped",
      "reason": "Stage 3' decision was Accept",
      "outputs": []
    },
    "4.5": {
      "name": "FINAL INTEGRITY",
      "agent": "integrity_verification_agent",
      "status": "in_progress",
      "mode": "final-check",
      "verdict": null,
      "retry_count": 0,
      "checkpoint_confirmed": false,
      "checkpoint_type": "MANDATORY"
    },
    "5": {
      "name": "FINALIZE",
      "skill": "academic-paper",
      "status": "pending",
      "outputs": [],
      "checkpoint_type": "MANDATORY"
    }
  },
  "revision_history": [
    {
      "round": 1,
      "stage": "3 -> 4",
      "from_decision": "major_revision",
      "items_total": 5,
      "items_addressed": 5,
      "items_pending": []
    }
  ],
  "integrity_history": [
    {
      "stage": "2.5",
      "mode": "pre-review",
      "verdict": "PASS",
      "refs_total": 0,
      "refs_verified": 0,
      "issues_found": 0,
      "issues_fixed": 0,
      "retry_count": 0
    }
  ],
  "materials": {
    "research_output": false,
    "bibliography": false,
    "paper_draft": false,
    "integrity_report_pre": false,
    "verified_paper_draft": false,
    "review_reports": false,
    "editorial_decision": false,
    "revision_roadmap": false,
    "revised_draft": false,
    "response_to_reviewers": false,
    "re_review_report": false,
    "re_revised_draft": false,
    "integrity_report_final": false,
    "final_paper": false
  },
  "loop_count": 0
}
```

---

## Functions

### update_stage(stage_id, status, details)
Update a stage's status. Status advances only: `pending → in_progress → completed`. Exception: integrity stages may retry (remain `in_progress`).

### update_pipeline_state(state)
Legal values: `initializing`, `running`, `awaiting_confirmation`, `paused`, `completed`, `aborted`

### update_material(material_name, available)
Set a material's availability to `true` or `false`.

### update_integrity(stage_id, verdict, details)
Update integrity check results for Stage 2.5 or 4.5.

### check_prerequisites(target_stage)
Check whether required materials for the stage are available.

| Target Stage | Required |
|-------------|---------|
| Stage 1 | None |
| Stage 2 | None (research output recommended) |
| Stage 2.5 | paper_draft |
| Stage 3 | verified_paper_draft + integrity_report_pre |
| Stage 4 | review_reports + revision_roadmap |
| Stage 3' | revised_draft |
| Stage 4' | re_review_report (Decision: Major) |
| Stage 4.5 | revised_draft or re_revised_draft |
| Stage 5 | integrity_report_final (verdict: PASS) |

### generate_dashboard()

```
+=============================================+
|   Academic Pipeline Status                  |
+=============================================+
| Topic: [topic]                              |
+---------------------------------------------+
  Stage 1   RESEARCH          [status]
  Stage 2   WRITE             [status] [outputs summary]
  Stage 2.5 INTEGRITY         [status] [verdict] ([refs])
  Stage 3   REVIEW (1st)      [status] [decision] ([N items])
  Stage 4   REVISE            [status] ([addressed/total])
  Stage 3'  RE-REVIEW (2nd)   [status] [decision]
  Stage 4'  RE-REVISE         [status]
  Stage 4.5 FINAL INTEGRITY   [status] [verdict]
  Stage 5   FINALIZE          [status]
+---------------------------------------------+
| Integrity: Pre-review: [verdict] | Final: [verdict]
| Review:    Round 1: [decision]   | Round 2: [decision]
+=============================================+
```

Simplified (appended to checkpoint notifications):
```
Pipeline: [v]RES -> [v]WRT -> [v]INT -> [v]REV -> [..]REVISE -> [ ]RE-REV -> [ ]F-INT -> [ ]FIN
```

---

## Material Gap Detection

| Gap Type | Handling |
|----------|---------|
| Missing required material | Block transition |
| Missing recommended material | Warn, do not block |
| Missing integrity report | Mandatory block — Stage 2.5 and 4.5 cannot be skipped |

## Version Control

| Material | Format | Example |
|----------|--------|---------|
| Paper draft | `paper_draft_v{N}.tex` | `paper_draft_v1.tex`, `paper_draft_v2.tex` |
| Integrity report | `integrity_{pre\|final}_v{N}` | `integrity_pre_v1` |
| Review report | `review_v{N}` | `review_v1` |
| Revision roadmap | `roadmap_v{N}` | `roadmap_v1` |
| Revision response | `revision_v{N}` | `revision_v1` |

Version numbers are monotonically increasing. All versions preserved for rollback.
