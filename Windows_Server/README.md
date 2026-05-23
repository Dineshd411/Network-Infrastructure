# Windows Server & ESXi Lab — Enterprise Infrastructure Case Study

**Environment:** VMware ESXi 8.0 U3 on HPE ProLiant DL360 Gen9 (physical hardware)
**OS Deployed:** Windows Server 2019 Standard — Desktop Experience
**Domain:** georgi.local
**Completed:** May 2026 | Vatanix Technologies, Trichy

---

## Objectives

- Install VMware ESXi 8.0 bare-metal on a physical enterprise server
- Deploy Windows Server 2019 as a VM via vSphere Host Client
- Promote server to Domain Controller and build a working AD domain
- Configure DNS with forward and reverse lookup zones
- Set up DHCP for automatic client IP assignment
- Apply Group Policies across domain-joined client machines
- Diagnose and resolve real hardware and configuration issues encountered

---

## Environment Setup

### Physical Hardware

| Component | Details |
|---|---|
| Server Model | HP ProLiant DL360 Gen9 |
| CPU | 2x Intel Xeon E5-2680 v4 @ 2.40GHz |
| Total vCPUs | 28 |
| RAM | ~32 GB |
| Storage | ~2 TB VMFS6 Datastore |
| Management | HPE iLO 4 |

### Network Design

| Device | IP Address | Role |
|---|---|---|
| ESXi Host | 10.10.11.14 (Static) | Hypervisor management |
| iLO Interface | 10.10.11.13 | Remote hardware management |
| Windows Server 2019 | Static assigned | Domain Controller, DNS, DHCP |
| Default Gateway / DNS | 10.10.11.1 | Network gateway |
| Client VM | DHCP assigned | Domain-joined client |

### Virtual Machines

| VM Name | OS | Storage | Purpose |
|---|---|---|---|
| windows-server-2019 | Windows Server 2019 | 150 GB | Domain Controller |
| client-vm | Windows Server 2019 | 150 GB | Domain-joined client |

---

## Phase 1 — ESXi Installation

### Steps Performed

1. Downloaded VMware ESXi 8.0 U3 ISO
2. Created bootable USB using Rufus — GPT partition scheme, UEFI mode
3. Booted HPE DL360 Gen9 — pressed F11 for Boot Menu, selected USB
4. Ran ESXi installer — accepted EULA, selected local storage, set root password
5. Configured static management IP: `10.10.11.14`
6. Set DNS: `10.10.11.1` and gateway: `10.10.11.1`
7. Accessed vSphere Host Client via browser: `https://10.10.11.14`
8. Uploaded Windows Server 2019 ISO to datastore via Datastore Browser

---

## Phase 2 — VM Deployment

### VM Configuration — Windows Server 2019

| Setting | Value |
|---|---|
| vCPUs | 4 (2 sockets × 2 cores) |
| RAM | 8 GB |
| Disk | 150 GB thin provisioned VMDK |
| NIC | VMXNET3 (paravirtualised) |
| OS | Windows Server 2019 Standard (Desktop Experience) |

### Key Decisions

**VMXNET3 over E1000** — VMXNET3 is a paravirtualised driver optimised for ESXi. E1000 emulates a physical Intel NIC and is slower. VMXNET3 requires VMware Tools to activate fully.

**Thin provisioned disk** — disk file grows as data is written, saving datastore space. Suitable for lab VMs.

**VMware Tools** — installed immediately after OS install. Activates VMXNET3 driver, enables memory ballooning, fixes time synchronisation, and allows graceful shutdown from vSphere.

---

## Phase 3 — Active Directory Setup

### Steps Performed

1. Server Manager → Add Roles and Features → Active Directory Domain Services
2. After install: flag icon → Promote this server to Domain Controller
3. Selected: Add a new forest → Root domain name: `georgi.local`
4. Set DSRM password → completed promotion → server rebooted as Domain Controller
5. Opened Active Directory Users & Computers — verified domain structure

### AD Structure Built

```
georgi.local (Domain)
├── Domain Controllers OU
│   └── WINSERVER2019 (DC)
└── IT OU
    ├── Users
    │   └── trainee01
    └── Computers
        └── client-vm
```

### PowerShell Verification

```powershell
Get-ADDomainController
Get-ADUser -Filter *
Get-ADOrganizationalUnit -Filter *
Get-ADDomain
```

---

## Phase 4 — DNS Configuration

### Steps Performed

1. Installed DNS Server role via Server Manager
2. Created Forward Lookup Zone: `georgi.local`
3. Created Reverse Lookup Zone for `10.10.11.x` subnet
4. Added PTR record for Domain Controller
5. Verified using `nslookup` in PowerShell

### Issue Found and Fixed

```
Problem : nslookup showing "Unknown" for server name
Cause   : Reverse lookup zone was missing — PTR record did not exist
Fix     : Created reverse lookup zone + added PTR record manually
Result  : nslookup correctly resolved DC hostname
```

### Verification Commands

```powershell
nslookup georgi.local
nslookup 10.10.11.x
Get-Service DNS
Get-DnsServerZone
```

---

## Phase 5 — DHCP Configuration

### Steps Performed

1. Installed DHCP Server role
2. Created IPv4 scope for client IP range
3. Set scope options — Default Gateway and DNS Server IP
4. Authorized DHCP server in Active Directory
5. Client VM received IP automatically on domain join

### DHCP Scope Settings

| Setting | Value |
|---|---|
| IP Range | 10.10.11.50 – 10.10.11.100 |
| Subnet Mask | 255.255.255.0 |
| Default Gateway | 10.10.11.1 |
| DNS Server | DC IP address |
| Lease Duration | 8 days |

---

## Phase 6 — Group Policy Lab

### Policies Applied

| Policy | Linked To | Effect | Verified |
|---|---|---|---|
| Logon Warning Message | Domain | Custom banner at every login | ✅ |
| Forced Desktop Wallpaper | IT OU | Company wallpaper — users cannot change it | ✅ |
| Disable Right-Click | IT OU | Context menu disabled on client desktop | ✅ |

### Commands Used

```powershell
gpupdate /force      # Force immediate GPO refresh
gpresult /r          # View all applied GPOs
gpmc.msc             # Open Group Policy Management Console
# Revert to workgroup: Win+R → sysdm.cpl → Computer Name → Change
```

---

## Challenges Faced

| Challenge | Root Cause | Resolution |
|---|---|---|
| nslookup showing "Unknown" | Reverse lookup zone not configured | Created reverse lookup zone + PTR record |
| GPO not applying on client | gpupdate not run after policy linked | Ran `gpupdate /force` and restarted client |
| VM network showing 100 Mbps | E1000 NIC selected, VMware Tools not installed | Changed to VMXNET3, installed VMware Tools |
| Host unreachable after cable plug-in | Ethernet cable plugged into iLO port instead of standard NIC | Identified port mismatch, moved cable to correct NIC port |

---

## Lessons Learned

- **Layer 1 first** — always verify physical connections before any software diagnosis
- **iLO and standard NIC ports look identical** — label or trace cables carefully before plugging in
- **PTR records are not automatic** — always create reverse lookup zones and add PTR records manually
- **VMware Tools is mandatory** — install immediately after OS deploy; VMXNET3, time sync, and graceful shutdown all depend on it
- **GPO needs a push** — `gpupdate /force` + restart is required for policies to apply immediately
- **DSRM password must be stored safely** — it is the only AD recovery option if domain services fail

---

## Screenshots

| Screenshot | Description |
|---|---|
| ![Server Front](screenshots/server-front.jpg) | HPE DL360 Gen9 front panel |
| ![Server Internals](screenshots/server-internals.jpg) | Internal — dual CPUs, RAM, fans |
| ![ESXi Boot](screenshots/esxi-boot.jpg) | ESXi 8.0.3 booting on physical server |
| ![ESXi Login](screenshots/esxi-login.jpg) | ESXi Host Client login page |
| ![ESXi Dashboard](screenshots/esxi-dashboard.png) | Host dashboard — VMs, RAM, storage |
| ![VM List](screenshots/vm-list.png) | VMs deployed and running |
| ![Storage](screenshots/storage.png) | VMFS6 datastore |
| ![Hardware Details](screenshots/hardware-details.png) | Hardware spec and network config |
