# Session Handoff

## Resume block (read first)

- Repo state: branch `dev`, HEAD `f3ca92e`, working tree dirty; Terraform, scripts, and context updates are uncommitted.
- Source of truth: `AGENTS.md` → `.ai/`
- Budget / usage observed: `<unknown | value from the tool>`
- Checkpoint updated: `2026-09-17`
- Last goal: Prepare a two-node self-managed OCI Kubernetes environment in `cn-oci`.
- Exact next action: Obtain `VM.Standard.A1.Flex` capacity (`OUT_OF_HOST_CAPACITY` in all three `us-ashburn-1` ADs) by retrying later; then `terraform apply` in `environments/kubernetes` and verify `kubectl get nodes`. Egress currently uses `nat_mode = "instance"` (NAT instance `k8s-lab-nat`, already in state). Switch `nat_mode` to `gateway` only after ticket `CAM-274296` raises `vcn/nat-gateway-count` to 1. Everything must stay within the Always Free allowance (ADR-005).
- Blocked by: `VM.Standard.A1.Flex` host capacity unavailable in every `us-ashburn-1` AD. (`nat-gateway-count` is still `0` but no longer blocks, because `nat_mode = "instance"`.)
- Resume prompt: `Read AGENTS.md and .ai/HANDOFF.md. Continue from the Resume block. Do not rediscover context.`

## Goal

Prepare a two-node self-managed OCI Kubernetes environment in `cn-oci`: one public control-plane and one private worker on the existing VCN `CN-Cloud-VCN-01`.

## Current State

`environments/kubernetes` defines an IGW, an optional NAT Gateway (gated by `nat_mode`), public/private route tables, security lists, one public subnet (`10.251.1.0/24`), one private subnet (`10.251.2.0/24`), two `VM.Standard.A1.Flex` nodes, and one NAT instance. `nat_mode = "instance"` routes the private subnet through the NAT instance's private IP; `"gateway"` uses a NAT Gateway instead. State holds the IGW, public route table, security lists, `control_plane` subnet, kubeadm tokens, and the NAT instance `oci_core_instance.nat` (created out-of-band and imported, no diff). `terraform plan` reports 4 to add (control-plane, worker, worker subnet, private route table). Blocked only by A1.Flex capacity.

## What Was Done

- Confirmed `vcn/nat-gateway-count = 0` (REGION scope) and inventoried VCN/compute limits; verified A1 capacity with the Compute Capacity Report (`OUT_OF_HOST_CAPACITY` in AD-1/2/3) and E2.1.Micro availability (AD-3 only).
- Restored kubeadm cloud-init by rendering `templates/kubeadm.yaml.tftpl` with `templatefile()` and injecting base64 `user_data` on both nodes; parameterized the API server port.
- Verified `v1.37` is the current Kubernetes stable and exists in the `pkgs.k8s.io` repository.
- Test-applied the environment: `oci_core_subnet.control_plane` was created; the NAT Gateway failed on quota and the control-plane instance failed on A1.Flex capacity.
- Filed the NAT Gateway limit-increase request via `oci support incident create --problem-type LIMIT`; Oracle returned ticket `CAM-274296`.
- Established the Always Free constraint (ADR-005) after finding `nat-gateway-count = 0` and `VM.Standard.E2.1.Micro` quota only in `US-ASHBURN-AD-3`.
- Created NAT instance `k8s-lab-nat` (`VM.Standard.E2.1.Micro`, AD-3, ephemeral public IP, `skip_source_dest_check`) and imported it as `oci_core_instance.nat`.
- Added the `nat_mode` (`gateway` | `instance`) flag and wired the private route table to select the corresponding NAT target.

## Files Changed

- `environments/kubernetes/compute.tf` (kubeadm cloud-init + NAT instance)
- `environments/kubernetes/network.tf` (`nat_mode` gating + private route target)
- `environments/kubernetes/variables.tf`, `terraform.tfvars`
- `environments/kubernetes/templates/kubeadm.yaml.tftpl`, `templates/nat.yaml.tftpl`
- `environments/kubernetes/outputs.tf`
- `scripts/bootstrap-kubernetes-tfvars.sh`
- `.ai/TASKS.md`, `.ai/HANDOFF.md`, `.ai/DECISIONS.md`, `.ai/LEARNINGS.md`, `.ai/TOOLS.md`

## Decisions Made

- ADR-005: stay within the OCI Always Free allowance; no paid shapes, no dependency on NAT Gateway.
- Added `nat_mode` so the same code can use a NAT Gateway (when the limit is granted) or a NAT instance, with only one active route.

## Problems / Risks

- `VM.Standard.A1.Flex` has `OUT_OF_HOST_CAPACITY` in all three `us-ashburn-1` ADs; the cluster cannot launch until capacity appears.
- `nat-gateway-count` is `0` until Oracle resolves ticket `CAM-274296`; Support read-back fails (`SUPPORT_ACCOUNT_NOT_FOUND`) because the tenancy is not registered on My Oracle Cloud Support.
- `terraform.tfvars` sets `ssh_source_cidr = "0.0.0.0/0"`, so SSH is open to the internet; tighten before any non-lab use.
- The NAT instance's `user_data`/iptables setup is unvalidated (no workload behind it yet).
- Untested runtime: the kubeadm bootstrap has not run on a live cluster.

## Validation Performed

- `terraform fmt -check -recursive` — Validated.
- `terraform -chdir=environments/kubernetes validate` — Validated.
- `terraform -chdir=environments/kubernetes plan -lock=false` — Validated: 4 to add, 0 to change, 0 to destroy; private route targets the NAT instance private IP (`ocid1.privateip...`); no `oci_core_nat_gateway` planned under `nat_mode = "instance"`.
- `terraform import oci_core_instance.nat` — Validated: import successful, no diff on subsequent plan.
- NAT instance launch (`oci compute instance launch`) — Validated: reached `RUNNING`.
- `bash -n scripts/bootstrap-kubernetes-tfvars.sh` — Validated; `shellcheck` unavailable.
- `oci support incident create --problem-type LIMIT` — Validated: returned ticket `CAM-274296`.
- Not validated: complete apply, `kubectl`, node join, NAT instance forwarding.

## Next Actions

- Retry `VM.Standard.A1.Flex` capacity periodically; when available, `terraform apply` and verify the cluster.
- Switch `nat_mode` to `gateway` once `CAM-274296` raises `nat-gateway-count` to 1.
- Tighten `ssh_source_cidr` before any non-lab use.
