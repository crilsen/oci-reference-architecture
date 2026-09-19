resource "oci_core_security_list" "control_plane" {
  compartment_id = var.compartment_ocid
  vcn_id         = var.vcn_id
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
  ingress_security_rules {
    protocol    = "6"
    source      = var.ssh_source_cidr
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 22
      max = 22
    }
  }
  ingress_security_rules {
    protocol    = "all"
    source      = var.private_subnet_cidr
    source_type = "CIDR_BLOCK"
  }
}
resource "oci_core_security_list" "worker" {
  compartment_id = var.compartment_ocid
  vcn_id         = var.vcn_id
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
  ingress_security_rules {
    protocol    = "all"
    source      = var.public_subnet_cidr
    source_type = "CIDR_BLOCK"
  }
  ingress_security_rules {
    protocol    = "all"
    source      = var.private_subnet_cidr
    source_type = "CIDR_BLOCK"
  }
}
resource "oci_core_subnet" "control_plane" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = var.vcn_id
  cidr_block                 = var.public_subnet_cidr
  dns_label                  = var.public_subnet_dns_label
  route_table_id             = oci_core_route_table.public.id
  security_list_ids          = [oci_core_security_list.control_plane.id]
  prohibit_public_ip_on_vnic = false
}
resource "oci_core_subnet" "worker" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = var.vcn_id
  cidr_block                 = var.private_subnet_cidr
  dns_label                  = var.private_subnet_dns_label
  route_table_id             = oci_core_route_table.private.id
  security_list_ids          = [oci_core_security_list.worker.id]
  prohibit_public_ip_on_vnic = true
}
