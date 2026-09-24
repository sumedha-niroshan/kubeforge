# KubeForge Architecture

```mermaid
flowchart TB
    subgraph Proxmox["Proxmox VE Host (pve)"]
        TPL["tpl-ubuntu-2404-cloudinit (VMID 9000)<br/>cloud-init golden template"]
        subgraph Cluster["kubeforge-01 cluster"]
            CP["kf-cp-01 (8001)<br/>control-plane<br/>192.168.1.101"]
            W1["kf-wk-01 (8002)<br/>192.168.1.102"]
            W2["kf-wk-02 (8003)<br/>192.168.1.103"]
            W3["kf-wk-03 (8004)<br/>192.168.1.104"]
            W4["kf-wk-04 (8005)<br/>192.168.1.105"]
        end
        TPL -.clone.-> CP
        TPL -.clone.-> W1
        TPL -.clone.-> W2
        TPL -.clone.-> W3
        TPL -.clone.-> W4
    end

    TF["Terraform<br/>(bpg/proxmox provider)"] -->|provisions + cloud-init| Proxmox
    TF -->|generates| INV["ansible/inventory/hosts.ini"]
    ANS["Ansible<br/>(site.yml)"] -->|reads| INV
    ANS -->|configures OS, containerd, kubeadm| Cluster
    CP -->|kubeadm join| W1
    CP -->|kubeadm join| W2
    CP -->|kubeadm join| W3
    CP -->|kubeadm join| W4
```

**Flow:** Terraform clones the cloud-init template into 5 VMs, injects SSH keys/network/hostname via cloud-init, and writes the Ansible inventory. Ansible then installs containerd + kubeadm on all nodes, runs `kubeadm init` + Calico on `kf-cp-01`, and joins the four `kf-wk-*` workers.
