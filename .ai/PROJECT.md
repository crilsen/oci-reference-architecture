# Project

## Identity

- **Name:** OCI reference architecture
- **Objective:** Define reusable OCI organization, lab, and self-managed Kubernetes infrastructure with Terraform.
- **Repository purpose:** Infrastructure-as-code reference architecture for OCI.
- **Status:** Active Terraform implementation; Kubernetes node launch is blocked by `VM.Standard.A1.Flex` host capacity in all `us-ashburn-1` ADs. Egress uses an Always Free NAT instance selected by the `nat_mode` flag; a NAT Gateway limit increase (`CAM-274296`) is pending.

## Observed

- Terraform manages OCI resources. `environments/organization` manages compartments and policies; `environments/lab` is a generic VCN lab; `environments/kubernetes` manages a two-node self-managed Kubernetes topology.
- OCI region is `us-ashburn-1`. The current Kubernetes target is compartment `cn-oci`, VCN `CN-Cloud-VCN-01`, CIDR `10.251.0.0/16`.

## Template priorities

- Context belongs to the repository and travels with Git.
- Keep documentation concise, evidence-based, and non-duplicative.
- Prefer safe semi-autonomous work: exploration, scoped edits, formatting, linting, tests, and validation are allowed; impactful external operations require explicit approval.

## Recommended convention

When this template is adopted by a project, replace only the unknown sections with observed facts, link to authoritative existing documentation, and keep this file an overview rather than a duplicate README.
