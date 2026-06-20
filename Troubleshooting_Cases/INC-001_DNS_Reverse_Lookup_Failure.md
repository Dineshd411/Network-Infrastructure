# INC-001 — DNS Reverse Lookup Failure (Missing PTR Record)

| Field | Detail |
|---|---|
| **Severity** | P3 — Minor, no service outage, affects diagnostics and logging accuracy |
| **System Affected** | DNS Server (WS2K19-DC01, mylab.local) |
| **Reported By** | Self-identified during Lab 03 — DNS Configuration |
| **Status** | ✅ Resolved |
| **Environment** | VirtualBox, Windows Server 2019, domain mylab.local |

---

## Summary

`nslookup` returned `Unknown` instead of resolving the Domain Controller's hostname
when performing a reverse lookup (IP → hostname). Forward lookups (hostname → IP)
worked correctly. Root cause was a missing Reverse Lookup Zone — Windows Server does
not create this automatically during DNS role installation or DC promotion.

---

## Symptom

```
PS C:\Users\Administrator> nslookup 10.10.11.119
Server:  UnKnown
Address:  10.10.11.119

*** UnKnown can't find 10.10.11.119: Non-existent domain
```

Forward lookup worked fine in the same session:
```
PS C:\Users\Administrator> nslookup WS2K19-DC01.mylab.local
Server:  WS2K19-DC01.mylab.local
Address:  10.10.11.119

Name:    WS2K19-DC01.mylab.local
Address: 10.10.11.119
```

---

## Diagnosis

Opened DNS Manager on the DC:

```
Server Manager → Tools → DNS
```

Checked both zone categories:

| Zone Type | Status |
|---|---|
| Forward Lookup Zones | `mylab.local` present, A record for DC present |
| Reverse Lookup Zones | **Empty — no zone existed** |

This confirmed the forward path was fully functional (hostname resolution worked
for AD, GPO, and client traffic), but nothing in the environment could resolve an
IP address back to a hostname.

---

## Root Cause

Windows Server's DNS role does not automatically create a Reverse Lookup Zone when
the role is installed or when a server is promoted to Domain Controller. Only the
Forward Lookup Zone is generated automatically (since AD depends on it for SRV
record registration). Reverse zones must be created manually.

---

## Fix

Created the Reverse Lookup Zone matching the DC's subnet:

```
DNS Manager → Right-click Reverse Lookup Zones → New Zone
→ Zone Type     : Primary Zone
→ Network ID    : 10.10.11
  (auto-generates zone name: 11.10.10.in-addr.arpa)
→ Dynamic Updates : Allow only secure dynamic updates
→ Finish
```

Added PTR records for the DC and the domain-joined client:

| IP | PTR Record |
|---|---|
| 10.10.11.119 | WS2K19-DC01.mylab.local |
| 10.10.11.121 | Oprekin-PC.mylab.local |

---

## Verification

```
PS C:\Users\Administrator> nslookup 10.10.11.119
Server:  WS2K19-DC01.mylab.local
Address:  10.10.11.119

Name:    WS2K19-DC01.mylab.local
Address: 10.10.11.119
```

Reverse lookup now resolves correctly for both the DC and the client.

---

## Impact if Left Unresolved

- Security and audit logs that rely on reverse DNS show raw IPs instead of
  hostnames, making incident investigation slower
- Some applications and services (mail servers, certain VPN/RADIUS configs)
  reject connections or log warnings when reverse DNS fails
- Network monitoring tools that resolve IPs to hostnames for dashboards display
  incomplete data

---

## Root Cause Category

`Configuration Gap — Default Behaviour Not Matching Environment Needs`

---

## Lessons Learned

- Reverse Lookup Zones are never automatic in Windows Server — this must be a
  standard step in every DNS deployment checklist, not an afterthought
- Always test both forward AND reverse lookup after deploying DNS — testing
  only one direction gives a false sense of completeness
- PTR records do not appear automatically even after creating the reverse zone —
  each one must be added manually unless "Create associated PTR record" was
  checked when the original A record was created
