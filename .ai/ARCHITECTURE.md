# Architecture

## Current repository architecture

Terraform is split into organization, lab, and Kubernetes environments. The Kubernetes environment targets an existing VCN and creates an IGW, route tables, security lists, two subnets, two Ampere VMs, and an Always Free NAT instance.

The intended Kubernetes layout is one public control-plane VM and one private worker VM. The VCN is `10.251.0.0/16`; subnets are `10.251.1.0/24` (public) and `10.251.2.0/24` (private).

Private egress is selectable with `nat_mode`: `instance` (current) routes the private subnet through the NAT instance's private IP; `gateway` would use a NAT Gateway. The OCI tenancy limit `vcn/nat-gateway-count` is `0`, so the Gateway path stays inactive pending support ticket `CAM-274296`. The remaining blocker is `VM.Standard.A1.Flex` host capacity, unavailable in every `us-ashburn-1` AD. Cloud-init kubeadm bootstrap is restored in the config but has not run on a live cluster.

## Context-layer layout

```text
Tool-specific adapter (optional)
            ↓
        AGENTS.md
            ↓
          .ai/
  project · architecture · conventions · decisions
  tasks · handoff · tools · validation · workflows · prompts
```

`.ai/` is the portable source of truth. Tool-specific adapters must only route agents to it.

## Recommended convention

Document the architecture that exists, not an idealized future design. Mark facts as observed, inferences as inferred, proposed patterns as recommended, and unavailable facts as unknown.
