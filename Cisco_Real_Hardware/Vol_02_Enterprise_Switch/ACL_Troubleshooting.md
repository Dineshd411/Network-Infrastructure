# ACL Troubleshooting — The Switch-Sourced Ping Problem

This is a standalone write-up of the third issue encountered during Vol 02, separated
from the main README because it's more detailed than a simple bug-and-fix. It documents
a scenario where the troubleshooting methodology itself was wrong, and the ACL appeared
to be failing when it was actually working correctly the entire time. It's worth
understanding properly because it's a non-obvious trap that costs real time.

---

## What the ACL Was Supposed to Do

The `VLAN_SECURITY` extended ACL was applied inbound on VLAN 10, VLAN 20, and VLAN 40
SVIs. Among other rules, it contained this line:

```
deny ip 192.168.40.0 0.0.0.255 192.168.30.0 0.0.0.255
```

GUEST (VLAN 40) should not be able to reach IT (VLAN 30). That's the policy.

---

## What Actually Happened During Testing

Every other deny line in the ACL was incrementing match counters in `show access-lists`
as expected. The GUEST→IT line showed zero matches — even after pinging 192.168.30.1
multiple times from the switch CLI:

```
vtnx_SW1# ping 192.168.30.1 source vlan40
Sending 5, 100-byte ICMP Echos to 192.168.30.1, timeout is 2 seconds:
Packet sent with a source address of 192.168.40.1
!!!!!
Success rate is 100 percent (5/5)
```

100% success. GUEST reaching IT. ACL apparently doing nothing.

The immediate assumption was that something was wrong with the ACL — wrong line order,
wrong wildcard mask, applied to the wrong interface. All of those were checked:

- `show running-config | section ip access-list extended VLAN_SECURITY` confirmed the
  deny line was present, in the correct position, before `permit ip any any`
- `show ip interface vlan40` confirmed `Inbound access list is VLAN_SECURITY` — it was
  bound to the right interface
- The wildcard mask `0.0.0.255` was correct for a /24 network

Configuration was right. Application was right. And yet the ping was succeeding and
the counter was stuck at zero.

---

## The Actual Problem

The ping was run from the switch itself, using `source vlan40`. This generates traffic
**from the switch's own control plane** — not from a real device arriving as inbound
traffic on the VLAN 40 SVI.

`ip access-group VLAN_SECURITY in` evaluates packets entering the interface from the
outside. Traffic that the switch itself generates internally doesn't necessarily travel
the same path through the data plane as host traffic arriving from a connected device.
Depending on the IOS version and platform, locally-originated pings can bypass inbound
interface ACL checks entirely.

This is why the counter never incremented — the switch's own ping wasn't being evaluated
against the ACL at all. It was travelling a different path internally and reaching its
destination without ever being checked.

---

## Why It Looked Like It Worked for Other VLANs

The deny lines for SALES→HR and other pairs had already accumulated match counts from
earlier in the lab, when real PC-to-PC traffic was being tested. So when those lines
were checked later, they appeared to "work" — but the match counts were from the
earlier legitimate host traffic, not from the switch-sourced pings that were being
run at verification time. The switch-sourced pings were never hitting the ACL for any
line, but since most lines already had counts from earlier, only the GUEST→IT line
(which hadn't been tested with real PC traffic yet) showed the problem clearly.

---

## The Correct Test

A real end-host PC plugged into a GUEST VLAN port. From that PC:

```
C:\> ping 192.168.30.1
Pinging 192.168.30.1 with 32 bytes of data:
Request timed out.
Request timed out.
Request timed out.
Request timed out.

Ping statistics for 192.168.30.1:
    Packets: Sent = 4, Received = 0, Lost = 4 (100% loss)
```

And immediately after, back on the switch:

```
vtnx_SW1# show access-lists VLAN_SECURITY
Extended IP access list VLAN_SECURITY
    10 deny ip 192.168.10.0 0.0.0.255 192.168.20.0 0.0.0.255 (45 matches)
    20 deny ip 192.168.10.0 0.0.0.255 192.168.40.0 0.0.0.255 (15 matches)
    30 deny ip 192.168.20.0 0.0.0.255 192.168.10.0 0.0.0.255 (45 matches)
    40 deny ip 192.168.40.0 0.0.0.255 192.168.10.0 0.0.0.255 (15 matches)
    50 deny ip 192.168.40.0 0.0.0.255 192.168.20.0 0.0.0.255 (5 matches)
    60 deny ip 192.168.40.0 0.0.0.255 192.168.30.0 0.0.0.255 (4 matches)
    70 permit ip any any (11638 matches)
```

Line 60 incremented for the first time. The ACL had been working correctly the whole
time. The test method was wrong.

---

## What This Means Practically

`ping <destination> source <vlanX>` from a switch CLI is a valid and useful command
for exactly one thing: confirming that inter-VLAN routing is functioning before any
ACL is applied. If the switch can reach a destination SVI from a given VLAN source,
routing is working.

It is not a valid test for ACL enforcement once a policy is in place. The traffic path
for locally-originated switch pings is different from inbound host traffic, and inbound
ACLs may not evaluate it the same way.

The only valid way to test whether an inbound SVI ACL is blocking real host traffic
is to generate real host traffic from an actual end device physically connected to
that VLAN — then cross-check the result with `show access-lists` match counters.
The counters are the ground truth. If they don't increment, the ACL never saw the
traffic, regardless of what the ping output shows on either end.

---

## Quick Reference — How to Verify an ACL Is Actually Working

```
! Step 1 — Confirm the ACL exists and has the right rules
show running-config | section ip access-list extended VLAN_SECURITY

! Step 2 — Confirm the ACL is actually bound to the right interface
show ip interface vlan10
! Look for: "Inbound access list is VLAN_SECURITY"

! Step 3 — Generate traffic from a REAL end-host PC, not from the switch
! (plug a laptop into a VLAN 10 access port, ping a VLAN 20 host from it)

! Step 4 — Check the counters immediately after
show access-lists VLAN_SECURITY
! The relevant deny line must have incremented
! If it hasn't, the traffic either didn't reach the switch, or isn't matching this ACL
```

The counters reset when the switch reloads or when you run `clear ip access-list
counters`. If you're running multiple tests and the counts get confusing, clear them
before each test series:

```
clear ip access-list counters VLAN_SECURITY
```

Then re-test and check again. Fresh counters make it unambiguous which traffic is
hitting which line.
