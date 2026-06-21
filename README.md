# Network & Infrastructure Engineering Portfolio

Hands-on infrastructure, virtualisation, Windows Server, networking, and troubleshooting labs built during enterprise training at **Vatanix Technologies, Trichy**.

**Georgin Shaju** | BTech CSE | Diploma in Network Engineering (NACTET)
📧 georginparackal@gmail.com | 🔗 [LinkedIn](https://www.linkedin.com/in/georginshaju)

---

## What This Repository Documents

- VMware ESXi 8.0 deployment on a physical HPE ProLiant DL360 Gen9 enterprise server
- Windows Server 2019 administration — Active Directory, DNS, DHCP, Group Policy, OU/User management
- Cisco switching and routing — VLANs, SSH, Spanning Tree Protocol, Inter-VLAN Routing (SVI and Router-on-a-Stick), Static Routing
- Structured incident troubleshooting — 5 detailed case studies plus a quick-reference guide spanning hardware, OS, networking, AD, and Cisco topics

---

##  Lab Environment Note

This portfolio spans three separate environments, not one continuous setup:

- **Physical hardware** — VMware ESXi installed bare-metal on a real **HPE ProLiant DL360 Gen9** server, accessed via iLO. Covers initial hypervisor install and VM deployment only.
- **Native Windows Server machine** — Active Directory through Group Policy was first completed on a separate physical machine, booted directly into Windows Server (not virtualized).
- **VirtualBox** — the same AD-through-GPO scope was repeated here for additional practice. This is the round documented with screenshots in this repository.

---

## Projects

| # | Project | Description | Status |
|---|---|---|---|
| 1 | [Windows Server & ESXi Lab](Windows_Server/) | 6 labs — ESXi setup · AD DS · DNS · DHCP · GPO · OU & User Management | ✅ Complete |
| 2 | [Cisco Networking Labs](Cisco_Labs/) | 5 labs (in progress) — VLANs/SSH · STP · Inter-VLAN Routing (SVI + ROAS) · Static Routing | 🔄 In Progress |
| 3 | [Troubleshooting Cases](Troubleshooting_Cases/) | 5 detailed incident case studies + quick-reference guide covering the full training journey | ✅ Complete |

---

## Windows Server Labs

| Lab | Topic | Key Skills Demonstrated |
|-----|-------|--------------------------|
| [01](Windows_Server/01_ESXi_Server_Setup/) | ESXi & VM Deployment | Bare-metal ESXi · iLO · VMXNET3 · VMware Tools · POST diagnostics |
| [02](Windows_Server/02_Active_Directory_Domain_Setup/) | Active Directory & Domain Controller | AD DS · DC promotion · forest · domain join |
| [03](Windows_Server/03_DNS_Configuration/) | DNS Server Configuration | Forward/reverse zones · A records · PTR records · nslookup verification |
| [04](Windows_Server/04_DHCP_Configuration/) | DHCP Server Configuration | IPv4 scope · scope options · server authorization · lease verification |
| [05](Windows_Server/05_Group_Policy_Objects/) | Group Policy Objects | Logon banner · wallpaper · password policy · security filtering |
| [06](Windows_Server/06_OU_Users_Groups_Management/) | OUs, Users & Groups | OU design · user creation · security groups · ADUC · domain join verification |

---

## Cisco Networking Labs

| Lab | Topic | Key Skills Demonstrated | Status |
|-----|-------|--------------------------|--------|
| [01](Cisco_Labs/01_Basic_Switch_VLAN_SSH/) | Basic Switch Config, VLANs & SSH | Hostname · enable secret · VLANs · SVI · Telnet → SSH migration · RSA key | ✅ Complete |
| [02](Cisco_Labs/02_Spanning_Tree_Protocol/) | Spanning Tree Protocol | Root Bridge election · port roles · BLK→FWD failover · PortFast · BPDU Guard | ✅ Complete |
| [03](Cisco_Labs/03_Inter_VLAN_Routing_SVI/) | Inter-VLAN Routing — SVI | Layer-3 switch · SVI · trunking · `ip routing` · multi-switch routing | ✅ Complete |
| [04](Cisco_Labs/04_Inter_VLAN_Routing_ROS/) | Inter-VLAN Routing — Router-on-a-Stick | Router subinterfaces · 802.1Q encapsulation · ROAS vs SVI | ✅ Complete |
| [05](Cisco_Labs/05_Static_Routing/) | Static Routing | `ip route` · next-hop configuration · wrong subnet mask troubleshooting | 🔄 Standard routing complete, Default routing pending |
| 06 | OSPF Single Area | OSPF process · DR/BDR election | 🔄 Planned |
| 07 | Access Control Lists | Standard and Extended ACLs | 🔄 Planned |

---

## Troubleshooting Cases

5 detailed incident write-ups in NOC ticket format, drawn from real faults
diagnosed and resolved across the labs above, plus a [quick-reference
guide](Troubleshooting_Cases/Common_Troubleshooting_Scenarios.md) covering
common scenarios from hardware fundamentals through Cisco routing.

| Case | Incident | Severity |
|------|----------|----------|
| [INC-001](Troubleshooting_Cases/INC-001_DNS_Reverse_Lookup_Failure.md) | DNS Reverse Lookup Failure — Missing PTR Record | P3 |
| [INC-002](Troubleshooting_Cases/INC-002_DHCP_APIPA_Authorization_Failure.md) | Client Receiving APIPA Address — DHCP Not Authorized | P2 |
| [INC-003](Troubleshooting_Cases/INC-003_VLAN_Missing_From_Trunk_Database.md) | Cross-Switch VLAN Unreachable — Missing VLAN in Database | P2 |
| [INC-004](Troubleshooting_Cases/INC-004_Wrong_Subnet_Mask_Static_Route.md) | One-Way Connectivity Failure — Wrong Subnet Mask on Static Route | P2 |
| [INC-005](Troubleshooting_Cases/INC-005_Port_Err_Disabled_BPDU_Guard.md) | Access Port Err-Disabled — BPDU Guard Triggered | P3 |

---

## Lab in Action

### Physical Server — HPE ProLiant DL360 Gen9

> Front panel with ProLiant badge and status LEDs

![Server Front Panel](Windows_Server/01_ESXi_Server_Setup/screenshots/server-front.jpg)

> Internal view — dual CPU heatsinks, RAM slots, hot-swap fans

![Server Internals](Windows_Server/01_ESXi_Server_Setup/screenshots/server-internals.jpg)

---

### VMware ESXi 8.0 — Bare-Metal Hypervisor

> ESXi boot screen — 2x Xeon E5-2680 v4, 31.9 GiB recognised on physical server

![ESXi Boot](Windows_Server/01_ESXi_Server_Setup/screenshots/esxi-boot.jpg)

> POST diagnostics — confirms iLO 4 IP and a real DIMM memory fault found and documented

![POST Screen](Windows_Server/01_ESXi_Server_Setup/screenshots/post-screen-ilo-dimm-error.jpg)

> ESXi Host Client dashboard — VMs running, version 8.0 Update 3 confirmed

![ESXi Dashboard](Windows_Server/01_ESXi_Server_Setup/screenshots/esxi-dashboard.png)

> Datastore — 2.06 TB VMFS6 storage configured

![Storage](Windows_Server/01_ESXi_Server_Setup/screenshots/storage.png)

---

### Cisco — Spanning Tree Protocol Failover

> Root Bridge election confirmed, then live failover tested by shutting the primary uplink

![STP Failover](Cisco_Labs/02_Spanning_Tree_Protocol/screenshots/sw1-failover-blk-to-fwd.png)

---

## Skills

| Category | Tools & Technologies |
|---|---|
| **Virtualisation** | VMware ESXi 8.0, vSphere Host Client, VM deployment |
| **Server Hardware** | HPE ProLiant DL360 Gen9, iLO 4, hardware RAID |
| **Windows Server** | Windows Server 2019, AD DS, DNS, DHCP, GPO, Domain Controller |
| **Cisco Switching & Routing** | VLANs, SVI, SSH, STP, Router-on-a-Stick, Static Routing |
| **Networking Fundamentals** | TCP/IP, OSI Model, Subnetting, Ethernet, Structured Cabling |
| **Troubleshooting** | OSI layer-by-layer methodology, Windows Server, Cisco CLI |
| **Tools** | Cisco Packet Tracer, VirtualBox, draw.io, PuTTY |

---

## Key Lessons Learned

- Hardware troubleshooting starts at Layer 1 — always verify physical connections and POST diagnostics first
- Port identification matters — iLO and standard NIC ports look identical; the POST screen's iLO IP display is the fastest way to confirm which is which
- DNS misconfiguration breaks many Windows services — reverse lookup zones are not created automatically and must be added manually
- A DHCP server must be authorized in Active Directory before it will lease addresses — running the service alone is not sufficient
- VLANs must exist in the local VLAN database on every switch carrying their traffic — a trunk being "up" doesn't guarantee every VLAN is passing
- Static routing requires a correct route on every router in both directions — one wrong subnet mask anywhere breaks the path
- STP runs automatically on Cisco switches — always manually set the Root Bridge in production rather than relying on MAC address election
- PortFast and BPDU Guard together let access ports skip STP delay safely, while still protecting against unauthorized switch connections
- Group Policy requires `gpupdate /force` and a restart to apply Computer Configuration settings reliably

---

> 🔧 Actively built during a 60-Day IT Network & Hardware Training Journal at Vatanix Technologies, Trichy. Real hardware, real labs, real documentation — updated regularly.
