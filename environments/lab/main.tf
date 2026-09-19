resource "oci_core_vcn" "this" {
  compartment_id = var.compartment_ocid
  cidr_block     = var.vcn_cidr
  display_name   = "${var.project_name}-vcn"
  dns_label      = "labvcn"
}
