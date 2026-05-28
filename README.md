# Orbit Cloud

## Overview
Orbit Cloud is a high‑availability, bare‑metal cloud platform built from the ground up. It provides automated orchestration via Kubernetes, distributed object storage with MinIO, and full Infrastructure‑as‑Code (IaC) provisioning. The platform demonstrates production‑grade fault tolerance and automated scaling for on‑premise environments.

## Features
- **High Availability**: Redundant services and failover mechanisms.
- **Kubernetes Orchestration**: Deploy workloads with built‑in clustering and self‑healing.
- **Object Storage**: MinIO provides S3‑compatible storage across the cluster.
- **Infrastructure as Code**: All resources are defined declaratively for repeatable deployments.
- **Scalable Architecture**: Horizontal scaling of compute and storage nodes.

## Project Structure
- `ansible/` – Ansible playbooks for provisioning and configuring bare‑metal nodes.
- `installer/` – Installer scripts and binaries for bootstrapping the environment.
- `kubernetes/` – Helm charts, manifests, and custom resources for the Kubernetes control plane.
- `scripts/` – Utility PowerShell scripts for prerequisite checks and maintenance tasks.
- `setup-wizard/` – Interactive PowerShell wizard guiding initial setup.
- `ui/` – Front‑end UI (web dashboard) source code.
- `vagrant/` – Vagrant configurations for local development and testing.
- `.gitignore` – Standard ignore patterns for this repository.
- `README.md` – Project documentation (this file).

## Getting Started
1. **Prerequisites**: Run the prerequisite script:
   ```powershell
   ./scripts/install_prereqs.ps1
   ```
2. **Run Setup Wizard**: Execute the PowerShell wizard to configure the cluster:
   ```powershell
   ./setup-wizard/check_syntax.ps1
   ```
3. **Deploy Kubernetes**: Use the Ansible playbooks in `ansible/` to provision nodes and deploy the control plane.
4. **Access UI**: After deployment, the web dashboard is available at `https://<node-ip>`.

For detailed instructions, refer to the documentation in each subdirectory.
