# ============================================================
# DNS and DHCP Configuration Commands — georgi.local
# Windows Server 2019 | Vatanix Technologies Lab
# ============================================================

# --- DNS: Create Forward Lookup Zone ---
Add-DnsServerPrimaryZone `
    -Name "georgi.local" `
    -ReplicationScope "Forest" `
    -PassThru

# --- DNS: Create Reverse Lookup Zone ---
Add-DnsServerPrimaryZone `
    -NetworkID "10.10.11.0/24" `
    -ReplicationScope "Forest" `
    -PassThru

# --- DNS: Add PTR Record for DC ---
Add-DnsServerResourceRecordPtr `
    -ZoneName "11.10.10.in-addr.arpa" `
    -Name "14" `
    -PtrDomainName "winserver2019.georgi.local"

# --- DNS: Verify zones ---
Get-DnsServerZone

# --- DNS: Test resolution ---
# Run in CMD: nslookup georgi.local
# Run in CMD: nslookup 10.10.11.14

# --- DHCP: Install role ---
Install-WindowsFeature -Name DHCP -IncludeManagementTools

# --- DHCP: Authorize server in AD ---
Add-DhcpServerInDC

# --- DHCP: Create scope ---
Add-DhcpServerv4Scope `
    -Name "Lab-Clients" `
    -StartRange 10.10.11.50 `
    -EndRange 10.10.11.100 `
    -SubnetMask 255.255.255.0 `
    -State Active

# --- DHCP: Set scope options ---
Set-DhcpServerv4OptionValue `
    -ScopeId 10.10.11.0 `
    -Router 10.10.11.1 `
    -DnsServer 10.10.11.14 `
    -DnsDomain "georgi.local"

# --- DHCP: Verify scope ---
Get-DhcpServerv4Scope
Get-DhcpServerv4Lease -ScopeId 10.10.11.0
