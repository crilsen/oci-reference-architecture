output "workloads_compartment_name" { value = oci_identity_compartment.workloads.name }
output "lab_compartment_id" { value = oci_identity_compartment.lab.id }
output "production_compartment_id" { value = oci_identity_compartment.production.id }
