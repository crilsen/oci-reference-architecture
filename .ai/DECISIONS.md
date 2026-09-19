# Architectural Decisions

## ADR-001 — Bounded learnings buffer with promotion

Status: Accepted

Context:
The template recorded state (`TASKS.md`, `HANDOFF.md`) and durable choices (`DECISIONS.md`), but had no mechanism for an agent to retain reusable, non-obvious learnings across sessions and tools.

Decision:
Introduce `.ai/LEARNINGS.md` as a bounded, append-only buffer with a fixed entry format, promotion rules, and compaction at 40 active entries. Durable learnings are promoted to `CONVENTIONS.md`, `DECISIONS.md`, `TOOLS.md`, or `VALIDATION.md` and the entry is marked `promoted`.

Reasoning:
Keeps the normative files clean and evidence-based while giving agents an explicit, portable place to capture what they learned, avoiding rediscovery and drift between tools.

Consequences:
- Learnings are portable and versioned with the repository.
- The buffer can grow and must be compacted; promotion directs durable rules to their permanent home.
- Agents must follow `.ai/workflows/capture-learning.md` rather than writing ad-hoc notes.

## ADR-002 — Agent-independent context with thin adapters

Status: Accepted

Context:
Work must continue across different agents, models, providers, and machines, including when one provider's usage limit is reached. Tool-specific files and chat history are not portable.

Decision:
Keep `AGENTS.md` and `.ai/` as the only source of truth. Any tool-specific file is a thin adapter that routes to `AGENTS.md` and contains no project facts; adapter paths are catalogued in `.ai/ADAPTERS.md`. Handoff state is carried by the Resume block in `.ai/HANDOFF.md` and the protocol in `.ai/workflows/switch-agent.md`, and must be committed and pushed or explicitly listed as uncommitted.

Reasoning:
The repository is the only medium every agent can read. Keeping adapters thin prevents drift, and centralizing handoff in version-controlled files makes agents interchangeable.

Consequences:
- Context survives agent, model, provider, and machine changes.
- Agents with lower context windows or tighter limits can resume because `AGENTS.md` stays small and `.ai/` is read on demand.
- Uncommitted work can be lost on a machine switch unless it is committed, pushed, or listed in `HANDOFF.md`.

## ADR-003 — Rolling checkpoints with usage-limit thresholds

Status: Accepted

Context:
Provider usage can be exhausted mid-task. The agent cannot always read the exact remaining quota, and losing work at the limit defeats the portability goals.

Decision:
Adopt a rolling checkpoint: the Resume block in `.ai/HANDOFF.md` is kept current after every meaningful step. Define usage thresholds in `.ai/LIMITS.md` (warn at 70%, stop starting new work and finalize at 85%). Use reported usage when the tool exposes it, plus a self-imposed work-volume proxy otherwise.

Reasoning:
A continuously current handoff makes any interruption resumable, and explicit thresholds turn an abrupt limit into a planned handoff.

Consequences:
- Interruptions and provider switches become routine rather than lossy.
- Agents must commit or list work in progress and must not claim an unobserved quota.
- Tool-specific watchers (statusline, hook, plugin) are optional and stay thin; the policy remains portable.

Use this ADR format for durable, meaningful decisions:

```text
## ADR-NNN - Title

Status: Proposed | Accepted | Superseded | Deprecated

Context:
...

Decision:
...

Reasoning:
...

Consequences:
...
```

Do not backfill invented history. Record decisions that are observed, expressly documented, or approved during future work.

## ADR-004 — Kubernetes default OCI boundary

Status: Accepted

Context:
The user selected the `cn-oci` compartment and its existing VCN for the self-managed Kubernetes environment.

Decision:
Use compartment `cn-oci` and VCN `CN-Cloud-VCN-01` (`10.251.0.0/16`) as the default Kubernetes target. Keep the VCN external to Terraform while Terraform manages cluster-adjacent networking.

Consequences:
- Planned subnets must be contained within `10.251.0.0/16`.
- Terraform must not attempt a NAT Gateway until the tenancy NAT quota is increased or the design changes.

## ADR-005 — Stay within the OCI Always Free allowance

Status: Accepted

Context:
The user requires the environment to remain within OCI's Always Free tier, without upgrading to a paid account and without a permanent cost. Observed Always Free facts: `vcn-count = 2`, `internet-gateway-count = 1`, `nat-gateway-count = 0`, A1 compute allowance of 2 OCPUs / 12 GB total, and `VM.Standard.E2.1.Micro` quota only in `US-ASHBURN-AD-3` (`AD-1`/`AD-2` are `0`).

Decision:
Design the Kubernetes environment so every resource stays inside the Always Free allowance: `VM.Standard.A1.Flex` totaling at most 2 OCPUs / 12 GB across both nodes, no paid shapes, and no reliance on NAT Gateway (unavailable in Always Free). If NAT-style private egress is required, use an Always Free NAT instance rather than a NAT Gateway. A NAT Gateway limit-increase request (ticket `CAM-274296`) was filed, but the design must not depend on its approval.

Reasoning:
Cost is a hard constraint. NAT Gateway returned `400-LimitExceeded` with a `0` limit, and Oracle guidance tells Free Tier tenancies to design without NAT.

Consequences:
- Instance shapes and counts are capped at the Always Free allowance; adding nodes or resizing beyond it is not allowed.
- The NAT Gateway resource cannot be part of a working apply unless the limit is granted.
- Private worker egress requires an alternative (NAT instance) or a public worker, both within Always Free.

## ADR-006 — Selectable NAT target via `nat_mode`

Status: Accepted

Context:
The NAT Gateway is unavailable on Always Free (`vcn/nat-gateway-count = 0`, ticket `CAM-274296` pending), but a working egress is needed now and the same code should switch to the real NAT Gateway if the limit is granted. The user asked to keep both options with only one active.

Decision:
Add a `nat_mode` variable (`"gateway"` | `"instance"`, validated). The NAT Gateway resource uses `count = nat_mode == "gateway" ? 1 : 0`, and the private route table's `network_entity_id` selects the NAT Gateway or the NAT instance's private IP accordingly. The NAT instance is an Always Free `VM.Standard.E2.1.Micro` with `skip_source_dest_check` and an ephemeral public IP.

Reasoning:
One code base, one active egress target, no NAT Gateway attempt while the limit is `0`, and a one-variable switch once the limit increases.

Consequences:
- `nat_mode = "instance"` is the current default; no NAT Gateway is planned.
- The private route target depends on a `oci_core_private_ips` data source lookup of the NAT instance's private IP.
- The NAT instance is created and imported into state; switching to `gateway` leaves it running but out of the data path.

