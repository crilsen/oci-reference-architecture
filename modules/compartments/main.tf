# AWS conceptual equivalent: Organizational Unit in AWS Organizations
# OCI implementation: parent compartment
resource "oci_identity_compartment" "workloads" {
  compartment_id = var.tenancy_ocid
  name           = var.workloads_compartment_name
  description    = "Parent boundary for Kubernetes workload compartments."
  enable_delete  = false
}

# AWS conceptual equivalent: member account boundary
# OCI implementation: child compartment in a shared tenancy
resource "oci_identity_compartment" "lab" {
  compartment_id = oci_identity_compartment.workloads.id
  name           = "Lab"
  description    = "Isolated compartment for Kubernetes experiments."
  enable_delete  = false
}

resource "oci_identity_compartment" "production" {
  compartment_id = oci_identity_compartment.workloads.id
  name           = "Production"
  description    = "Isolated compartment representing production workloads."
  enable_delete  = false
}
