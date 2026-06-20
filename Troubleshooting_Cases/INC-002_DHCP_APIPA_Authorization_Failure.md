# INC-002 — Client Receiving APIPA Address (DHCP Unreachable)

| Field | Detail |
|---|---|
| **Severity** | P2 — Client has no network connectivity |
| **System Affected** | DHCP Server (WS2K19-DC01) and domain-joined client |
| **Reported By** | Self-identified during Lab 04 — DHCP Configuration |
| **Status** | ✅ Resolved |
| **Environment** | VirtualBox, Windows Server 2019, domain mylab.local |

---

## Summary

A client machine configured for DHCP received a `169.254.x.x` Automatic Private IP
Addressing (APIPA) address instead of an address from the configured DHCP scope.
Root cause was the DHCP server not being authorized in Active Directory — in an
AD environment, an unauthorized DHCP server is deliberately blocked from leasing
addresses as a security control against rogue DHCP servers.

---

## Symptom

```cmd
C:\>ipconfig /all

Ethernet adapter Ethernet0:
   IPv4 Address. . . . . . . . . . . : 169.254.23.108
   Subnet Mask . . . . . . . . . . . : 255.255.0.0
   Default Gateway . . . . . . . . . :
```

No default gateway, no DNS server, subnet mask is the APIPA default `/16` —
client cannot reach anything outside its local link, including the Domain
Controller.

---

## Diagnosis

**Step 1 — Confirm this is APIPA, not a manual misconfiguration**

`169.254.x.x` is the reserved Microsoft APIPA range. Windows assigns this
automatically when DHCP is enabled but no DHCP server responds within the
timeout window. This immediately ruled out a client-side static IP error and
pointed to a DHCP service problem.

**Step 2 — Check DHCP server status**

```powershell
Get-Service DHCPServer
```

```
Status   Name         DisplayName
------   ----         -----------
Running  DHCPServer   DHCP Server
```

Service was running — so the problem was not the service itself.

**Step 3 — Check scope status**

```powershell
Get-DhcpServerv4Scope
```

```
ScopeId       Name            State
-------       ----            -----
10.10.11.0    Corporate-LAN   Active
```

Scope existed and was active.

**Step 4 — Check authorization status**

```powershell
Get-DhcpServerInDC
```

Returned an empty result — **the DHCP server was not listed as authorized in
Active Directory**, even though the service was running and the scope was
correctly configured.

---

## Root Cause

In an Active Directory domain, a DHCP server must be explicitly authorized in
AD before it is permitted to respond to client DHCPDISCOVER broadcasts — even
if the service is running and a valid scope exists. This is a deliberate
Microsoft security mechanism to prevent rogue or accidental DHCP servers from
handing out incorrect addresses on a domain network. The authorization step
during role setup had not been completed.

---

## Fix

```
Server Manager → Notifications → Complete DHCP configuration
→ Use the following user's credentials (Domain Admin account)
→ Commit
```

Or via PowerShell:
```powershell
Add-DhcpServerInDC -DnsName "WS2K19-DC01.mylab.local" -IPAddress 10.10.11.119
```

---

## Verification

```powershell
Get-DhcpServerInDC
```

```
DnsName                      IPAddress
-------                      ---------
WS2K19-DC01.mylab.local      10.10.11.119
```

Client-side, forced a fresh lease request:

```cmd
C:\>ipconfig /release
C:\>ipconfig /renew
C:\>ipconfig /all

IPv4 Address. . . . . . . . . . . : 10.10.11.55
Subnet Mask . . . . . . . . . . . : 255.255.255.0
Default Gateway . . . . . . . . . : 10.10.11.1
DHCP Server . . . . . . . . . . . : 10.10.11.119
```

Client now holds a correctly leased address from the configured scope.

---

## Impact if Left Unresolved

- Client has zero network connectivity beyond its local link — cannot reach the
  DC, cannot resolve DNS, cannot authenticate to the domain
- If multiple clients are affected, this presents as a sitewide "network down"
  incident even though the physical network and switches are fully functional
- Easily misdiagnosed as a cabling or switch issue if APIPA isn't recognised
  immediately, wasting troubleshooting time on the wrong layer

---

## Root Cause Category

`Service Misconfiguration — Missing Authorization Step`

---

## Lessons Learned

- A `169.254.x.x` address is diagnostic gold — it immediately narrows the
  problem to "client cannot reach a DHCP server," not a routing or cabling fault
- `Get-Service` showing "Running" is not sufficient proof that DHCP is actually
  functional in an AD environment — authorization must be checked separately
- `ipconfig /release` then `/renew` is the fastest way to force a client to
  re-attempt DHCP for testing, rather than waiting for natural lease expiry
- Always verify DHCP authorization as a standard post-install step — it is easy
  to complete the scope configuration and forget this separate requirement
