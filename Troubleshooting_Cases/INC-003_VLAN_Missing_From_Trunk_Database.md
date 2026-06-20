# INC-003 — Cross-Switch VLAN Unreachable (Missing VLAN in Local Database)

| Field | Detail |
|---|---|
| **Severity** | P2 — One VLAN fully unreachable across switches |
| **System Affected** | MLS1, MLS2 (Cisco 3560-24PS), Cisco_Labs Lab 03 — Inter-VLAN Routing SVI |
| **Reported By** | Self-identified during Lab 03 troubleshooting scenario |
| **Status** | ✅ Resolved |
| **Environment** | Cisco Packet Tracer |

---

## Summary

A device in VLAN 20 on MLS1 could not reach a device in VLAN 30 on MLS2, despite
the trunk link between the two switches being up and both switches having
`ip routing` enabled. Root cause was VLAN 30 missing from MLS1's local VLAN
database — a switch will not forward or route traffic for a VLAN it does not
know about locally, even if that VLAN is carried correctly across an incoming
trunk.

---

## Symptom

```
PC2> ping 192.168.30.10

Pinging 192.168.30.10 with 32 bytes of data:
Request timed out.
Request timed out.
Request timed out.
Request timed out.

Ping statistics for 192.168.30.10:
    Packets: Sent = 4, Received = 0, Lost = 4 (100% loss)
```

Other connectivity in the topology was unaffected — PC0 and PC1 (VLAN 10) could
reach all destinations normally.

---

## Diagnosis

**Step 1 — Confirm the trunk link is physically and logically up**

```
MLS1# show interfaces trunk
```

```
Port    Mode    Encapsulation  Status    VLANs Allowed
Fa0/5   on      802.1q         trunking  1,10,20
```

The trunk was active — but the **Allowed VLANs list only showed 1, 10, 20**.
VLAN 30 was missing from the list entirely on the MLS1 side of the trunk.

**Step 2 — Check the local VLAN database**

```
MLS1# show vlan brief
```

```
VLAN  Name      Status    Ports
1     default   active
10    SALES     active    Fa0/1, Fa0/2
20    HR        active    Fa0/3
```

**VLAN 30 did not exist anywhere in MLS1's VLAN database.** This confirmed the
trunk output — a VLAN can only appear as "allowed" on a trunk if it exists
locally first.

**Step 3 — Confirm MLS2 had VLAN 30 correctly configured**

```
MLS2# show vlan brief
```

```
VLAN  Name      Status    Ports
1     default   active
10    SALES     active    Fa0/1, Fa0/2
30    ACCOUNTS  active    Fa0/3
```

MLS2 was correctly configured — the fault was isolated entirely to MLS1.

---

## Root Cause

A switch will only forward, flood, or route traffic for VLANs that exist in its
own local VLAN database — regardless of what is arriving correctly tagged on a
trunk port from a neighbouring switch. MLS2 was sending VLAN 30 tagged frames
across the trunk correctly, but MLS1 silently dropped them because VLAN 30 had
never been created on MLS1. Since MLS1 was also the routing hub for this topology
(holding the SVI for VLAN 30), the SVI itself could not come up either, since an
SVI requires its corresponding VLAN to exist first.

---

## Fix

```
MLS1(config)# vlan 30
MLS1(config-vlan)# name ACCOUNTS
MLS1(config-vlan)# exit
```

Creating the VLAN entry automatically allowed it to register on the trunk as
well, since the trunk's default behaviour is to carry all locally-known VLANs
unless explicitly restricted.

---

## Verification

```
MLS1# show vlan brief
```
```
30    ACCOUNTS  active
```

```
MLS1# show interfaces trunk
```
```
Port    Mode    Encapsulation  Status    VLANs Allowed
Fa0/5   on      802.1q         trunking  1,10,20,30
```

```
PC2> ping 192.168.30.10

Reply from 192.168.30.10: bytes=32 time=2ms TTL=127
Reply from 192.168.30.10: bytes=32 time=1ms TTL=127
Reply from 192.168.30.10: bytes=32 time=1ms TTL=127
Reply from 192.168.30.10: bytes=32 time=2ms TTL=127

Ping statistics for 192.168.30.10:
    Packets: Sent = 4, Received = 4, Lost = 0 (0% loss)
```

---

## Impact if Left Unresolved

- An entire VLAN becomes a silent island — reachable from its local switch but
  invisible to the rest of the network, with no error or alarm raised anywhere
- Symptoms point misleadingly toward the trunk or physical link, when the trunk
  itself is functioning correctly — wasted time checking cabling or interface
  status instead of the VLAN database
- In a larger production network, this fault could go unnoticed for a long time
  if the affected VLAN has low traffic volume, since nothing fails loudly

---

## Root Cause Category

`Configuration Omission — VLAN Database Inconsistency Across Switches`

---

## Lessons Learned

- Every VLAN must exist in the local VLAN database on every switch that needs to
  carry or route its traffic — even switches with no access ports in that VLAN
- `show interfaces trunk` and `show vlan brief` together tell the full story —
  the trunk being "up" does not mean every VLAN is actually being carried
- When a single VLAN is unreachable but everything else works, the fault is
  almost always at Layer 2 VLAN database level, not Layer 1 cabling or Layer 3
  routing — narrow the search accordingly
- This fault is invisible from `show ip route` alone, since a missing VLAN
  prevents the SVI from existing in the first place — always check VLAN and
  trunk state before assuming a routing problem
