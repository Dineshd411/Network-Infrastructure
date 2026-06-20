# INC-005 — Access Port Err-Disabled After Unauthorized Switch Connection

| Field | Detail |
|---|---|
| **Severity** | P3 — Single port down, no wider network impact |
| **System Affected** | SW1, Cisco_Labs Lab 02 — Spanning Tree Protocol |
| **Reported By** | Scenario based on BPDU Guard configuration in Lab 02 |
| **Status** | ✅ Resolved |
| **Environment** | Cisco Packet Tracer |

> **Note:** This case is built around the PortFast and BPDU Guard configuration
> completed in Lab 02. It documents the expected and standard recovery procedure
> for this exact fault condition, based on Cisco's documented BPDU Guard
> behaviour and the configuration already verified working in that lab.

---

## Summary

A PC's access port on SW1 stopped passing traffic after a small unmanaged switch
was connected to it. The port had PortFast and BPDU Guard enabled, as configured
in Lab 02. BPDU Guard detected an incoming BPDU on the access port — the
signature of another switch being connected — and immediately placed the port
into `err-disabled` state to protect the Spanning Tree topology, exactly as
designed.

---

## Symptom

The originally connected PC lost all network connectivity. The port's link
light was off, and the device connected to it could not obtain an IP via DHCP
or reach the gateway.

```
SW1# show interfaces fa0/3 status

Port      Name              Status       Vlan       Duplex  Speed Type
Fa0/3                       err-disabled 10         auto    auto  10/100BaseTX
```

---

## Diagnosis

**Step 1 — Confirm the port state**

```
SW1# show interfaces fa0/3 status
```

Status showed `err-disabled` — not `down`, `notconnect`, or `disabled`. This
specific status only occurs when a protective mechanism (port security, BPDU
Guard, storm control, etc.) has automatically shut the port down — it is never
a manual or physical-layer state.

**Step 2 — Identify which protection mechanism triggered it**

```
SW1# show spanning-tree interface fa0/3 detail
```

or check the system log:

```
SW1# show logging
```

```
%SPANTREE-2-BLOCK_BPDUGUARD: Received BPDU on port FastEthernet0/3 with BPDU
Guard enabled. Disabling port.
%PM-4-ERR_DISABLE: bpduguard error detected on Fa0/3, putting Fa0/3 in err-disable state
```

This confirmed BPDU Guard was the specific trigger — the port received a BPDU,
meaning a switch (not an end device) was connected to what was configured as a
PortFast access port.

**Step 3 — Confirm the configuration matches Lab 02's intended setup**

```
SW1# show running-config interface fa0/3
```

```
interface FastEthernet0/3
 switchport mode access
 switchport access vlan 10
 spanning-tree portfast
 spanning-tree bpduguard enable
```

Configuration was correct and exactly as intended — BPDU Guard had functioned
precisely as designed, not malfunctioned. The "fault" was the unauthorized
switch connection, not the configuration.

---

## Root Cause

A small unmanaged or consumer-grade switch was connected to a port that was
deliberately configured for a single end device using PortFast. PortFast ports
are not expected to ever see BPDUs, since only switches generate them — a PC
or printer never sends a BPDU. BPDU Guard treats any BPDU arriving on such a
port as a violation of that assumption and immediately disables the port to
prevent a potential Spanning Tree loop or topology change caused by an
unauthorized device.

---

## Fix

**Step 1 — Physically disconnect the unauthorized switch** from the port before
re-enabling it — re-enabling without removing the cause will trigger the same
shutdown again within seconds.

**Step 2 — Recover the port**

```
SW1(config)# interface fa0/3
SW1(config-if)# shutdown
SW1(config-if)# no shutdown
```

> A manual `shutdown` / `no shutdown` cycle is required — `err-disabled` does
> not clear automatically and a simple `no shutdown` alone is not sufficient if
> the interface was never administratively shut in the first place.

---

## Verification

```
SW1# show interfaces fa0/3 status
```

```
Port      Name              Status       Vlan       Duplex  Speed Type
Fa0/3                       connected    10         auto    auto  10/100BaseTX
```

Port returns to `connected` status and the originally connected PC regains
network access normally.

---

## Impact if Left Unresolved

- The connected end device has no network access until the port is manually
  recovered — BPDU Guard does not self-clear
- If the root cause (unauthorized switch) is not identified and removed before
  recovery, the port will immediately re-trigger and disable again
- Without monitoring or alerting in place, an err-disabled port can go unnoticed
  for an extended period, especially on ports not actively monitored by NOC tools

---

## Root Cause Category

`Security Control Functioning As Designed — Unauthorized Device Connection`

---

## Lessons Learned

- `err-disabled` is always the result of a protective mechanism, never a normal
  link failure — `show interfaces status` should be the very first command run
  when a port shows unexpected "down" behaviour
- BPDU Guard working correctly looks identical to a "problem" from the end
  user's perspective — distinguishing a security control doing its job from an
  actual fault is a key triage skill
- Recovery always requires removing the root cause first — cycling the port
  without addressing why a BPDU arrived in the first place only delays the
  same shutdown from happening again
- `shutdown` then `no shutdown` is the standard manual recovery method for any
  err-disabled port, regardless of which specific feature triggered it
- This is exactly why PortFast should only ever be applied to ports that are
  genuinely connected to a single end device — never to uplinks or ports with
  uncertain downstream equipment
