# Parallel Design Variants Skill

Generate N genuinely different design directions at once — each built by its own subagent locked to a distinct visual reference — collect them in one gallery, pick winners, then run a second round that mixes the winning styles.

## What it does

When you'd otherwise build one design and iterate, but you don't yet know the direction, this skill turns the choice into a parallel bake-off. The core idea: **divergence comes from reference anchors, not from asking "be creative."** Ten subagents told "make a nice hero" produce ten similar heroes; ten subagents anchored to terminal / broadsheet / brutalist / swiss / zine produce ten different worlds with the same content.

## When to use

- A redesign, landing, hero, thumbnail layout, email, or slide system where the direction is open
- You want a real choice between options, not iteration on a first guess
- A live/stream or team design bake-off where people vote on the options

Not for:

- A single known direction — just build it
- Pixel-level refinement of one chosen design — that's normal iteration

## The loop

```text
ask how many variants (N)
  → spec doc (constant content + N reference anchors + briefs)
  → N subagents in parallel (blind to each other)
  → gallery index.html (side by side)
  → pick winners (optionally by vote)
  → second round: mix winning styles
```

## Method contract

- **One spec doc** holds everything: constant content, result layout, the table of N reference anchors, a shared prompt scaffold, and per-direction briefs
- **Constant content** — identical real data and required sections across every variant; only the visual system differs
- **Asks how many variants (N)** first — suggests 6–10; each anchored to a distinct, recognizable reference (adjacent styles waste a variant)
- **Self-contained HTML** — inline CSS, vanilla JS, no build step, no framework, so the gallery just opens
- **Parallel dispatch** — subagents blind to each other; that independence produces the divergence
- **Converge by remixing** — the second round mixes winning styles, it does not polish one or restart

## Installation

```bash
cp -r skills/parallel-design-variants ~/.claude/skills/
```

The skill is then available in Claude Code.

## How to invoke

Tell the agent:

> "Use parallel-design-variants and give me design options for this hero."

Or:

> "Run a design bake-off for the landing page — several different directions, then mix the winners."

## See also

- [SKILL.md](SKILL.md) — full skill specification
- [README.ru.md](README.ru.md) — Russian version
