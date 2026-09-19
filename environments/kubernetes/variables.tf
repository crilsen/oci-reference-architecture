variable "tenancy_ocid" { type = string }
variable "compartment_ocid" { type = string }
variable "oci_region" { type = string }
variable "vcn_id" { type = string }
variable "project_name" { type = string }
variable "availability_domain" { type = string }
variable "ssh_public_key" { type = string }
variable "ssh_source_cidr" { type = string }
variable "public_subnet_cidr" { type = string }
variable "private_subnet_cidr" { type = string }
variable "public_subnet_dns_label" { type = string }
variable "private_subnet_dns_label" { type = string }
variable "control_plane_private_ip" { type = string }
variable "instance_shape" { type = string }
variable "instance_ocpus" { type = number }
variable "instance_memory_gbs" { type = number }
variable "instance_image_ocid" { type = string }
variable "kubernetes_minor_version" { type = string }
variable "pod_cidr" { type = string }
variable "api_server_port" { type = number }
variable "flannel_vxlan_port" { type = number }
variable "nat_availability_domain" { type = string }
variable "nat_instance_image_ocid" { type = string }
variable "nat_instance_private_ip" { type = string }
variable "nat_mode" {
  type = string
  validation {
    condition     = contains(["gateway", "instance"], var.nat_mode)
    error_message = "nat_mode deve ser \"gateway\" ou \"instance\"."
  }
}
