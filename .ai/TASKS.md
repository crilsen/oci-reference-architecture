# Current Work

## Active

- Egress has a mode flag `nat_mode` (`gateway` | `instance`). Currently `instance`: the private route table targets the NAT instance's private IP (`k8s-lab-nat`, `10.251.1.20`). Switch to `gateway` once the NAT limit is granted.
- NAT Gateway limit-increase request **submitted** as support ticket `CAM-274296` (`problem-type LIMIT`, request `1`, `us-ashburn-1`). Awaiting Oracle; `nat-gateway-count` is still `0`. Note: read-back via CLI fails with `SUPPORT_ACCOUNT_NOT_FOUND` because the tenancy is not registered on My Oracle Cloud Support.
- Obtain `VM.Standard.A1.Flex` capacity: `OUT_OF_HOST_CAPACITY` in all three ADs (`AD-1`/`AD-2`/`AD-3`) via the Compute Capacity Report. Retry later.
- After both are resolved: `terraform apply` in `environments/kubernetes`, then verify `kubectl get nodes` and that the worker joins via kubeadm.

## Planned

- Populate project-specific context after this template is adopted.

## Blocked

- `VM.Standard.A1.Flex` has no host capacity in any `us-ashburn-1` AD, so the two Kubernetes nodes cannot launch.
- NAT Gateway optional path: `vcn/nat-gateway-count` is `0` pending ticket `CAM-274296`; not a blocker while `nat_mode = "instance"`.

## Completed

- Created the NAT instance `k8s-lab-nat` (`VM.Standard.E2.1.Micro`, `US-ASHBURN-AD-3`, ephemeral public IP, `skip_source_dest_check`), and `terraform import`ed it as `oci_core_instance.nat` with no diff.
- Added `nat_mode` (`gateway` | `instance`); the private route table selects the NAT Gateway or the NAT instance accordingly.
- Test-applied `environments/kubernetes`: created `oci_core_subnet.control_plane`; NAT Gateway failed on quota and the control-plane instance failed on A1.Flex capacity.
- Restored kubeadm cloud-init in `environments/kubernetes/compute.tf` via `templatefile()` over `templates/kubeadm.yaml.tftpl`, parameterized the API server port, and confirmed `terraform plan` reports 6 to add.
- Adopted the repository context with observed OCI/Terraform facts.
- Configured `cn-oci` and VCN `CN-Cloud-VCN-01` as Kubernetes defaults.

- Created the portable agent-context template.
- Polished template consistency: referenced `.ai/prompts/` in `AGENTS.md`, corrected the `PROJECT.md` observed state, and removed a stray test file.
- Added the learning feedback loop: `.ai/LEARNINGS.md`, `.ai/workflows/capture-learning.md`, `.ai/prompts/capture-learning.md`, the capture step in `AGENTS.md`, and the promotion/compaction rules.
- Added agent independence and provider switching: `.ai/ADAPTERS.md`, `.ai/workflows/switch-agent.md`, `.ai/prompts/switch-agent.md`, the Resume block in `HANDOFF.md`, and the switch step in `AGENTS.md`.
- Added usage-limit safety: `.ai/LIMITS.md`, `.ai/workflows/checkpoint.md`, `.ai/prompts/checkpoint.md`, the budget/checkpoint fields in the Resume block, and the checkpoint step in `AGENTS.md`.
- Added the adoption flow: `.ai/workflows/adopt.md`, `.ai/prompts/adopt.md`, and the bootstrap instructions in `README.md`.
- Made `AGENTS.md` self-driving: load-context, mode detection, work steps, and always-on rules, so "read AGENTS.md" is sufficient.
