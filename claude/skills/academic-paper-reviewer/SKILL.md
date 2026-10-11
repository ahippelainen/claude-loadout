---
name: academic-paper-reviewer
description: "Simulates the review a manuscript would get at a named journal: an editor's desk screen and two referee reports, each written by a separate fresh-context opus subagent, then the editor's decision letter with must-address and optional points tied to locations in the paper. Written the way referees in hep-th/hep-ph and in economics write; no scores or acceptance probabilities; venue fit judged only from evidence. Modes: full (default), desk, re-review, calibrate; a devil's-advocate referee only on request. Never edits the manuscript. Triggers: referee my paper, simulate peer review, mock referee report, what would the referees say, pre-submission review, would the editor send this out, re-review my revision. Do NOT trigger for: checking a calculation or derivation, 'check my calculation', 'sanity check this' (physics-review); answering real referee reports (academic-paper, response mode); choosing a journal (journal-picker agent); pressure-testing an economic model before it is written up (academic-economist agent); proofreading."
---

# academic-paper-reviewer

Tells the author what a real editor and real referees at the target journal would plausibly say, so he can fix it before they do. The failure this skill exists to avoid is a simulation harsher, longer and more confident than real review: manufactured objections, lists padded to a quota, numeric acceptance odds, and venue verdicts without evidence. (A simulated editor once reported "high confidence on venue fit" and an 85% chance of acceptance after minor revision for a paper the real journal then desk-rejected as out of scope.)

A simulated report is an opinion. Nothing in it counts as checked unless the report shows the check.

## Rules for every role

1. **Read-only.** No role edits the manuscript or any file of the author's. Subagents write nothing; the main session saves their reports under `LLM/<YYMMDD>_review/`.
2. **Independent.** Each role is its own Agent call, `model: "opus"`, fresh context. A referee never sees the other referee's report, the editor's screen, earlier simulated reviews, or this conversation. Launch the editor screen and the referees in one message.
3. **Attributed briefs.** What the author said about the paper goes into a brief marked `AUTHOR-STATED`. The main session adds no summary of the paper, no view of its quality and no hint of the expected outcome; referees read the paper themselves.
4. **No unpublished text in web searches.** With the author's permission, referees may look up published work on INSPIRE, arXiv or Crossref by author, title, identifier or field-standard terms, never by a sentence, phrase, working title or term coined in the manuscript. Without permission, no network use, and a referee says which literature points it could not check.
5. **No numbers for judgement.** No scores, ratings, confidence levels or acceptance probabilities. A recommendation is a category.

## Referee discipline (goes into every referee brief verbatim)

- Write the report a competent referee in this subfield would sign and send to this editor. Before returning it, delete every point that asks for a different paper, applies another field's standards, is generic ("the methodology could be stronger"), repeats another point, or that you would not defend to the editor.
- There is no minimum number of points. Two substantive points and a list of typos is a normal report; so is "I have no major concerns".
- Tie every point to a location: section, equation, figure, table or page.
- Mark each main point **[must address]** (a stated claim is wrong, unsupported as stated, or cannot be followed; or earlier work already contains the result) or **[optional]** (it would improve the paper, but the claims stand without it).
- If you say something is wrong, show the check: what you computed and what you got. If you could not verify a step, write "I could not verify eq. (N)" and ask for the missing step; that is a legitimate request, not an error finding.
- Say a result is already known only with the reference (arXiv id or DOI) and what that reference contains. If you cite from memory, say so.
- Say briefly what the paper does well, where it does. Do not pad.
- The recommendation follows the must-address list: none → accept or minor revision; resolvable by clarification, references or small additions → minor revision; needs a new calculation or analysis, or a claim must change → major revision; central result wrong, nothing new, or outside the journal's scope → reject. The author's experience of real reports is that a technically sound paper within scope usually gets minor or major revision; before recommending rejection of a sound, in-scope paper, re-check the reason.
- One to two pages for a regular article.

Report format:

```
Referee report: <journal>, "<title>"
Summary: one paragraph, in your own words, of what the paper does and claims.
Assessment: one paragraph on significance for this journal's readers, correctness as far as you
  checked it (name the parts you checked), and clarity.
Main points: numbered; each [must address] or [optional], location, the issue, what would resolve it.
Minor comments: location: comment (typos, notation, undefined symbols, missing references).
Note to the editor (confidential): accept / minor revision / major revision / reject, and one to
  three sentences why.
```

If the author knows the journal's own recommendation categories (economics journals may say "revise and resubmit"), use those instead.

## Panel

Default: editor, Referee A, Referee B. Who the referees are depends on the paper and the venue:

| Paper, venue | Referee A | Referee B |
|---|---|---|
| hep-th / hep-ph, physics journal | specialist in the paper's core method or model family: key steps, approximations, conventions, limits | active researcher on the physics question the paper addresses: significance, comparison with existing results, literature, whether the claims match what is computed |
| economics, economics journal | `academic-economist` agent as an economist in the paper's field, keeping its own rules (identity vs partial- vs general-equilibrium result, calibration sources, minimal fix, no blanket demand for general equilibrium) | an economist from the neighbouring subfield the paper leans on least (measurement, theory or empirics); `academic-economist` with that role card |
| physics methods on an economic question, physics journal (Physica A, PRE, ...) | statistical physicist: is the method used correctly, and is it physics this journal publishes | economist: is the economics right, and is the paper connected to the economics literature |
| the same, economics journal | economist in the paper's field | methods-literate economist or applied mathematician |

Other referees run as `general-purpose` agents with the role card. A role card names the field, the method, and the first thing the referee will check; no real person's name.

**Devil's advocate**, only when the author asks: a third referee whose brief is the strongest objection to the central claim that a referee in this field could raise. Same discipline, report labelled DA, no recommendation; the editor adopts its points only where they hold.

## Venue evidence

The editor judges scope only from evidence gathered this session, with the author's permission for network use:

- the journal's aims and scope text (publisher pages may refuse non-browser fetches, as recorded in `~/Git/dotfiles/claude/skills/journal-port/SKILL.md`, "Before porting"; then ask him to save the page);
- recent titles from Crossref, queried with two or three field-standard terms, never manuscript text: `https://api.crossref.org/works?filter=issn:<ISSN>,from-pub-date:<YYYY-01-01>&query.bibliographic=<terms>&rows=12&select=title,issued`. Zero hits is a risk signal, not a verdict;
- two or three papers of the same kind published there in the last two years, with DOIs.

Save it as `LLM/<YYMMDD>_review/venue.md` and give that file to the editor. Without it, the editor writes "Scope: not assessed (no evidence)". Choosing a venue is the journal-picker agent's job, not this skill's.

## Modes

### full (default)

1. **Panel card, checkpoint.** Target journal (ask if unstated; journal-picker if undecided); paper files (main .tex and included files, or the PDF; the compiled PDF for figures); field; the two role cards; network lookups yes/no; devil's advocate yes/no. He confirms or edits; "go" suffices.
2. **Venue evidence**, if network use is allowed.
3. **One message, parallel Agent calls:**
   - Editor screen (`general-purpose`): reads the paper and `venue.md`. Writes: Scope (in / borderline / out / not assessed, citing items in `venue.md`); send to referees, yes or no, in one paragraph; if no, the desk-rejection paragraph an editor would send. Nothing on technical correctness.
   - Referee A, Referee B (and DA if asked). Brief: role card, journal, file paths, `AUTHOR-STATED` notes, the referee discipline and report format above, the network rule, and: "Read the whole paper; read long files in chunks with offset and limit. Write nothing to disk. Return the report as your final message."
4. **Decision.** Continue the editor subagent with SendMessage, passing both reports. It writes the decision letter: the decision; one paragraph on the referees' views; required changes (only must-address points it endorses, each with its referee and location); optional suggestions; where the referees disagree, its call and the reason. It raises no technical objections of its own. If its screen found the paper out of scope, the decision is a desk rejection whatever the reports say, and the letter says why.
5. **Save** `panel.md`, `venue.md`, `editor_screen.md`, `referee_A.md`, `referee_B.md` (`referee_DA.md`) and `decision.md`, which ends with a roadmap table (id M1.. for must-address, O1.. for optional; point; source; location) for academic-paper's revision mode.
6. **Hand-over**, in the main session and outside the simulation: the decision; every point where a referee claims a derivation error, to be checked with physics-review (verify mode) before the author acts on it; what no role checked; which literature claims came from memory.

### desk

Steps 1–3 with the editor screen only. For "would they send it out?".

### re-review

Inputs: the earlier review directory, the revised manuscript, the response letter if any, and a diff of old and new source when both exist. Each referee reruns as a fresh subagent with its own earlier report only. For each of its earlier points: addressed / partly addressed / not addressed / made worse, with the location in the revised text and one line of reason. A response that answers the point counts, even when it disagrees with the referee, if its argument holds; restating the original position without a new argument does not. New points only where the revision introduced them or where an error would block publication, labelled new. Then a recommendation, and the editor's decision as in full step 4. Output in `LLM/<YYMMDD>_rereview/`, with a table per referee: point, the author's claim, location, verdict.

### calibrate

Measures realism against real review. Input: one of his papers as submitted and the real reports and decision it received. Run full mode on the submitted version; no subagent sees the real reports. Then compare in the main session: real points the simulation raised; real points it missed; simulated points no real referee raised, each judged plausible or manufactured; simulated against real recommendations and decision; length and tone. Save `LLM/<YYMMDD>_review_calibration.md` and propose specific changes to the role cards or the referee discipline. Change this skill only when he asks.
