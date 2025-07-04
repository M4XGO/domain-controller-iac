# PowerShell Script for Domain Controller Setup
# Simple configuration for school project with full DNS setup

# Log function with enhanced debugging
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "[$timestamp] $Message"
    Add-Content -Path "C:\dcsetup.log" -Value "[$timestamp] $Message"
    # Also log to console for userdata debugging
    Write-Host "[$timestamp] $Message" -ForegroundColor Green
}

# Create debug information
Write-Log "=== USERDATA SCRIPT STARTED ==="
Write-Log "PowerShell Version: $($PSVersionTable.PSVersion)"
Write-Log "Execution Policy: $(Get-ExecutionPolicy)"
Write-Log "Current User: $env:USERNAME"
Write-Log "Computer Name: $env:COMPUTERNAME"
Write-Log "Script Path: $($MyInvocation.MyCommand.Path)"

# Save a copy of this script for manual execution if needed
try {
    $scriptContent = Get-Content $MyInvocation.MyCommand.Path -Raw
    $scriptContent | Out-File "C:\Windows\Temp\dc-userdata-manual.ps1" -Encoding UTF8 -Force
    Write-Log "Manual execution script saved to C:\Windows\Temp\dc-userdata-manual.ps1"
} catch {
    Write-Log "Could not save manual script: $($_.Exception.Message)"
}

# Start setup
Write-Log "Starting Domain Controller setup with full DNS configuration..."

try {
    # Set Administrator password
    Write-Log "Setting Administrator password..."
    net user Administrator "${admin_password}"
    
    # Enable Administrator account if disabled
    net user Administrator /active:yes
    
    # Install Windows Features
    Write-Log "Installing Active Directory Domain Services..."
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -Restart:$false
    
    Write-Log "Installing DNS Server..."
    Install-WindowsFeature -Name DNS -IncludeManagementTools -Restart:$false
    
    # Import AD DS Module
    Import-Module ADDSDeployment
    
    # Configure Domain Controller
    Write-Log "Configuring new Active Directory Forest: ${domain_name}"
    
    $securePassword = ConvertTo-SecureString "${safe_mode_password}" -AsPlainText -Force
    
    Install-ADDSForest `
        -DomainName "${domain_name}" `
        -DomainNetbiosName "${domain_netbios_name}" `
        -ForestMode "WinThreshold" `
        -DomainMode "WinThreshold" `
        -DatabasePath "C:\Windows\NTDS" `
        -LogPath "C:\Windows\NTDS" `
        -SysvolPath "C:\Windows\SYSVOL" `
        -SafeModeAdministratorPassword $securePassword `
        -InstallDns:$true `
        -CreateDnsDelegation:$false `
        -NoRebootOnCompletion:$true `
        -Force:$true
        
    Write-Log "Domain Controller setup completed, configuring DNS zones..."
    
    # Wait for services to start
    Start-Sleep -Seconds 30
    
    # Import DNS Module
    Import-Module DnsServer
    
    # Configure DNS Forwarders
    Write-Log "Configuring DNS forwarders..."
    Set-DnsServerForwarder -IPAddress 8.8.8.8,1.1.1.1,8.8.4.4 -PassThru
    
    # Configure reverse lookup zone for 10.0.0.0/16 network
    Write-Log "Creating reverse lookup zone for 10.0.0.0/16..."
    Add-DnsServerPrimaryZone -NetworkId "10.0.0.0/16" -ReplicationScope "Forest"
    
    # Add some useful DNS records
    Write-Log "Adding DNS records..."
    
    # Add A record for domain controller itself
    $dcIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "10.0.*"}).IPAddress
    Add-DnsServerResourceRecordA -ZoneName "${domain_name}" -Name "dc1" -IPv4Address $dcIP
    
    # Add PTR record for reverse zone
    $reverseName = $dcIP.Split('.')[3] + "." + $dcIP.Split('.')[2]
    Add-DnsServerResourceRecordPtr -ZoneName "0.10.in-addr.arpa" -Name $reverseName -PtrDomainName "dc1.${domain_name}"
    
    # Configure DNS server settings
    Write-Log "Configuring DNS server settings..."
    Set-DnsServerRecursion -Enable $true
    Set-DnsServerCache -LockingPercent 100
    
    # Enable DNS logging for troubleshooting
    Set-DnsServerDiagnostics -Answers $true -Queries $true -SaveLogsToPersistentStorage $true
    
    Write-Log "DNS configuration completed successfully!"
    
} catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    Write-Log "Full error details: $($_ | Out-String)"
}

# Configure Windows Firewall for domain services
Write-Log "Configuring Windows Firewall..."
netsh advfirewall firewall set rule group="Remote Desktop" new enable=Yes
netsh advfirewall firewall set rule group="Active Directory Domain Services" new enable=Yes
netsh advfirewall firewall set rule group="DNS Service" new enable=Yes

# Additional firewall rules for monitoring
netsh advfirewall firewall add rule name="Zabbix Agent" dir=in action=allow protocol=TCP localport=10050

Write-Log "Setup script completed. Domain: ${domain_name}, DNS configured with forwarders. Check C:\dcsetup.log for details."

# Schedule a reboot in 2 minutes to complete AD setup
Write-Log "Scheduling reboot in 2 minutes to complete Active Directory setup..."
shutdown /r /t 120 /c "Completing Active Directory installation" 