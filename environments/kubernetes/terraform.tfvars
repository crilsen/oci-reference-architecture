vcn_id                   = "ocid1.vcn.oc1.iad.amaaaaaamspoqmiaf6c2spebgzz2ml4kzqqeg5bwk7igtfoworsyureuibna"
compartment_ocid         = "ocid1.compartment.oc1..aaaaaaaabbxp42tusvrht5llgsplmskll5p3ka3ombkyygz6k5vtjxnxt5lq"
project_name             = "k8s-lab"
public_subnet_cidr       = "10.251.1.0/24"
private_subnet_cidr      = "10.251.2.0/24"
public_subnet_dns_label  = "k8spublic"
private_subnet_dns_label = "k8sprivate"
control_plane_private_ip = "10.251.1.10"
instance_shape           = "VM.Standard.A1.Flex"
instance_ocpus           = 1
instance_memory_gbs      = 6
kubernetes_minor_version = "v1.37"
pod_cidr                 = "10.244.0.0/16"
api_server_port          = 6443
flannel_vxlan_port       = 8472
ssh_source_cidr          = "0.0.0.0/0"
nat_availability_domain  = "xWeP:US-ASHBURN-AD-3"
nat_instance_private_ip  = "10.251.1.20"
nat_mode                 = "instance"

# Informe apenas em arquivo privado ou TF_VAR_*:
# tenancy_ocid         = "ocid1.tenancy.oc1..."
# compartment_ocid     = "ocid1.compartment.oc1..."
# availability_domain  = "..."
# instance_image_ocid  = "ocid1.image.oc1..."
# ssh_public_key       = "ssh-ed25519 AAAA..."
