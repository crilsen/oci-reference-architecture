output "resource_structure" {
  value = {
    management_tenancy      = var.tenancy_ocid
    lab_compartment         = module.hierarchy.lab_compartment_id
    production_compartment  = module.hierarchy.production_compartment_id
  }
  sensitive = true
}
