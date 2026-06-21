# Lab 04 — DHCP Server Configuration

**Environment:** VirtualBox (separate from the physical HPE server used in Lab 01)
**Topics:** DHCP · IPv4 Scope · Scope Options · Server Authorization · Lease Management

---

## Objective

Install and configure the DHCP Server role on Windows Server 2019, create an IPv4
scope for automatic client IP assignment, and verify that domain-joined clients
receive addresses correctly.

---

## Environment

| Component | Detail |
|-----------|--------|
| Domain | mylab.local |
| DC Hostname | WS2K19-DC01 |
| DHCP Scope Range | 10.10.11.50 – 10.10.11.100 |
| Default Gateway | 10.10.11.1 |
| Lease Duration | 8 days |

---

## Key Concepts

**DHCP (Dynamic Host Configuration Protocol)** automatically assigns IP addresses,
subnet masks, default gateways, and DNS servers to clients — eliminating manual
IP configuration on every machine.

**Scope** defines the range of IP addresses the DHCP server can lease out, along
with associated options like gateway and DNS server.

**Authorization** — in an AD environment, a DHCP server must be authorized in
Active Directory before it will respond to client requests. This prevents rogue
DHCP servers from handing out incorrect addresses on the network.

**Lease Duration** controls how long a client can use an assigned IP before it
must renew. Shorter leases suit dynamic environments (guest networks); longer
leases suit stable corporate networks.

---

## Configuration Steps

---

### STEP 1 — Install the DHCP Server Role

```
Server Manager → Add Roles and Features → DHCP Server → Install
```

> After installation, a post-deployment notification appears in Server Manager
> requiring completion of DHCP configuration — this step authorizes the server.

---

### STEP 2 — Complete DHCP Post-Deployment Configuration

```
Server Manager → Notifications → Complete DHCP configuration
→ Use the following user's credentials (domain admin)
→ Commit
```

> This step authorizes the DHCP server in Active Directory. An unauthorized
> DHCP server installed on a domain will not lease addresses to domain clients —
> AD-integrated DHCP servers must be explicitly authorized as a security measure.

---

### STEP 3 — Create a New IPv4 Scope

```
DHCP Console → IPv4 → Right-click → New Scope
→ Scope Name        : Corporate-LAN
→ Start IP Address   : 10.10.11.50
→ End IP Address     : 10.10.11.100
→ Subnet Mask        : 255.255.255.0
→ Exclusions         : (none, or reserve static IPs as needed)
→ Lease Duration     : 8 days
```

> **Why exclude a range?** Static devices like the DC, printers, or servers should
> never receive a DHCP-assigned address. Excluding their IPs from the scope
> prevents conflicts.

---

### STEP 4 — Configure Scope Options

```
DHCP Console → Scope → Scope Options → Configure
→ 003 Router (Default Gateway)  : 10.10.11.1
→ 006 DNS Servers               : 10.10.11.119 (DC IP)
→ 015 DNS Domain Name           : mylab.local
```

> **Why these three options matter most:** Without 003, clients have no route
> off their local subnet. Without 006, clients cannot resolve any hostname,
> including the domain itself. Without 015, clients may not properly register
> with the correct DNS suffix.

---

### STEP 5 — Activate the Scope

```
DHCP Console → Scope → Right-click → Activate
```

> A newly created scope is inactive by default and will not lease addresses
> until activated.

---

### STEP 6 — Verify DHCP Service Status

```powershell
Get-Service DHCPServer
Get-DhcpServerv4Scope
Get-DhcpServerv4ScopeStatistics
```

Expected:
```
Status   : Active
Free %   : (depends on number of leased addresses)
```

---

### STEP 7 — Verify Client Receives an IP

On the client VM:

```cmd
ipconfig /release
ipconfig /renew
ipconfig /all
```

Expected output confirms:
```
IPv4 Address. . . . . . . . . . . : 10.10.11.5x
Subnet Mask . . . . . . . . . . . : 255.255.255.0
Default Gateway . . . . . . . . . : 10.10.11.1
DHCP Server . . . . . . . . . . . : 10.10.11.119
```

---

### STEP 8 — View Active Leases

```powershell
Get-DhcpServerv4Lease -ScopeId 10.10.11.0
```

Or via GUI:
```
DHCP Console → IPv4 → Scope → Address Leases
```

This confirms which clients currently hold a leased IP, their MAC address, and
lease expiration time.

---

## Verification Summary

| Check | Command / Location | Expected Result |
|-------|---------------------|------------------|
| DHCP service running | `Get-Service DHCPServer` | Status: Running |
| Scope created and active | DHCP Console → IPv4 | Status: Active |
| Scope options set | Scope Options node | 003, 006, 015 all configured |
| Client receives IP | `ipconfig /all` on client | IP in 10.10.11.50–100 range |
| Lease visible on server | `Get-DhcpServerv4Lease` | Client MAC and IP listed |

---

## Common Issues and Fixes

| Problem | Cause | Fix |
|---------|-------|-----|
| Client gets APIPA (169.254.x.x) | DHCP server not authorized, or scope inactive | Authorize server in AD; activate scope |
| Client gets IP but no internet/DNS | Scope option 006 (DNS) missing or wrong | Set 006 to the DC's IP address |
| Two DHCP servers conflict | Rogue or duplicate DHCP server on network | Identify and disable the unauthorized server |
| Lease not renewing | Client cached old lease | `ipconfig /release` then `ipconfig /renew` |

---

## Lessons Learned

- An AD-integrated DHCP server must be authorized before it leases any addresses — this is a deliberate security control against rogue DHCP servers
- Scope options 003 (gateway) and 006 (DNS) are the two most critical settings — missing either breaks client connectivity even with a valid IP
- Static infrastructure devices (DC, printers) should be excluded from the DHCP range or given reservations, never left to dynamic assignment
- `ipconfig /release` followed by `/renew` is the fastest way to force a client to re-request an IP for testing
- DHCP and DNS work together — a client with a DHCP-assigned IP still needs the correct DNS server option to resolve the domain
