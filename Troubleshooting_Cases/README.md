# Troubleshooting Cases

Structured troubleshooting scenarios from real lab work at Vatanix Technologies. Each case follows a consistent methodology using OSI layer-by-layer analysis.

---

## Methodology

```
1. Symptom         — What was reported or observed
2. Initial Checks  — First steps: ping, ipconfig, show commands
3. Layer Analysis  — OSI layer-by-layer diagnosis
                     Physical → Data Link → Network → Transport → Application
4. Root Cause      — What actually caused the issue
5. Fix Applied     — Exact steps taken to resolve
6. Verification    — Proof it is working after the fix
7. Lessons Learned — What to remember for next time
```

---

## Case 01 — Host Unreachable After Connecting Ethernet Cable

**Environment:** HPE ProLiant DL360 Gen9 — ESXi 8.0 setup

**Symptom:**
After connecting the server's Ethernet cable and attempting to access the ESXi Host Client via browser at `https://10.10.11.14`, the host was completely unreachable. Ping also showed no response.

**Initial Checks:**
```
ping 10.10.11.14        → Request timed out
ping 10.10.11.1         → Request timed out
Browser: https://10.10.11.14  → Site cannot be reached
```

**Layer Analysis:**

| Layer | Check | Finding |
|---|---|---|
| Physical (L1) | Cable plugged in? | Yes — cable connected |
| Physical (L1) | Link LED on port? | No link light on the port used |
| Physical (L1) | Correct port? | ❌ Cable was in iLO port, not standard NIC |
| Network (L3) | IP reachable? | No — physically disconnected from data network |

**Root Cause:**
The Ethernet cable was accidentally plugged into the **iLO (Integrated Lights-Out) management port** instead of the standard network NIC port. Both ports sit side by side on the rear panel and look nearly identical. The iLO port operates on a separate management network (`10.10.11.13`) — it does not carry ESXi data traffic. The ESXi management interface on `10.10.11.14` was therefore physically disconnected.

**Fix Applied:**
1. Physically inspected the rear panel of the server
2. Identified the iLO port label vs standard NIC ports
3. Moved the Ethernet cable from iLO port to the correct NIC port
4. Link LED immediately lit up on the correct port

**Verification:**
```
ping 10.10.11.14        → Reply from 10.10.11.14 — OK
Browser: https://10.10.11.14  → ESXi Host Client loaded successfully
```

**Lessons Learned:**
- Always check Layer 1 first — software cannot fix a wrong cable
- iLO and standard NIC ports are physically adjacent and look the same — read the port labels
- No link LED = physical layer problem — check the cable and port before any IP troubleshooting
- This is a common real-world mistake in datacentre environments — even experienced engineers make it

---

## Case 02 — nslookup Showing "Unknown" After DC Promotion

**Environment:** Windows Server 2019 Domain Controller — georgi.local

**Symptom:**
After promoting Windows Server 2019 to Domain Controller, `nslookup` in PowerShell showed:
```
Server: Unknown
Address: 10.10.11.x
```

**Initial Checks:**
```powershell
nslookup georgi.local     # Resolved correctly — forward lookup OK
nslookup 10.10.11.x       # Returned "Unknown" — reverse lookup failing
Get-DnsServerZone         # Only forward zone present — no reverse zone
```

**Layer Analysis:**

| Layer | Check | Finding |
|---|---|---|
| Application | nslookup output | Forward works, reverse fails |
| Network | DNS zone config | Reverse lookup zone missing |
| Configuration | PTR record | No PTR record existed for DC IP |

**Root Cause:**
Reverse lookup zone for the `10.10.11.0/24` subnet was never created. Without it, DNS cannot resolve an IP address back to a hostname — causing nslookup to display "Unknown."

**Fix Applied:**
```powershell
# Create reverse lookup zone
Add-DnsServerPrimaryZone -NetworkID "10.10.11.0/24" -ReplicationScope "Forest"

# Add PTR record for Domain Controller
Add-DnsServerResourceRecordPtr `
    -ZoneName "11.10.10.in-addr.arpa" `
    -Name "x" `
    -PtrDomainName "winserver2019.georgi.local"
```

**Verification:**
```powershell
nslookup 10.10.11.x
# Server: winserver2019.georgi.local — resolved correctly
```

**Lessons Learned:**
- Always create both forward AND reverse lookup zones during DNS setup
- PTR records must be added manually if not auto-created
- Many Windows services depend on reverse DNS — never skip this step

---

## Case 03 — GPO Not Applying on Domain-Joined Client

**Environment:** Windows Server 2019 DC + Windows client VM — georgi.local

**Symptom:**
Group Policy (forced wallpaper + logon message) linked to IT OU on DC. After joining client to domain, policies were not visible on the client.

**Initial Checks:**
```powershell
gpresult /r          # GPO listed but not applied
echo %logonserver%   # Confirmed correct DC
ping georgi.local    # DNS resolving correctly
```

**Root Cause:**
Group Policy applies at login and at 90-minute intervals. The policy was linked after the client already logged in — no refresh had occurred yet.

**Fix Applied:**
```powershell
gpupdate /force      # Force immediate refresh
shutdown /r /t 0     # Restart to apply computer-level policies
```

**Verification:**
After restart — wallpaper applied, logon message displayed, right-click disabled.

**Lessons Learned:**
- Always run `gpupdate /force` after linking a new GPO — never wait for auto-refresh
- Computer Configuration policies require a full restart to apply
- Use `gpresult /r` to confirm which GPOs are applied and from which DC

---

## Case 04 — VM Network Speed Showing 100 Mbps

**Environment:** Windows Server 2019 VM on ESXi 8.0

**Symptom:**
After OS install, Device Manager showed "Intel PRO/1000 MT" at 100 Mbps. Physical host has 10 GbE NICs.

**Root Cause:**
VM was created with E1000 NIC (emulated Intel adapter). VMware Tools not installed — VMXNET3 driver unavailable.

**Fix Applied:**
1. Shut down VM
2. vSphere: Edit Settings → Remove E1000 NIC → Add VMXNET3 NIC
3. Power on → Install VMware Tools → Restart

**Verification:**
Device Manager showed "VMware VMXNET3 Ethernet Adapter" — full speed available.

**Lessons Learned:**
- Always select VMXNET3 when creating VMs — never use the default E1000
- VMware Tools must be installed for VMXNET3 to activate
- Physical host NIC speed does not automatically pass to VM — NIC type determines VM speed
