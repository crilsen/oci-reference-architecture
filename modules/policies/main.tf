# AWS closest equivalent: IAM policies combined with organizational guardrails
# OCI implementation: tenancy-level IAM policy granting compartment administration
resource "oci_identity_policy" "workload_administration" {
  compartment_id = var.tenancy_ocid
  name           = "KubernetesWorkloadAdministration"
  description    = "Delegate workload administration without granting tenancy-wide administration."
  statements = [
    "Allow group ${var.administrator_group_name} to manage all-resources in compartment ${var.workloads_compartment_name}",
    "Allow group ${var.administrator_group_name} to inspect compartments in tenancy"
  ]
}
