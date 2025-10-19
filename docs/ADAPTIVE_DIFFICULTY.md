# Adaptive Difficulty and Tactic Evaluation

This document explains the gameplay logic added to evaluate the player's (Village 1) per-agent tactics against the optimal "auto-mode" plan and to adapt Village 2 (AI) difficulty over time using fuzzy logic.

- Code locations:
  - `scripts/game_manager.gd`: evaluation, fuzzy logic, difficulty updates, HUD updates
  - `scripts/village.gd`: difficulty multipliers, optimal-evaluation helpers, AI strategy factor
  - `scripts/agent.gd`: applies difficulty multipliers to movement, energy, and carry
  - `scenes/map_generator.tscn`: added `LabelAIDifficulty` to HUD below the Win Probability

## Overview

1) Evaluate user tactic quality by comparing each agent's current task with the algorithmically optimal choice (based on the same capability logic used in auto mode).
2) Feed the tactic quality plus game pressure into a fuzzy logic module that outputs a small difficulty delta.
3) Update the AI team's difficulty multipliers gradually (speed, energy, carry, and strategy aggressiveness), making the AI stronger or weaker over time.

---

## 1) User tactic evaluation (per-agent)

Function: `GameManager.evaluate_user_tactic() -> float` returns a score in [0, 1].

For each Village 1 agent:
- Determine the agent's current selection:
  - If the agent has a manual assignment, use it.
  - Otherwise infer from its current goal (WOOD, STONE, GOLD).
- Compute the optimal resource (auto-mode baseline) using:
  - `Village.get_optimal_resource_for_agent(agent)` → argmax over resources of `calc_capability_for_eval()`.
- Compute capabilities for both the optimal and current choices using:
  - `Village.calc_capability_for_eval(agent, resource_type)` which includes:
    - Resource significance based on remaining need and team carry capacity
    - Knowledge availability (unknown locations are down-weighted)
    - Working agents metric (avoid overcrowding)
    - Agent chromosome metric (carry capacity bits)
    - Note: excludes AI strategy multipliers and user selection overrides
- Weight and credit:
  - Let `opt_cap` be the capability of the optimal resource, `cur_cap` of the chosen one.
  - Use `weight = max(opt_cap, cur_cap)` so high-impact choices matter more.
  - If resources match: full `weight` credit.
  - If different: partial credit proportional to `cur_cap / opt_cap` (clamped) times `weight * 0.5`.
- Aggregate across agents and normalize to [0, 1].

Intuition:
- Matching the optimal choice yields 100% credit for that agent.
- Near-optimal choices get partial credit; poor choices add little.
- Agents with negligible impact don’t sway the score much.

---

## 2) Fuzzy logic difficulty adjustment

Function: `GameManager.fuzzy_adjustment(tactic_quality, game_pressure) -> float` outputs a small delta in [-0.05, +0.05].

Inputs:
- `tactic_quality` ∈ [0, 1] (from evaluation above).
- `game_pressure` ∈ [0, 1] defined as `1 - win_probability_user`.
  - If the user is likely to win, pressure is low; if likely to lose, pressure is high.

Membership functions (triangular):
- For a variable x and parameters a ≤ b ≤ c:
  - Low: `tri(0.0, 0.0, 0.4, x)`
  - Medium: `tri(0.3, 0.5, 0.7, x)`
  - High: `tri(0.6, 1.0, 1.0, x)`

Where
- `tri(a,b,c,x) = 0` if `x ≤ a or x ≥ c`
- `tri(a,b,c,x) = 1` if `x = b`
- `tri(a,b,c,x) = (x - a) / (b - a)` if `a < x < b`
- `tri(a,b,c,x) = (c - x) / (c - b)` if `b < x < c`

Rule base (Mamdani style):
1) If tactic = Low and pressure = High → increase difficulty strongly (+0.05)
2) If tactic = Low and pressure = Low → increase difficulty slightly (+0.02)
3) If tactic = High and pressure = High → decrease difficulty slightly (−0.02)
4) If tactic = High and pressure = Low → decrease difficulty strongly (−0.05)
5) If tactic = Medium and pressure = Medium → small balancing towards the center (± up to ~0.04 scaled)

Defuzzification:
- Weighted average of the rule outputs with their activation strengths.
- Result is clamped to [-0.05, +0.05] to ensure gradual changes.

Update cadence:
- Every `adjust_interval_sec` seconds (default 2.0) in `_maybe_adjust_difficulty()`, which is invoked by `_update_remaining_resources()`—already called periodically by the game loop.

---

## 3) AI difficulty application (Village 2)

Difficulty state: `ai_difficulty ∈ [0, 1]` represents how strong the AI is.
- Applied via `Village.apply_difficulty(level)` which updates:
  - `speed_multiplier`: 0.95 → 1.15
  - `energy_loss_multiplier`: 0.95 → 0.75 (harder AI loses less energy per tick)
  - `energy_gain_multiplier`: 1.00 → 1.20 (harder AI refills faster)
  - `carry_multiplier`: 1.00 → 1.15 (harder AI carries more per run)
  - `decision_aggressiveness`: 0.9 → 1.3 (boosts AI capability impact in strategy)

Where they are used:
- `scripts/agent.gd`:
  - Movement speed: `chromosome.speed * village.speed_multiplier`
  - Energy gain/loss per tick scaled by `village.energy_gain_multiplier` / `village.energy_loss_multiplier`
  - Loot carry capacity scaled by `village.carry_multiplier`
- `scripts/village.gd`:
  - AI strategy capability: multiplied by `decision_aggressiveness` to slightly bias AI priorities when harder

---

## 4) HUD readouts

- `LabelWinProbability`: shows user win probability.
- `LabelAIDifficulty`: shows current `ai_difficulty` as a percent under the Win Probability panel.
  - Location: `UILayer/VBoxContainerVillage1AgentsList/PanelWinProbability/VBoxContainerWin/LabelAIDifficulty` in `scenes/map_generator.tscn`.

---

## 5) Tuning knobs and extensions

- Membership thresholds (low/med/high) and rule outputs (±0.05/0.02) can be adjusted for a more/less reactive feel.
- `adjust_interval_sec` can be shortened/lengthened (e.g., 1.0 for faster adaptation or 3.0+ for slower drift).
- Multiplier ranges in `Village.apply_difficulty()` can be widened/narrowed to change the overall impact of difficulty.
- Additional inputs to evaluation could include path length, congestion, or time-to-return metrics for even richer scoring.

---

## 6) Edge cases and safeguards

- If there are no agents or capability totals are zero, the evaluation returns a neutral 0.5.
- Difficulty deltas are clamped to keep changes smooth; difficulty itself is clamped [0, 1].
- Partial credit avoids harsh penalties when the player’s choice is near-optimal.

---

## 7) Quick reference (functions)

- `GameManager.evaluate_user_tactic() -> float`
- `GameManager.fuzzy_adjustment(tactic_quality: float, game_pressure: float) -> float`
- `GameManager._adaptive_difficulty_tick()` and `_maybe_adjust_difficulty()`
- `Village.calc_capability_for_eval(agent, resource_type) -> float`
- `Village.get_optimal_resource_for_agent(agent) -> ResourceType`
- `Village.apply_difficulty(level: float)`

---

## 8) Success criteria

- When the player makes consistently suboptimal choices and is under pressure, the AI eases up slowly—game remains fair.
- When the player dominates with high-quality choices, the AI gradually ramps up—game stays engaging.
- Changes are smooth (no sudden swings) and visible via the HUD difficulty percent.
