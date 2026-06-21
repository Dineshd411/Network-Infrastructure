# Windows Server & ESXi Lab — Enterprise Infrastructure Case Study

**Vatanix Technologies, Trichy**

A complete enterprise infrastructure build — from bare-metal hypervisor installation
through Active Directory, DNS, DHCP, and Group Policy — documented as individual labs.

---

##  Environment Note

These labs were built across two different environments, not a single continuous setup:

- **Lab 01** — VMware ESXi installed bare-metal on the physical **HPE ProLiant DL360 Gen9**
  server. This is real enterprise hardware accessed via iLO.
- **Labs 02–06** — Active Directory, DNS, DHCP, GPO, and OU/User management were first
  completed on a separate physical Windows Server machine (booted natively), then
  **repeated in VirtualBox** for additional practice. The documentation and screenshots
  below are from the VirtualBox round. These labs use domain `mylab.local` and DC
  hostname `WS2K19-DC01`.

The two environments are documented separately below so the hardware context for each
lab is accurate.

---

## Lab Index

| # | Lab | Environment | Topics Covered | Status |
|---|-----|-------------|-----------------|--------|
| 01 | [ESXi Server Setup](01_ESXi_Server_Setup/) | Physical HPE ProLiant DL360 Gen9 | Bare-metal ESXi install · vSphere Host Client · VM deployment · VMXNET3 · VMware Tools | ✅ Complete |
| 02 | [Active Directory Domain Setup](02_Active_Directory_Domain_Setup/) | VirtualBox / separate machine | AD DS role · DC promotion · Forest creation · Domain join | ✅ Complete |
| 03 | [DNS Configuration](03_DNS_Configuration/) | VirtualBox / separate machine | Forward/reverse lookup zones · A records · PTR records · nslookup verification | ✅ Complete |
| 04 | [DHCP Configuration](04_DHCP_Configuration/) | VirtualBox / separate machine | IPv4 scope · Scope options · Server authorization · Lease verification | ✅ Complete |
| 05 | [Group Policy Objects](05_Group_Policy_Objects/) | VirtualBox / separate machine | Logon banner · Wallpaper enforcement · Password policy · Security filtering | ✅ Complete |
| 06 | [OU, Users & Groups Management](06_OU_Users_Groups_Management/) | VirtualBox / separate machine | OU design · User creation · Security groups · ADUC · Domain join verification | ✅ Complete |

---

## Lab 01 Environment — Physical Hardware

### HPE ProLiant DL360 Gen9

| Component | Details |
|---|---|
| Server Model | HP ProLiant DL360 Gen9 |
| CPU | 2x Intel Xeon E5-2680 v4 @ 2.40GHz |
| Total vCPUs | 28 |
| RAM | ~32 GB |
| Storage | ~2 TB VMFS6 Datastore |
| Management | HPE iLO 4 |

### Network Design (Lab 01 — ESXi Host)

| Device | IP Address | Role |
|---|---|---|
| ESXi Host | 10.10.11.14 (Static) | Hypervisor management |
| iLO Interface | 10.10.11.13 | Remote hardware management |

This server hosted the initial Windows Server 2019 VM deployment in Lab 01. From
Lab 02 onward, domain configuration work moved to a separate environment — see below.

---

## Labs 02–06 Environment — VirtualBox (Second Practice Round)

These labs were first completed on a separate physical Windows Server machine,
then repeated in VirtualBox for additional practice. Details below describe the
VirtualBox round, which is what's documented in this repository.

| Component | Detail |
|---|---|
| Domain | mylab.local |
| DC Hostname | WS2K19-DC01 |
| DC IP | 10.10.11.119 |
| Client Hostname | Oprekin-PC |
| Hypervisor | VirtualBox |

### AD Structure Built

```
mylab.local (Domain)
├── Domain Controllers OU
│   └── WS2K19-DC01 (DC)
└── KANNUR OU
    ├── Users
    │   └── GEO SHA (geo.user@mylab.local)
    └── Computers
        └── Oprekin-PC
```

---

## Lab Format

Each lab folder contains:

- `README.md` — objective, environment, step-by-step configuration with explanations, verification commands, common issues, lessons learned
- `screenshots/` — visual proof of configuration and verification (where available)

---

## Overall Challenges Faced

| Challenge | Lab | Root Cause | Resolution |
|---|---|---|---|
| VM network showing 100 Mbps | 01 | E1000 NIC selected, VMware Tools not installed | Changed to VMXNET3, installed VMware Tools |
| Host unreachable after cable plug-in | 01 | Ethernet cable plugged into iLO port instead of standard NIC | Identified port mismatch, moved cable to correct NIC port |
| nslookup showing "Unknown" | 03 | Reverse lookup zone not configured | Created reverse lookup zone + PTR record |
| GPO not applying on client | 05 | gpupdate not run after policy linked | Ran `gpupdate /force` and restarted client |

---

## Overall Lessons Learned

- Layer 1 first — always verify physical connections before any software diagnosis
- iLO and standard NIC ports look identical — label or trace cables carefully before plugging in
- VMware Tools is mandatory — install immediately after OS deploy; VMXNET3, time sync, and graceful shutdown all depend on it
- PTR records are not automatic — always create reverse lookup zones and add PTR records manually
- GPO needs a push — `gpupdate /force` + restart is required for policies to apply immediately
- DSRM password must be stored safely — it is the only AD recovery option if domain services fail
- DHCP and DNS work together — a client with a valid DHCP-assigned IP still needs the correct DNS option to resolve the domain

---

> Built as part of the 60-Day IT Network & Hardware Training Journal at Vatanix Technologies, Trichy. Real hardware and virtual lab environments, real documentation.
