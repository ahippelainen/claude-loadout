# Physics conventions: how the physics agents find and keep them

Conventions belong to a project, not to the agents. They change between projects (a mostly-plus V-QCD paper, a mostly-minus AdS/QCD note) and sometimes within one as a paper matures, so no agent carries defaults.

## Where they live

Each research project keeps them in `LLM/conventions.md` (created by `/research-init`). Every entry says what the convention is, where it was read (file and line, or "stated by the author on <date>"), and when it was last checked. When something changes, the old entry is struck through with the date, not deleted, so older notes can still be read correctly.

## Protocol for every agent

1. Read `LLM/conventions.md`. If it is missing or does not cover what the task needs, read the conventions section of the project's notes or draft (search for "signature", "mostly", "convention", "Riemann", the action).
2. If still unsettled, ask. Never pick a convention silently; a derivation that needs an unfixed convention stops there.
3. When a convention is established during the work (from the author or read from the draft), add it to `LLM/conventions.md` with its source and date.
4. State the conventions used at the top of every derivation, and flag any quantity whose sign or factor depends on one of them.

## Axes to fix (as far as the task needs)

- Metric signature, and the spacetime and boundary dimensions (d+1 bulk, d boundary, or another labelling).
- Curvature: the Riemann and Ricci definitions, hence the sign of R for AdS.
- Normalization and sign of the gravitational action (κ², G, 1/(2κ²) or 1/(16πG), string or Einstein frame when there is a dilaton).
- Radial coordinate: name (z, r, u), where the boundary sits, orientation, and the AdS radius (L or ℓ; set to 1 or kept).
- Units (ℏ = c = 1, GeV or units of the IR scale).
- Fourier convention (e^{−iωt+ik·x} or the opposite) and hence the form of the infalling condition.
- Gauge fields: covariant-derivative sign, coupling normalization, generator normalization Tr(TᵃTᵇ).
- Matter normalizations: how fields such as π or the tachyon are normalized relative to f_π, and any field redefinitions.
- Kinematics specific to the project, e.g. t = −Q² for form factors, Minkowski or Euclidean momenta.
- Wick rotation convention, when both signatures appear.

## Signature flip, for reference (derived)

Under g_{μν} → −g_{μν} with the Riemann and Ricci definitions kept: Christoffel symbols, R^a_{bcd} and R_{ab} are unchanged; R → −R; √|g| is unchanged (use √|g|: det(−g) = (−1)^D det g changes sign in odd D). Each inverse metric in a contraction contributes one sign: (∂φ)² and A_μA^μ flip, F_{μν}F^{μν} does not, a mass term m²φ² has no metric. So the Einstein-Hilbert term must change its overall sign to describe the same physics, and a mostly-plus scalar Lagrangian −½(∂φ)² − ½m²φ² becomes +½(∂φ)² − ½m²φ² in mostly-minus.
