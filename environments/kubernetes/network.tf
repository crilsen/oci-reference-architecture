resource "oci_core_internet_gateway" "this" {
  compartment_id = var.compartment_ocid
  vcn_id         = var.vcn_id
  display_name   = "${var.project_name}-igw"
  enabled        = true
}
resource "oci_core_nat_gateway" "this" {
  count          = var.nat_mode == "gateway" ? 1 : 0
  compartment_id = var.compartment_ocid
  vcn_id         = var.vcn_id
  display_name   = "${var.project_name}-nat"
}
resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = var.vcn_id
  route_rules {
    network_entity_id = oci_core_internet_gateway.this.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}
data "oci_core_private_ips" "nat" {
  subnet_id  = oci_core_subnet.control_plane.id
  ip_address = var.nat_instance_private_ip
}
resource "oci_core_route_table" "private" {
  compartment_id = var.compartment_ocid
  vcn_id         = var.vcn_id
  route_rules {
    network_entity_id = var.nat_mode == "gateway" ? oci_core_nat_gateway.this[0].id : data.oci_core_private_ips.nat.private_ips[0].id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}
