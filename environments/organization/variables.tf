variable "tenancy_ocid" {
  description = "Existing OCI tenancy OCID, which is also the root compartment."
  type        = string
  sensitive   = true
}
variable "oci_region" { type = string }
variable "workloads_compartment_name" { type = string }
variable "administrator_group_name" {
  description = "Existing OCI group that administers the workload compartments."
  type        = string
}
