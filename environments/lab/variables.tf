variable "oci_region" {
  description = "OCI region used by the lab."
  type        = string
}

variable "project_name" {
  description = "Generic prefix for OCI lab resources."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for OKE."
  type        = string
}

variable "vcn_cidr" {
  description = "Address range for the lab virtual cloud network."
  type        = string
}
