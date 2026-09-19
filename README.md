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

## Infraestrutura base Always Free

`environments/lab` e uma infraestrutura generica de laboratorio, independente de Kubernetes. Atualmente cria uma VCN basica, que pode ser estendida conforme cada workload.

`environments/kubernetes` cria um cluster autogerenciado inspirado no [Ampernetacle](https://github.com/jpetazzo/ampernetacle) dentro de uma VCN existente. Ele cria a malha de rede ao redor do cluster (internet gateway, route tables publica/privada, security lists e duas subnets `10.251.1.0/24` e `10.251.2.0/24`), duas VMs Ampere `VM.Standard.A1.Flex` (1 OCPU e 6 GB cada: um control plane publico e um worker privado) e uma NAT instance `VM.Standard.E2.1.Micro` para a saida do worker.

O egress e selecionavel por `nat_mode`:

- `instance` (padrao): a rota privada aponta para o IP privado da NAT instance.
- `gateway`: usa um NAT Gateway, indisponivel em conta Always Free (`vcn/nat-gateway-count` = 0; pedido `CAM-274296` pendente).

Gere os valores privados (tenancy, `compartment_ocid`, imagem, AD e `ssh_public_key`) e aplique:

```bash
bash scripts/bootstrap-kubernetes-tfvars.sh
cd environments/kubernetes
terraform init
terraform plan
terraform apply
```

Restrinja `ssh_source_cidr` ao IP publico do seu computador antes de aplicar. O limite Always Free Ampere e compartilhado pela conta e pode faltar capacidade de host (`Out of host capacity`); este cluster usa 2 OCPUs e 12 GB, alem da NAT instance.

Ao final, use a saida `kubeconfig_instructions` para obter o kubeconfig e abrir um tunel SSH para a API. Esse cluster e para laboratorio: nao inclui cloud controller manager OCI, storage class ou ingress controller; Services `LoadBalancer` nao receberao IP externo.
