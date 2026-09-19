# Tools

## Current availability

OCI CLI is installed and authenticated locally through the `DEFAULT` profile in `~/.oci/config`. Terraform uses the Oracle OCI provider and HashiCorp Random provider.

Resource limits can be read with `oci limits value list --service-name <svc> --compartment-id <tenancy> --all`. Service-limit *increases* are created with `oci support incident create --problem-type LIMIT` (pass `--ocid <user-ocid>`, required for OCI users). Support read operations (`incident get`/`list`) require My Oracle Cloud Support (MOS) registration and otherwise fail with `SUPPORT_ACCOUNT_NOT_FOUND`, even when create succeeds.

## Allowed without additional authorization

- Read and search repository files.
- Make scoped task-related edits.
- Run project formatters, linters, tests, syntax checks, and validation commands when they exist.
- Run read-only commands and safe dry runs.
- `terraform fmt`, `terraform validate`, and `terraform plan -lock=false` when the local state lock is unavailable.
- Update this portable context.

## Requires explicit authorization

- Deployment or production changes.
- `terraform apply`, `terraform destroy`, `tofu apply`, or `tofu destroy`.
- `kubectl apply` against a real cluster, `kubectl delete`, or equivalent cluster mutation.
- Secret changes, destructive state operations, irreversible changes, paid-resource creation, or any external operation with material impact.
- Creating OCI service-limit increase requests (`oci support incident create --problem-type LIMIT`): opens a real support ticket.

## Technology-specific guidance when adopted

| Technology | Usually safe | Restricted |
| --- | --- | --- |
| Terraform/OpenTofu | `fmt`, `validate`, `plan` | `apply`, `destroy` |
| Kubernetes | `get`, `describe`, `diff`, client dry-run | real-cluster apply/delete |
| Helm | `lint`, `template` | install/upgrade against real environments |
| Static analysis | `tflint`, `checkov`, `trivy`, `shellcheck` | Follow tool/project-specific impact rules |

Before running a command, confirm it is appropriate for the repository and does not require unavailable credentials or mutate external systems.
