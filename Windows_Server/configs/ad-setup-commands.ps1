# ============================================================
# Active Directory Setup Commands — georgi.local Domain
# Windows Server 2019 | Vatanix Technologies Lab
# ============================================================

# --- Install AD DS Role ---
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# --- Promote to Domain Controller (new forest) ---
Install-ADDSForest `
    -DomainName "georgi.local" `
    -DomainNetBIOSName "GEORGI" `
    -ForestMode "WinThreshold" `
    -DomainMode "WinThreshold" `
    -InstallDns:$true `
    -Force:$true

# --- Create Organisational Units ---
New-ADOrganizationalUnit -Name "IT" -Path "DC=georgi,DC=local"
New-ADOrganizationalUnit -Name "Users" -Path "OU=IT,DC=georgi,DC=local"
New-ADOrganizationalUnit -Name "Computers" -Path "OU=IT,DC=georgi,DC=local"

# --- Create Users ---
New-ADUser `
    -Name "trainee01" `
    -GivenName "Trainee" `
    -Surname "01" `
    -SamAccountName "trainee01" `
    -UserPrincipalName "trainee01@georgi.local" `
    -Path "OU=Users,OU=IT,DC=georgi,DC=local" `
    -AccountPassword (ConvertTo-SecureString "Pass@1234" -AsPlainText -Force) `
    -Enabled $true

# --- Create Security Group ---
New-ADGroup `
    -Name "IT-Staff" `
    -GroupScope Global `
    -GroupCategory Security `
    -Path "OU=IT,DC=georgi,DC=local"

# --- Add User to Group ---
Add-ADGroupMember -Identity "IT-Staff" -Members "trainee01"

# --- Verify Domain Controller ---
Get-ADDomainController

# --- List all users ---
Get-ADUser -Filter * | Select Name, SamAccountName, Enabled

# --- List all OUs ---
Get-ADOrganizationalUnit -Filter * | Select Name, DistinguishedName

# --- Force GPO update ---
gpupdate /force

# --- View applied GPOs ---
gpresult /r
