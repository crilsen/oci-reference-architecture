# Hello World with GKE Ingress

The application is published by the GKE Ingress controller through an external
Google Cloud Application Load Balancer:

```text
Internet -> global static IP -> GKE Ingress -> NEG -> ClusterIP Service -> Pod
```

The `Service` remains `ClusterIP`. The Ingress creates the Load Balancer and the
NEG annotation connects Pods directly to its backend, avoiding a second Load
Balancer.

## 1. Reserve the public IP

Apply Terraform before the Kubernetes manifest:

```bash
cd gcp/environments/lab
terraform plan
terraform apply
terraform output hello_world_public_ip
cd ../../..
```

Create an `A` record with your DNS provider before deploying the Ingress:

```text
Name:  gcp-test
Type:  A
Value: <terraform output hello_world_public_ip>
TTL:   300
```

The final FQDN in this public example is `gcp-test.example.com`. The
`example.com` domain is reserved for documentation and cannot be configured by
users. Before deploying, replace it in `hello-world.yaml` with a hostname in a
domain you control, then create the corresponding DNS record.

## 2. Deploy

```bash
kubectl apply -f kubernetes/hello-world/hello-world.yaml
kubectl rollout status deployment/hello-world -n lab-workloads
kubectl get pods,service,ingress,managedcertificate -n lab-workloads
```

GKE can take 5 to 15 minutes to finish the global Load Balancer. Follow its
progress with:

```bash
kubectl describe ingress hello-world -n lab-workloads
kubectl get ingress hello-world -n lab-workloads --watch
kubectl describe managedcertificate hello-world-certificate -n lab-workloads
```

When the Ingress has an address and the certificate status is `Active`, open:

```bash
curl "https://gcp-test.example.com"
curl "https://gcp-test.example.com/healthz"
```

## Remove

Delete the Ingress before destroying Terraform so GKE can clean up all managed
Load Balancer components:

```bash
kubectl delete -f kubernetes/hello-world/hello-world.yaml
terraform -chdir=gcp/environments/lab destroy
```

An external Application Load Balancer, health checks, forwarding rules, public
IP, logging, and network traffic can generate charges against the trial credit.
