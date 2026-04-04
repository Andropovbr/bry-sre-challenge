# SRE Challenge — High Availability Web Service on Kubernetes (EKS)

## Overview
This project implements a highly available web service on Kubernetes using AWS EKS, focusing on infrastructure automation, observability, and resilience.

## Objectives
- Provision infrastructure using Terraform
- Deploy a web application on Kubernetes
- Expose the application securely via HTTPS
- Implement monitoring and observability
- Perform stress testing and analyze system behavior

## Architecture (High-Level)
(To be added)

## Tech Stack
- AWS (EKS, VPC, S3)
- Terraform
- Kubernetes
- NGINX Ingress
- cert-manager + Let's Encrypt
- Prometheus & Grafana
- k6 (stress testing)

## Project Structure
(you can paste your folder structure here)

## Current Status
- [x] Bootstrap (S3 backend)
- [ ] Network
- [ ] EKS
- [ ] Platform
- [ ] Observability
- [ ] Stress test

## Incremental Terraform Validation

The Terraform project was validated incrementally by creating the root module first and then adding functional stubs for the `network` and `eks` modules.

This approach made it possible to validate the project structure early, ensuring that module inputs and references were aligned before implementing the actual AWS resources.

## Network Module

The `network` module provisions the foundational AWS networking resources required by the project.

Implemented resources include:

- a dedicated VPC
- two public subnets across two Availability Zones
- two private subnets across two Availability Zones
- an Internet Gateway
- a single NAT Gateway for outbound internet access from private subnets
- public and private route tables with the appropriate associations

The public subnets are intended for internet-facing components such as the ingress load balancer, while the private subnets are reserved for the EKS worker nodes. This separation improves the security posture of the environment while keeping the architecture aligned with common AWS networking practices.

## EKS Module

The `eks` module provisions the Kubernetes control plane and worker nodes for the project.

Implemented resources include:

- an Amazon EKS cluster
- a managed node group
- IAM roles for the control plane and worker nodes
- IAM policy attachments required for EKS operation
- an OpenID Connect (OIDC) provider for future IAM Roles for Service Accounts (IRSA) integrations
- core EKS-managed add-ons:
  - VPC CNI
  - CoreDNS
  - kube-proxy

The cluster was configured to use private subnets for the worker nodes and both private and restricted public API access for cluster administration. This provides a balance between operational simplicity and improved security for the challenge environment.

## Ingress Controller

An NGINX Ingress Controller was deployed to the cluster using Helm.

The controller was exposed using a Kubernetes Service of type `LoadBalancer`, which automatically provisioned an AWS Network Load Balancer (NLB).

This component is responsible for routing external HTTP/HTTPS traffic into the cluster and will be used to expose the application in the next steps.

The decision to use NGINX Ingress aligns with the challenge requirements and provides a flexible and widely adopted solution for managing traffic routing in Kubernetes environments.

### Tooling

The following tools are required to interact with the Kubernetes cluster:

- kubectl
- Helm

Helm is used to install and manage Kubernetes packages such as the NGINX Ingress Controller and monitoring stack.

## Ingress Controller Deployment

The NGINX Ingress Controller is deployed using Helm through an automation script instead of manual ad-hoc commands.

This approach improves repeatability and makes the lab environment easier to destroy and recreate, which is especially useful for cost control and for demonstrating the setup during the recorded walkthrough.

The deployment uses:

- Helm repository configuration
- namespace creation if needed
- `helm upgrade --install` for idempotent installation
- a `LoadBalancer` service to expose the ingress controller externally

## Decisions (WIP)
(To be expanded)

## Next Steps
(To be expanded)