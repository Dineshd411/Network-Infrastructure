# INC-004 — One-Way Connectivity Failure (Wrong Subnet Mask on Static Route)

| Field | Detail |
|---|---|
| **Severity** | P2 — Asymmetric routing failure, one-way communication only |
| **System Affected** | R2 (Router2), Cisco_Labs Lab 05 — Static Routing |
| **Reported By** | Self-identified during Lab 05 troubleshooting scenario |
| **Status** | ✅ Resolved |
| **Environment** | Cisco Packet Tracer, three-router static routing topology |

---

## Summary

A device on the PC0 LAN (192.168.10.0/24, behind R0) could reach R2's WAN
interface but could not reach R2's LAN (192.168.20.0/24, where PC4 sits) or
receive replies from it. WAN connectivity across all three routers was confirmed
working. Root cause was an incorrect subnet mask on R2's static route back to
PC0's network — `/30` instead of `/24` — causing R2 to silently fail to match
return traffic against the correct destination.

---

## Symptom

```
PC0> ping 20.20.20.1
Reply from 20.20.20.1: bytes=32 time=8ms TTL=253
Reply from 20.20.20.1: bytes=32 time=6ms TTL=253
Reply from 20.20.20.1: bytes=32 time=7ms TTL=253
Reply from 20.20.20.1: bytes=32 time=8ms TTL=253

PC0> ping 192.168.20.10
Request timed out.
Request timed out.
Request timed out.
Request timed out.

PC0> ping 192.168.20.1
Request timed out.
Request timed out.
Request timed out.
Request timed out.
```

R2's WAN interface (20.20.20.1) is fully reachable — but nothing behind it
responds, including R2's own LAN-facing interface.

---

## Diagnosis

**Step 1 — Isolate which segment of the path is failing**

Since `ping 20.20.20.1` succeeded, the WAN path R0 → R1 → R2 was confirmed
working end-to-end — both static routes on R0 and R1 were correct, and traffic
was crossing all three routers without issue.

Since `ping 192.168.20.1` (R2's own LAN interface) also failed, the problem was
not specific to PC4 — it pointed to something on R2 itself preventing return
traffic from reaching back toward PC0's network.

**Step 2 — Check R2's routing table**

```
R2# show ip route
```

```
S    192.168.10.0/30 [1/0] via 20.20.20.1
```

The static route for PC0's network was present — but using a **/30 mask
(255.255.255.252) instead of /24 (255.255.255.0)**. A /30 covers only 4 IP
addresses (192.168.10.0–192.168.10.3) — PC0's actual address, 192.168.10.10,
falls completely outside that range.

**Step 3 — Confirm via running-config**

```
R2# show run | include ip route
```

```
ip route 192.168.10.0 255.255.255.252 20.20.20.1
```

Confirmed the wrong mask was present in the active configuration, not just a
display artifact.

---

## Root Cause

When R2 needed to send a reply back to 192.168.10.10 (PC0), it checked its
routing table for a matching route. The configured static route only covered
192.168.10.0/30 — a 4-address block that does not include .10. Since no route
matched the actual destination, R2 had no path back to PC0's network and
silently dropped the return traffic. The forward path (PC0 → R2) worked because
R0 and R1 had correct /24 routes — only R2's return route was broken, creating
a one-way (asymmetric) failure that is easy to misdiagnose as a two-way outage
if WAN reachability isn't checked first.

---

## Fix

```
R2(config)# no ip route 192.168.10.0 255.255.255.252 20.20.20.1
R2(config)# ip route 192.168.10.0 255.255.255.0 20.20.20.1
```

> Note: attempting to add the correct route before removing the incorrect one
> using `no ip route 192.168.10.0 255.255.255.0 20.20.20.1` returned
> `%No matching route to delete` — confirming the stored route's mask really
> was /30, not /24, and had to be removed using its actual configured mask
> before the correct one could be added.

---

## Verification

```
R2# show ip route
```
```
S    192.168.10.0/24 [1/0] via 20.20.20.1
```

```
PC0> ping 192.168.20.10

Reply from 192.168.20.10: bytes=32 time=9ms TTL=126
Reply from 192.168.20.10: bytes=32 time=8ms TTL=126
Reply from 192.168.20.10: bytes=32 time=8ms TTL=126
Reply from 192.168.20.10: bytes=32 time=9ms TTL=126

Ping statistics for 192.168.20.10:
    Packets: Sent = 4, Received = 4, Lost = 0 (0% loss)
```

Full end-to-end connectivity restored in both directions.

---

## Impact if Left Unresolved

- Presents as intermittent or one-directional connectivity, which is
  significantly harder to diagnose than a full outage — the destination appears
  "almost reachable"
- Applications relying on bidirectional handshakes (TCP, authentication,
  any session-based protocol) fail completely even though basic WAN
  reachability looks fine
- A wrong subnet mask does not produce any error or warning when configured —
  the route installs successfully and only fails silently when traffic actually
  needs to match against it

---

## Root Cause Category

`Configuration Error — Incorrect Subnet Mask on Static Route`

---

## Lessons Learned

- A successful ping to a router's WAN interface only proves the WAN path is
  up — it says nothing about whether that router can route traffic onward to
  its own LAN or back to the source
- If a remote router's WAN interface is reachable but its own LAN interface or
  hosts behind it are not, the fault is almost always the **return route** on
  that specific router, not the forward path
- Subnet mask errors in static routes are invisible until tested — `show ip
  route` must be read carefully, comparing the actual mask against the intended
  network size, not just confirming a route with the right destination IP exists
- Static routing requires a correct route on every router for every remote
  network in both directions — one wrong mask on one router breaks the entire
  path even if every other router is configured perfectly
- `show run | include ip route` is the fastest way to audit every static route
  on a router in one view, rather than scrolling through the full config
