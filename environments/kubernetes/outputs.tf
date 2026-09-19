output "control_plane_public_ip" { value = oci_core_instance.control_plane.public_ip }
output "nat_public_ip" { value = oci_core_instance.nat.public_ip }
output "kubeconfig_instructions" {
  value = <<-EOT
    ssh ubuntu@${oci_core_instance.control_plane.public_ip} 'sudo cat /etc/kubernetes/admin.conf' > kubeconfig
    sed -i.bak 's#https://.*:6443#https://127.0.0.1:6443#' kubeconfig
    ssh -N -L 6443:${var.control_plane_private_ip}:6443 ubuntu@${oci_core_instance.control_plane.public_ip}
    KUBECONFIG=$PWD/kubeconfig kubectl get nodes
  EOT
}
