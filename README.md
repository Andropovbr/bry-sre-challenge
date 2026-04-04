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

## Decisions (WIP)
(To be expanded)

## Next Steps
(To be expanded)