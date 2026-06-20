# Common Troubleshooting Scenarios — Quick Reference

A consolidated reference of common faults, symptoms, and fixes encountered across
the full training journey — from hardware fundamentals through networking,
Windows Server, and Cisco labs. Unlike the detailed [Case Studies](README.md)
in this folder, this is a fast-lookup table format for quick recall and
interview preparation.

---

## How to Use This Document

Each table follows the same structure: **Symptom → Likely Cause → Fix → Command/Check**.
Organized by topic area in the same order covered during training (Days 1–40+).

---

## 1. Hardware & BIOS/UEFI

| Symptom | Likely Cause | Fix | Verify With |
|---|---|---|---|
| PC won't POST, no display | RAM not seated, loose power cable | Reseat RAM, check 24-pin + CPU power | Listen for POST beep codes |
| "No bootable device" | Boot order wrong, drive not detected | Check boot order in BIOS, verify drive cable | BIOS storage detection screen |
| System boots to BIOS every time | CMOS battery dead, boot order not saved | Replace CMOS battery (CR2032) | Check system clock resets to default |
| Overheating shutdown | Dust buildup, thermal paste dried out, fan failure | Clean fans/heatsinks, repaste CPU | Monitor temps in BIOS or HWMonitor |
| DIMM memory error at POST | Faulty or improperly seated RAM module | Reseat, test in different slot, replace if uncorrectable | POST error code (e.g., `295-DIMM Failure`) |
| USB boot drive not recognized | Wrong partition scheme (MBR vs GPT) for UEFI mode | Recreate boot USB with Rufus using GPT for UEFI | Boot Menu (F11/F12) shows the USB device |

---

## 2. Operating System & Boot Issues

| Symptom | Likely Cause | Fix | Verify With |
|---|---|---|---|
| BSOD on startup | Driver conflict, corrupted system file, failing disk | Boot to Safe Mode, run `sfc /scannow`, check Event Viewer | `Get-WinEvent` or Event Viewer System log |
| "Operating System Not Found" | MBR/GPT corruption, wrong boot mode (Legacy vs UEFI) | Boot repair via installation media, `bootrec /fixmbr` | Check disk partition style in Disk Management |
| Windows stuck on "Preparing devices" | Failed update, corrupted driver | Boot into Safe Mode, roll back recent update | `sfc /scannow`, `DISM /Online /Cleanup-Image /RestoreHealth` |
| Service fails to start | Dependency service not running, corrupted service registry entry | Check service dependencies in Services console | `Get-Service`, `sc qc [servicename]` |
| Virus/malware suspected slowdown | Malicious process running, startup bloat | Boot to Safe Mode with Networking, run full AV scan | Task Manager → Startup tab, `msconfig` |
| Disk shows as RAW or unformatted | File system corruption, improper shutdown | Run `chkdsk /f`, attempt data recovery before reformatting | `chkdsk` output, Disk Management |

---

## 3. Networking Fundamentals (IP/DNS/DHCP/Binary)

| Symptom | Likely Cause | Fix | Verify With |
|---|---|---|---|
| "Limited connectivity" / no internet | DHCP failure, APIPA address assigned | Check DHCP service/scope, `ipconfig /release` then `/renew` | `ipconfig /all` — look for 169.254.x.x |
| Can ping IP but not hostname | DNS not resolving | Check DNS server setting, test with `nslookup` | `nslookup [hostname]` |
| Can resolve hostname but ping fails | Firewall blocking ICMP, host actually down | Check firewall rules, confirm target host is up | `ping`, `Test-NetConnection -Port [port]` |
| Wrong subnet calculated | Subnetting/binary math error | Recalculate using binary — convert mask to binary, AND with IP | Subnet calculator, manual binary verification |
| Two devices with same IP (conflict) | Static IP misconfigured, DHCP scope overlap | Reassign static IP outside DHCP range, or fix DHCP scope | `arp -a`, Windows IP conflict popup |
| Reverse DNS lookup fails | No PTR record / reverse lookup zone | Create reverse lookup zone, add PTR record | `nslookup [IP-address]` |

---

## 4. Email / Outlook / Authentication

| Symptom | Likely Cause | Fix | Verify With |
|---|---|---|---|
| Outlook won't connect to server | Incorrect server settings, port blocked | Verify IMAP/SMTP/POP settings and ports | Test connectivity with `Test-NetConnection -Port 587/993` |
| 2FA codes not arriving | SMS/app sync issue, time drift on device | Check device time sync, use backup codes, resync authenticator | Authenticator app time sync setting |
| "Account locked out" | Too many failed login attempts, policy lockout threshold reached | Check AD account lockout policy, unlock via ADUC | `Get-ADUser -Identity [user] -Properties LockedOut` |

---

## 5. Printers / Ping / Firewall

| Symptom | Likely Cause | Fix | Verify With |
|---|---|---|---|
| Printer offline / not responding | Printer powered off, wrong IP, driver issue | Verify printer IP, ping printer, reinstall driver | `ping [printer-IP]`, printer status page |
| Print jobs stuck in queue | Print spooler service hung | Restart Print Spooler service, clear queue | `Restart-Service Spooler`, check spooler folder |
| Ping works locally but not to remote network | Firewall blocking ICMP, routing issue | Check firewall ICMP rules, verify default gateway | `tracert [destination]` to find where it stops |
| Application blocked by firewall | Inbound/outbound rule missing | Add firewall rule for the application/port | `Get-NetFirewallRule`, Windows Defender Firewall console |

---

## 6. Virtualization / Hypervisor (ESXi)

| Symptom | Likely Cause | Fix | Verify With |
|---|---|---|---|
| VM network shows slow speed (100 Mbps) | Using emulated E1000 NIC instead of VMXNET3 | Change NIC type to VMXNET3, install VMware Tools | VM network adapter settings, link speed display |
| VM won't power on | Insufficient host resources, datastore full | Check host CPU/RAM availability, free up datastore space | ESXi Host Client → Monitor → Resources |
| Can't access ESXi Host Client | Wrong IP, management network down, service stopped | Verify management IP at console, check physical NIC connection | DCUI (Direct Console User Interface) at server console |
| VM clock drift | VMware Tools not installed or not syncing | Install/reinstall VMware Tools, enable time sync | VM Settings → Options → VMware Tools |
| Host unreachable after cabling | Cable plugged into iLO port instead of standard NIC | Identify correct NIC port using POST screen reference | POST screen shows iLO IP vs management NIC IP separately |

---

## 7. Server Hardware (HPE DL360 Gen9 / iLO)

| Symptom | Likely Cause | Fix | Verify With |
|---|---|---|---|
| Can't access iLO web interface | Wrong iLO IP, cable in wrong port, iLO not configured | Confirm iLO IP from POST screen, check correct iLO NIC port | POST screen displays iLO IPv4/IPv6 directly |
| Server reports DIMM failure | Faulty memory module on specific processor/slot | Note exact processor/DIMM number, reseat or replace | POST diagnostic message (e.g., `Processor 2, DIMM 12`) |
| Redundant PSU alarm | One power supply failed or unplugged | Check both PSU LEDs, verify power cable connections | Front panel PSU status LEDs |
| Server won't boot past POST | Failed POST self-test, hardware fault | Read full POST output for specific error code | POST screen detailed error text |

---

## 8. RAID

| Symptom | Likely Cause | Fix | Verify With |
|---|---|---|---|
| Array shows degraded | One disk failed or dropped from array | Identify failed disk, replace and allow rebuild | RAID controller utility (e.g., HPE Smart Storage) |
| Data loss after disk failure | RAID 0 used (no redundancy) instead of RAID 1/5/10 | Restore from backup; for future, use redundant RAID level | RAID level documentation, controller config |
| Rebuild taking very long / degraded performance | Large disk size, array under load during rebuild | Allow rebuild to complete, avoid heavy I/O during rebuild | RAID controller rebuild progress indicator |

---

## 9. Active Directory / GPO / Registry

| Symptom | Likely Cause | Fix | Verify With |
|---|---|---|---|
| GPO not applying to client | gpupdate not run, GPO linked to wrong OU, client not in scope | Run `gpupdate /force`, verify OU link and security filtering | `gpresult /r`, `gpresult /h report.html` |
| Can't promote server to DC | DNS not configured correctly, insufficient permissions | Verify DNS points to itself or valid DNS server first | Check `ipconfig /all` for DNS server entry before promotion |
| User can't log into domain | Account locked, expired password, wrong OU/group policy restricting logon | Check account status in ADUC, verify logon hours/workstation restrictions | `Get-ADUser -Identity [user] -Properties *` |
| Registry change not taking effect | Need restart/logoff, wrong registry hive edited, GPO overriding | Restart or `gpupdate /force`, verify correct HKLM vs HKCU path | `regedit`, compare against GPO-defined value |
| DSRM password forgotten | Not documented during DC promotion | Reset DSRM password via `ntdsutil` (boot to DSRM mode required) | `ntdsutil` "set dsrm password" |

---

## 10. Cisco Switching — VLANs, Trunks, SSH

| Symptom | Likely Cause | Fix | Verify With |
|---|---|---|---|
| Devices in same VLAN can't communicate | Port not in correct VLAN, port in wrong mode | Verify `switchport access vlan`, confirm `switchport mode access` | `show vlan brief` |
| Cross-VLAN traffic fails (expected) | No Layer 3 device — VLANs are isolated by design | This is expected without SVI or router — add inter-VLAN routing | `show ip route` confirms no path exists |
| One VLAN unreachable across switches | VLAN missing from local VLAN database on one switch | Add the missing VLAN to that switch's database | `show vlan brief` + `show interfaces trunk` on each switch |
| Trunk not passing expected VLANs | VLAN not in trunk's allowed list, encapsulation mismatch | Verify `switchport trunk allowed vlan`, match encapsulation type | `show interfaces trunk` |
| SSH connection refused | RSA key not generated, `transport input` not set to ssh | Generate RSA key with domain name set, verify `transport input ssh` on VTY lines | `show ip ssh`, `show crypto key mypubkey rsa` |
| Telnet works but SSH doesn't | Missing domain name or local user account | Set `ip domain-name`, create local user, regenerate RSA keys | `show running-config` for domain-name and username entries |

---

## 11. Spanning Tree Protocol

| Symptom | Likely Cause | Fix | Verify With |
|---|---|---|---|
| Network-wide broadcast storm | STP disabled or misconfigured, physical loop present | Re-enable STP, verify topology has no unintended redundant links without STP | `show spanning-tree`, check for excessive broadcast traffic |
| Wrong switch elected as Root Bridge | Default priority used, lowest MAC won unintentionally | Manually set priority with `spanning-tree vlan [id] root primary` | `show spanning-tree` — check "This bridge is the root" |
| Port stuck in blocking unexpectedly | Redundant path exists, STP correctly preventing loop | This may be correct behaviour — verify with topology, not necessarily a fault | `show spanning-tree` — check port role (Altn/Root/Desg) |
| Port shows err-disabled | BPDU Guard, port security, or storm control violation triggered | Identify root cause (e.g., unauthorized switch connected), remove cause, cycle port | `show interfaces status`, `show logging` |
| Failover takes ~30+ seconds | Classic 802.1D STP convergence time (default, no fast features) | Expected behaviour for legacy STP; consider Rapid PVST+ for faster convergence | Time the failover, check `spanning-tree mode` |

---

## 12. Static & Inter-VLAN Routing

| Symptom | Likely Cause | Fix | Verify With |
|---|---|---|---|
| Static route configured but traffic still fails | Wrong subnet mask or wrong next-hop IP on the route | Compare configured mask/next-hop against actual network design | `show ip route`, `show run \| include ip route` |
| One-way connectivity (ping out works, no reply) | Missing return route on the destination router | Add static route on the far-end router back to the source network | Ping from both directions to isolate which leg fails |
| SVI shows down/down | No active port exists in that VLAN yet | Connect/activate at least one port in the VLAN | `show ip interface brief` |
| `ip routing` enabled but no routing happens | SVI exists but `ip routing` was never run, or run on wrong device | Confirm `ip routing` is active globally on the Layer-3 switch | `show running-config \| include ip routing` |
| ROAS subinterface down | Physical interface not brought up, or subinterface number/VLAN mismatch | `no shutdown` on physical interface first; verify `encapsulation dot1Q` matches | `show ip interface brief` on the router |

---

## General Troubleshooting Principles Applied Throughout

1. **Always start at Layer 1** — cabling, power, physical port — before assuming a software or configuration fault
2. **Reproduce before diagnosing** — confirm the exact symptom rather than acting on a vague description
3. **Isolate by testing each segment** — ping the immediate gateway, then the next hop, then the final destination, to find exactly where the path breaks
4. **Compare expected vs actual `show` output** — most Cisco and Windows faults are visible the moment the correct verification command is run
5. **Check the simplest explanation first** — service not running, port not authorized, cable in wrong slot — before assuming a complex configuration error
6. **Verify after every fix** — never assume a fix worked without re-testing the original symptom

---

> This reference is updated as new topics and scenarios are covered during training. For detailed incident write-ups with full diagnosis steps and root cause analysis, see the [Case Studies](README.md) in this folder.
