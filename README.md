# KubeForge — Production-Style Kubernetes on Proxmox with Terraform + Ansible

Provision a 5-node kubeadm Kubernetes cluster (1 control-plane + 4 workers) on a single
Proxmox host, fully automated: Terraform provisions VMs via cloud-init, Ansible configures
the OS and bootstraps Kubernetes. Zero manual clicking after the one-time template build.

## Architecture

See [`docs/architecture.md`](docs/architecture.md) for the full diagram.

| Component | Tool |
|---|---|
| VM provisioning | Terraform (`bpg/proxmox` provider) |
| Base OS image | Cloud-init (Ubuntu 24.04) |
| OS + K8s configuration | Ansible |
| Kubernetes | kubeadm (v1.31) |
| CNI | Calico |
| Container runtime | containerd |

## Naming Conventions

| Item | Value |
|---|---|
| Cluster name | `kubeforge-01` |
| Repo name | `kubeforge` |
| Template VM | `tpl-ubuntu-2404-cloudinit` (VMID 9000) |
| Control plane | `kf-cp-01` (VMID 8001, 192.168.1.101) |
| Workers | `kf-wk-01`…`kf-wk-04` (VMID 8002–8005, 192.168.1.102–105) |

## Prerequisites

- One working Proxmox VE host, reachable over the network.
- Terraform >= 1.6, Ansible >= 2.15, on your workstation.
- An SSH keypair for automation.

## Step-by-Step

### 1. Build the cloud-init template (one-time, on the Proxmox host)

```bash
# SSH into the Proxmox host as root, then:
cd /var/lib/vz/template/iso
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img

qm create 9000 --name tpl-ubuntu-2404-cloudinit --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk 9000 noble-server-cloudimg-amd64.img local-lvm
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --agent enabled=1
qm template 9000
```

### 2. Create a Proxmox API token

Datacenter → Permissions → API Tokens → Add.
User: `terraform-prov@pve`, Token ID: `terraform-token`, uncheck "Privilege Separation" for simplicity (or scope it down for production).
Grant the token `PVEAdmin` role on `/`.

### 3. Clone this repo and configure variables

```bash
git clone https://github.com/<you>/kubeforge.git
cd kubeforge/terraform
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: API token, SSH public key, network settings
```

### 4. Provision the VMs

```bash
terraform init
terraform plan
terraform apply
```

This creates `kf-cp-01` and `kf-wk-01..04`, and writes `../ansible/inventory/hosts.ini` automatically.

### 5. Bootstrap Kubernetes

```bash
cd ../ansible
ansible-playbook -i inventory/hosts.ini site.yml
```

### 6. Verify the cluster

```bash
ssh ubuntu@192.168.1.101
kubectl get nodes -o wide
kubectl get pods -A
```

Expected: 5 `Ready` nodes (1 control-plane, 4 `<none>`/worker).

### 7. Smoke test

```bash
kubectl create deployment hello --image=nginx --replicas=3
kubectl expose deployment hello --port=80 --type=NodePort
kubectl get pods -o wide   # confirm pods land on different workers
```

### 8. Document and publish

- Take screenshots at: template creation, `terraform apply` output, `kubectl get nodes`, running app.
- Push the repo to GitHub (`kubeforge`), add these screenshots to `docs/`.
- Write the LinkedIn/Facebook post around the build story (see prompt for drafts).

## Repo Structure

```
kubeforge/
├── README.md
├── docs/architecture.md
├── terraform/          # VM provisioning + cloud-init + inventory generation
└── ansible/             # OS config + kubeadm bootstrap (roles: common, containerd, kubernetes, control-plane, worker)
```

## Teardown

```bash
cd terraform
terraform destroy
```

## Notes / Production Hardening Ideas (good "future work" section for your article)

- Move `kf-cp-01` to a 3-node stacked-etcd control plane for real HA (needs 3+ physical hosts to be meaningful).
- Store `terraform.tfvars` secrets in Vault or SOPS instead of plaintext.
- Add `kube-vip` or an external load balancer in front of the control plane.
- Swap Calico for Cilium if you want eBPF-based networking as a follow-up post.
