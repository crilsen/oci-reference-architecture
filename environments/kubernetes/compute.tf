resource "random_string" "token_id" {
  length  = 6
  lower   = true
  numeric = true
  special = false
  upper   = false
}
resource "random_string" "token_secret" {
  length  = 16
  lower   = true
  numeric = true
  special = false
  upper   = false
}
locals {
  kubeadm_token = "${random_string.token_id.result}.${random_string.token_secret.result}"
  kubeadm_common = {
    kubernetes_version = var.kubernetes_minor_version
    token              = local.kubeadm_token
    control_plane_ip   = var.control_plane_private_ip
    api_server_port    = var.api_server_port
    pod_cidr           = var.pod_cidr
  }
  control_plane_user_data = templatefile("${path.module}/templates/kubeadm.yaml.tftpl", merge(local.kubeadm_common, { role = "control-plane" }))
  worker_user_data        = templatefile("${path.module}/templates/kubeadm.yaml.tftpl", merge(local.kubeadm_common, { role = "worker" }))
  nat_user_data           = templatefile("${path.module}/templates/nat.yaml.tftpl", { worker_subnet_cidr = var.private_subnet_cidr })
}
resource "oci_core_instance" "control_plane" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_ocid
  display_name        = "${var.project_name}-control-plane"
  shape               = var.instance_shape
  shape_config {
    ocpus         = var.instance_ocpus
    memory_in_gbs = var.instance_memory_gbs
  }
  create_vnic_details {
    subnet_id        = oci_core_subnet.control_plane.id
    private_ip       = var.control_plane_private_ip
    assign_public_ip = true
  }
  source_details {
    source_type = "image"
    source_id   = var.instance_image_ocid
  }
  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(local.control_plane_user_data)
  }
}
resource "oci_core_instance" "worker" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_ocid
  display_name        = "${var.project_name}-worker-1"
  shape               = var.instance_shape
  shape_config {
    ocpus         = var.instance_ocpus
    memory_in_gbs = var.instance_memory_gbs
  }
  create_vnic_details {
    subnet_id        = oci_core_subnet.worker.id
    assign_public_ip = false
  }
  source_details {
    source_type = "image"
    source_id   = var.instance_image_ocid
  }
  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(local.worker_user_data)
  }
}
resource "oci_core_instance" "nat" {
  availability_domain = var.nat_availability_domain
  compartment_id      = var.compartment_ocid
  display_name        = "${var.project_name}-nat"
  shape               = "VM.Standard.E2.1.Micro"
  create_vnic_details {
    subnet_id              = oci_core_subnet.control_plane.id
    private_ip             = var.nat_instance_private_ip
    assign_public_ip       = true
    skip_source_dest_check = true
  }
  source_details {
    source_type = "image"
    source_id   = var.nat_instance_image_ocid
  }
  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(local.nat_user_data)
  }
}
