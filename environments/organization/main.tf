provider "oci" {
  tenancy_ocid = var.tenancy_ocid
  region       = var.oci_region
}

module "hierarchy" {
  source                     = "../../modules/compartments"
  tenancy_ocid               = var.tenancy_ocid
  workloads_compartment_name = var.workloads_compartment_name
}

module "policies" {
  source                     = "../../modules/policies"
  tenancy_ocid               = var.tenancy_ocid
  workloads_compartment_name = module.hierarchy.workloads_compartment_name
  administrator_group_name   = var.administrator_group_name
}
