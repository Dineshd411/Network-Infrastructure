# Lab Architecture Notes

## Physical Infrastructure

- **Server:** HPE ProLiant DL360 Gen9 — 1U rack server
- **Hypervisor:** VMware ESXi 8.0 Update 3 (Build 24677879) — bare-metal Type 1
- **Management:** HPE iLO 4 at 10.10.11.13 — remote KVM, power control, health monitoring
- **Storage:** Single VMFS6 datastore — 2.06 TB total, 773 GB used

## Why ESXi on Physical Hardware Matters

Most training environments use nested virtualisation (VMs inside VMs) which does not reflect real production infrastructure. This lab uses:
- A real enterprise 1U rack server
- Bare-metal hypervisor installation (not installed on top of Windows/Linux)
- Real hardware RAID controller (HPE Smart Array P440ar)
- Real server management interface (iLO 4)

This mirrors how enterprise infrastructure is actually deployed in datacentres.

## Key Configuration Decisions

| Decision | Choice | Reason |
|---|---|---|
| VM NIC type | VMXNET3 | Paravirtualised — faster than emulated E1000 |
| Disk type | Thin provisioned | Saves datastore space in lab environment |
| OS edition | Desktop Experience | GUI needed for lab work — Server Core for production |
| Domain name | georgi.local | Internal-only domain — .local suffix standard for AD labs |
| DHCP scope | 10.10.11.50–100 | Leaves room for static assignments below .50 |

## Tools Used

| Tool | Purpose |
|---|---|
| VMware vSphere Host Client | ESXi web-based management interface |
| Rufus | Creating bootable USB for ESXi and Windows Server |
| Active Directory Users & Computers (ADUC) | Managing domain objects |
| Group Policy Management Console (GPMC) | Creating and linking GPOs |
| DNS Manager | Zone and record management |
| DHCP Manager | Scope and lease management |
| PowerShell | Automation and verification commands |
| iLO 4 Web Interface | Remote server hardware management |
