# Cisco Networking Labs

Hands-on Cisco IOS labs built in Packet Tracer and GNS3 during network engineering training at Vatanix Technologies, Trichy.

---

## Lab Format

Each lab includes:
- Topology diagram (PNG)
- Device configuration files (`.txt`)
- Verification outputs (`show` commands)
- Brief lab report (objectives, steps, findings)

---

## Labs

| Lab | Topics Covered | Tools | Status |
|---|---|---|---|
| Lab 01 — VLANs & Trunking | VLAN creation, trunk ports, `show vlan brief` | Packet Tracer | 🔄 In Progress |
| Lab 02 — Inter-VLAN Routing | Router-on-a-stick, subinterfaces, `show ip route` | Packet Tracer | 🔄 In Progress |
| Lab 03 — OSPF Single Area | OSPF process, DR/BDR election, `show ip ospf neighbor` | GNS3 | 🔄 In Progress |
| Lab 04 — STP | Spanning Tree, root bridge, port states | Packet Tracer | 🔄 In Progress |
| Lab 05 — ACLs | Standard and extended access lists, `show access-lists` | Packet Tracer | 🔄 In Progress |

---

## Essential Cisco IOS Commands Reference

```bash
# --- Show Commands ---
show version                    # IOS version, uptime, hardware
show running-config             # Current active configuration
show ip interface brief         # Interface status and IPs
show vlan brief                 # VLAN list and assigned ports
show interfaces trunk           # Trunk port status
show ip route                   # Routing table
show ip ospf neighbor           # OSPF neighbour relationships
show ip ospf interface          # OSPF interface details
show access-lists               # ACL entries and hit counts
show spanning-tree              # STP port states and root bridge

# --- Basic Config ---
enable
configure terminal
hostname R1
no ip domain-lookup             # Stop DNS lookup on mistyped commands

# --- Interface Config ---
interface GigabitEthernet0/0
 ip address 192.168.1.1 255.255.255.0
 no shutdown

# --- VLAN Config (Switch) ---
vlan 10
 name Sales
vlan 20
 name IT
interface FastEthernet0/1
 switchport mode access
 switchport access vlan 10
interface FastEthernet0/24
 switchport mode trunk

# --- OSPF Config ---
router ospf 1
 router-id 1.1.1.1
 network 192.168.1.0 0.0.0.255 area 0

# --- ACL Config ---
access-list 100 permit tcp 192.168.1.0 0.0.0.255 any eq 80
access-list 100 deny ip any any
interface GigabitEthernet0/0
 ip access-group 100 in
```

> Labs and Packet Tracer files will be added as training progresses.
