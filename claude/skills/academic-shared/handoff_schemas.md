# Handoff Schemas — Cross-Skill Data Contracts

Defines the data structures passed between pipeline stages. Consuming agents validate input on receipt and request re-generation if required fields are missing.

**Convention**: Structured Markdown output. Missing required fields trigger `HANDOFF_INCOMPLETE`.

---

## Schema 1: Research Output (deep-research-academic → academic-paper)

**Producer**: `deep-research-academic`  
**Consumer**: `academic-paper/intake_agent`

### Required Fields

| Field | Description |
|-------|-------------|
| `research_question` | The finalized research question or problem statement |
| `key_references` | Annotated list of core papers (INSPIRE keys + arXiv IDs) |
| `bibliography` | BibTeX entries in INSPIRE format (`Author:YEARabc`) |
| `coverage_assessment` | Self-assessment of literature completeness |

### Optional Fields

| Field | Description |
|-------|-------------|
| `open_questions` | Identified gaps or open problems in the literature |
| `calculation_notes` | Key equations or results from reviewed papers |

---

## Schema 2: Paper Draft (academic-paper → integrity / reviewer)

**Producer**: `academic-paper/draft_writer_agent`  
**Consumer**: `integrity_verification_agent`, `academic-paper-reviewer/*`

### Required Fields

| Field | Description |
|-------|-------------|
| `title` | Paper title |
| `abstract` | Abstract text |
| `sections` | Ordered list of sections with headings and content |
| `references` | Full BibTeX reference list (INSPIRE format) |
| `total_word_count` | Word count excluding references |
| `structure_type` | `hep-th` / `econophysics` / `IMRaD` |
| `target_journal` | JHEP / SciPost Physics / PRD / PRL / PRE / PTEP / other |
| `documentclass` | LaTeX documentclass used (jheppub, revtex4-2, etc.) |

### Section Object

| Field | Description |
|-------|-------------|
| `heading` | Section heading |
| `level` | Heading level (1–4) |
| `content` | Full section LaTeX source |
| `word_count` | Word count for this section |
| `citation_count` | Number of in-text citations |

### Reference Object

| Field | Description |
|-------|-------------|
| `inspire_key` | INSPIRE key: `Author:YEARabc` |
| `arxiv_id` | arXiv ID (mandatory for preprints) |
| `doi` | DOI (mandatory for published papers) |
| `full_bibtex` | Complete BibTeX entry |
| `cited_in_sections` | Section headings where this reference is cited |

---

## Schema 3: Integrity Report (integrity_verification_agent → pipeline)

**Producer**: `integrity_verification_agent`  
**Consumer**: `pipeline_orchestrator_agent`

### Required Fields

| Field | Description |
|-------|-------------|
| `verdict` | `PASS` / `PASS_WITH_CONDITIONS` / `FAIL` |
| `mode` | `pre-review` / `final-check` |
| `refs_checked` | Total references checked |
| `refs_verified` | References passing Phase A |
| `issues` | Object: `{SERIOUS: int, MEDIUM: int, MINOR: int}` |
| `citation_integrity_score` | 0.0–1.0 |
| `timestamp` | ISO 8601 |

---

## Schema 4: Review Report (academic-paper-reviewer → pipeline)

**Producer**: `academic-paper-reviewer/editorial_synthesizer_agent`  
**Consumer**: `pipeline_orchestrator_agent`, `academic-paper/draft_writer_agent`

### Required Fields

| Field | Description |
|-------|-------------|
| `editorial_decision` | `Accept` / `Minor Revision` / `Major Revision` / `Reject` |
| `reviewer_reports` | List of individual review reports (EIC, R1, R2, R3, DA) |
| `consensus` | `CONSENSUS-4` / `CONSENSUS-3` / `SPLIT` / `DA-CRITICAL` |
| `revision_roadmap` | Prioritized list of required changes (Schema 5) |

### ReviewerReport Object

| Field | Description |
|-------|-------------|
| `reviewer_id` | `EIC`, `R1`, `R2`, `R3`, `DA` |
| `role` | Reviewer identity description |
| `recommendation` | Accept / Minor Revision / Major Revision / Reject |
| `confidence_score` | 1–5 |
| `strengths` | List of identified strengths |
| `weaknesses` | List of Weakness objects |
| `questions` | Questions for the authors |

### Weakness Object

| Field | Description |
|-------|-------------|
| `description` | What the weakness is |
| `severity` | `critical` / `major` / `minor` |
| `type` | `technique` / `domain` / `writing` / `structure` / `novelty` |

---

## Schema 5: Revision Roadmap (reviewer → academic-paper revision)

**Producer**: `academic-paper-reviewer/editorial_synthesizer_agent`  
**Consumer**: `academic-paper/draft_writer_agent`, `pipeline_orchestrator_agent`

### Required Fields

| Field | Description |
|-------|-------------|
| `items` | Ordered list of RoadmapItem objects |
| `total_items` | Total count |
| `must_fix_count` | Count of `must_fix` priority items |
| `editorial_decision` | Decision from Schema 4 |
| `consensus_summary` | Summary of reviewer consensus |

### RoadmapItem Object

| Field | Description |
|-------|-------------|
| `id` | Unique ID, e.g. `REV-001` |
| `description` | What needs to change |
| `reviewer` | Which reviewer(s) raised this |
| `type` | `Major` / `Minor` / `Editorial` |
| `priority` | `must_fix` / `should_fix` / `consider` |
| `target_section` | Section of the paper to modify |
| `suggested_action` | How to address |
| `consensus_level` | `CONSENSUS-4` / `CONSENSUS-3` / `SPLIT` / `DA-CRITICAL` |
| `verification_criteria` | How to confirm the fix is adequate |

---

## Schema 6: Response to Reviewers (academic-paper → re-review)

**Producer**: `academic-paper/draft_writer_agent` (revision mode)  
**Consumer**: `academic-paper-reviewer/editorial_synthesizer_agent`

### Required Fields

| Field | Description |
|-------|-------------|
| `revision_round` | Which revision round (1, 2, …) |
| `items` | List of ResponseItem objects |
| `summary` | `{resolved: int, limitations: int, unresolvable: int, disagreed: int}` |
| `word_count_delta` | Net word count change |
| `new_references_added` | Count of new BibTeX entries added |
| `summary_of_changes` | High-level summary |

### ResponseItem Object

| Field | Description |
|-------|-------------|
| `roadmap_item_id` | Matches RoadmapItem.id |
| `reviewer_comment` | Original comment (quoted) |
| `author_response` | Detailed response |
| `change_location` | Section + paragraph where change was made |
| `status` | `RESOLVED` / `DELIBERATE_LIMITATION` / `UNRESOLVABLE` / `REVIEWER_DISAGREE` |
| `decline_justification` | Required if status is not RESOLVED; must cite evidence |

---

## Schema 7: Material Passport (cross-stage metadata)

Accompanies every artifact as it passes between stages.

### Required Fields

| Field | Description |
|-------|-------------|
| `origin_skill` | Which skill produced this artifact |
| `origin_mode` | Which mode was used |
| `origin_date` | ISO 8601 timestamp |
| `verification_status` | `VERIFIED` / `UNVERIFIED` / `STALE` |
| `version_label` | e.g. `paper_draft_v1`, `paper_draft_v2` |

### Optional Fields

| Field | Description |
|-------|-------------|
| `integrity_pass_date` | ISO 8601 timestamp of last integrity pass |
| `upstream_dependencies` | Version labels of artifacts this one depends on |

---

## Schema 8: R&R Traceability Matrix (re-review)

**Producer**: `academic-paper-reviewer` (re-review mode)  
**Consumer**: `academic-paper` (revision mode, if further revision needed), `pipeline_orchestrator_agent`

Maps every reviewer concern through the full revision cycle.

### Required Fields per Item

| Field | Description |
|-------|-------------|
| `concern_id` | Unique ID (R1, R2, S1, …) |
| `priority` | `MUST_FIX` / `SHOULD_FIX` / `CONSIDER` |
| `original_comment` | Reviewer's original concern text |
| `authors_claim` | What the author states they did |
| `revision_location` | Section/paragraph reference in revised manuscript |
| `verified` | `YES` ✅ / `PARTIAL` ⚠️ / `NO` ❌ / `CANNOT_VERIFY` 🔍 |
| `status` | `FULLY_ADDRESSED` / `PARTIALLY_ADDRESSED` / `NOT_ADDRESSED` / `MADE_WORSE` |
| `quality_assessment` | Free-text evaluation |

### Validation

- Every item from the original Revision Roadmap (Schema 5) must appear in the matrix
- `authors_claim` cannot be empty for MUST_FIX items (flag as `CANNOT_VERIFY` if missing)

---

## Validation Rules

1. All required fields must be present — missing fields return `HANDOFF_INCOMPLETE`
2. Enum fields must use allowed values
3. Cross-references must resolve (e.g. ResponseItem.roadmap_item_id must match a RoadmapItem.id)
4. Every artifact must carry a Material Passport (Schema 7) with a version label
5. Version labels are monotonically increasing within a pipeline run
6. Artifacts that passed integrity verification must have `verification_status: VERIFIED` and `integrity_pass_date` set
7. If an upstream artifact is modified after a downstream artifact was produced, mark downstream as `STALE`
8. Stage 2.5 and Stage 4.5 integrity checks can never be skipped regardless of passport status
