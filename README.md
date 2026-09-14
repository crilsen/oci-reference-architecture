# OCI: Compartments, IAM Policies, and OKE

OCI uses an existing tenancy as management boundary and root compartment. Terraform creates Workloads, Lab, and Production compartments.

## Hierarchy

```text
OCI tenancy / root compartment
└── KubernetesWorkloads
    ├── Lab
    └── Production
```

Compartments are IAM/resource scopes inside one tenancy, not separate accounts. `modules/compartments` creates the hierarchy with deletion disabled. `modules/policies` delegates workload administration to an existing group. OCI policies grant access and are therefore not deny-based SCP equivalents.

```bash
cd environments/organization
terraform init
terraform validate
terraform plan -var-file=terraform.tfvars
```

Replace the tenancy OCID privately and confirm the administrator group exists. Policy propagation and compartment deletion are asynchronous.

## OKE workload boundary

`environments/lab` defines region, project label, Kubernetes target, and VCN CIDR. Module boundaries reserve VCN gateways/subnets, OKE, workload identity, Container Registry, and OCI Monitoring/Logging. Governance and workload state remain independent; OKE, nodes, NAT, load balancers, and logs can incur charges.
