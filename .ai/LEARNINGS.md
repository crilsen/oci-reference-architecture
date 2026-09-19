# Learnings

Append-only buffer of reusable, non-obvious learnings captured while working, so future sessions and tools do not rediscover them. This is not task state (`TASKS.md`), not a session handoff (`HANDOFF.md`), and not a durable decision record (`DECISIONS.md`).

## How to use

- Append one entry per learning. Do not rewrite or delete entries; to correct one, mark it `superseded` and add a new entry.
- Capture only learnings that are non-obvious and likely to recur. Skip anything already stated in `CONVENTIONS.md`, `DECISIONS.md`, `TOOLS.md`, or `VALIDATION.md`.
- Keep each entry short and evidence-based. Prefer `observed` facts over speculation.
- This file is a buffer, not a permanent home: promote durable learnings and keep the entry as a breadcrumb.

## Entry format

```text
### L-001 — <short title>
Date: YYYY-MM-DD
Status: active | superseded | promoted
Confidence: observed | inferred
Scope: repo | <path-or-glob> | <technology>
Context: <what was being done>
Evidence: <file:line, command output, or concrete observation>
Pattern / rule: <the reusable takeaway>
Promotion: none | CONVENTIONS.md | DECISIONS.md#ADR-nnn | TOOLS.md | VALIDATION.md
```

## Promotion rules

- Recurring pattern → `CONVENTIONS.md`
- Durable architectural choice → `DECISIONS.md` (ADR), cross-referenced here
- Safe or restricted command rule → `TOOLS.md`
- Completion or validation check → `VALIDATION.md`

After promotion, set the entry to `Status: promoted` and keep it as a breadcrumb; do not duplicate the rule body.

## Compaction

- Keep at most 40 active entries. When exceeded, consolidate related entries, promote what is durable, and mark the rest `superseded`.
- Compaction means summarizing and promoting, not erasing history. Record the compaction in `HANDOFF.md`.

## Entries

### L-008 — Routing to a NAT instance and importing it back into Terraform
Date: 2026-09-17
Status: active
Confidence: observed
Scope: environments/kubernetes | OCI
Context: Creating an Always Free NAT instance out-of-band and wiring it as the private route target.
Evidence: `oci compute instance launch ... --skip-source-dest-check true` reached `RUNNING`; `terraform import oci_core_instance.nat <ocid>` succeeded with no diff. The singular `oci_core_private_ip` data source requires `private_ip_id`, so the route target was resolved with the plural `oci_core_private_ips` data source using `subnet_id` + `ip_address`, yielding a `ocid1.privateip...` for `route_rules.network_entity_id`.
Pattern / rule: A compute instance can act as a route target by giving the route rule a private IP OCID (disable source/dest check on the VNIC). Look it up with `oci_core_private_ips` (`subnet_id`+`ip_address`), not the singular data source. Resources created by CLI can be adopted with `terraform import` and then show no diff when the config matches.
Promotion: none

### L-006 — A1.Flex capacity can be unavailable in a single AD
Date: 2026-09-14
Status: active
Confidence: observed
Scope: OCI | environments/kubernetes
Context: First `terraform apply` of the Kubernetes environment.
Evidence: `oci_core_instance.control_plane` launch returned `500-InternalError, Out of host capacity` for `VM.Standard.A1.Flex` in `US-ASHBURN-AD-1`; the NAT Gateway failed in the same apply.
Pattern / rule: A1.Flex availability is per-AD and can be exhausted; retry later, try another AD (`US-ASHBURN-AD-2`/`AD-3`), or switch shape. Apply failures leave partial state, so re-plan before retrying.
Promotion: none

### L-007 — Service-limit increases can be created via `oci support incident create`
Date: 2026-09-16
Status: active
Confidence: observed
Scope: OCI | .ai/TOOLS.md
Context: Opening a NAT gateway limit-increase request.
Evidence: `oci support incident create --problem-type LIMIT --from-json ...` returned ticket `CAM-274296` with `problem-type: LIMIT`. Passing `--ocid <user-ocid>` is mandatory for OCI users (without it: `USER_OCID_MISSING`). Subsequent `incident get`/`list` fail with `SUPPORT_ACCOUNT_NOT_FOUND` ("MOS validation failure. Support account does not exists").
Pattern / rule: Create limit-increase SRs with `oci support incident create --problem-type LIMIT`; confirm the current value first with `oci limits value list`. Reads may require My Oracle Cloud Support registration even when create succeeds, so treat the returned ticket number as the source of truth.
Promotion: TOOLS.md

### L-005 — OCI service-limit increases have no CLI/API path
Date: 2026-09-14
Status: superseded
Confidence: observed
Scope: OCI | .ai/TOOLS.md
Context: Preparing the NAT Gateway limit-increase request.
Evidence: `oci limits` exposes only `definition`, `quota`, `resource-availability`, `service`, and `value`; there is no increase-request command. `oci limits value list --service-name vcn --name nat-gateway-count` returns `0` (REGION scope).
Pattern / rule: Superseded by L-007: there is no `oci limits` request command, but `oci support incident create --problem-type LIMIT` does create the SR.
Promotion: TOOLS.md

### L-004 — NAT quota can be zero without visible NAT resources
Date: 2026-09-14
Status: promoted
Confidence: observed
Scope: OCI | environments/kubernetes
Context: Diagnosing `400-LimitExceeded` while creating a NAT Gateway.
Evidence: `oci limits value list --service-name vcn --name nat-gateway-count` returned value `0`; NAT lists were empty.
Pattern / rule: Check the effective VCN NAT limit before assuming an existing hidden gateway; private-node egress requires a quota increase or an alternate design.
Promotion: DECISIONS.md#ADR-004

### L-001 — Workflows and prompts duplicate their content
Date: 2026-09-14
Status: active
Confidence: observed
Scope: .ai/workflows/**, .ai/prompts/**
Context: Auditing the template for maintainability.
Evidence: `.ai/prompts/review.md`, `.ai/prompts/security-review.md`, and `.ai/prompts/cloud-port.md` restate the same steps as the matching workflows.
Pattern / rule: Keep prompts as thin pointers to the workflow file; do not restate the procedure, or the two copies will diverge.
Promotion: none

### L-002 — Switching agents only survives if state is committed
Date: 2026-09-14
Status: active
Confidence: observed
Scope: repo | .ai/HANDOFF.md
Context: Designing handoff between agents and providers after a usage limit.
Evidence: An agent on the same checkout sees the working tree, but a different machine, cloud agent, or fresh clone sees only committed and pushed files.
Pattern / rule: Before switching agents, commit and push work in progress or list uncommitted files explicitly in `.ai/HANDOFF.md`; never rely on chat history.
Promotion: none

### L-003 — Remaining quota is usually not observable
Date: 2026-09-14
Status: active
Confidence: observed
Scope: repo | .ai/LIMITS.md
Context: Designing an automatic warning near provider usage limits.
Evidence: Providers meter usage differently and do not expose a uniform quota API; OpenCode Go documents usage only in the web console.
Pattern / rule: Combine reported usage when available with a work-volume proxy, and keep a continuously current Resume block; never state a remaining quota that was not observed.
Promotion: none
