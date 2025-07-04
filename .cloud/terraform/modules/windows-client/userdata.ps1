# PowerShell Script for Windows Client Configuration
# Domain join, Zabbix agent, and security testing setup

# Log function
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "[$timestamp] $Message"
    Add-Content -Path "C:\client-setup.log" -Value "[$timestamp] $Message"
}

Write-Log "Starting Windows Client setup for domain ${domain_name}..."

try {
    # Set local Administrator password
    Write-Log "Configuring local Administrator account..."
    net user Administrator "${local_admin_password}"
    net user Administrator /active:yes
    
    # Rename computer to client name
    Write-Log "Renaming computer to ${client_name}..."
    Rename-Computer -NewName "${client_name}" -Force -PassThru
    
    # Configure DNS to point to Domain Controller
    Write-Log "Configuring DNS to point to Domain Controller (${domain_controller_ip})..."
    $adapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up" -and $_.InterfaceDescription -like "*Ethernet*"} | Select-Object -First 1
    if ($adapter) {
        Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses "${domain_controller_ip}"
        Write-Log "DNS configured for adapter: $($adapter.Name)"
    }
    
    # Wait for DNS to propagate
    Write-Log "Waiting for DNS resolution..."
    Start-Sleep -Seconds 30
    
    # Test domain connectivity
    Write-Log "Testing domain connectivity..."
    $pingResult = Test-Connection -ComputerName "${domain_name}" -Count 2 -Quiet
    if ($pingResult) {
        Write-Log "Domain ${domain_name} is reachable"
    } else {
        Write-Log "WARNING: Cannot reach domain ${domain_name}"
    }
    
    # Create domain join credential
    Write-Log "Preparing domain join..."
    $domainUser = "${domain_name}\${domain_admin_username}"
    $securePassword = ConvertTo-SecureString "${domain_admin_password}" -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($domainUser, $securePassword)
    
    # Join domain
    Write-Log "Joining domain ${domain_name}..."
    Add-Computer -DomainName "${domain_name}" -Credential $credential -Restart:$false -Force
    
    Write-Log "Domain join completed successfully!"
    
    # Configure security settings for testing
    %{ if enable_security_testing }
    Write-Log "Configuring security settings for testing..."
    
    # Enable LLMNR (Link-Local Multicast Name Resolution) - vulnerable to responder attacks
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -Name "EnableMulticast" -Value 1 -Force
    
    # Enable NetBIOS over TCP/IP
    $regKey = "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces"
    Get-ChildItem $regKey | ForEach-Object {
        Set-ItemProperty -Path $_.PSPath -Name "NetbiosOptions" -Value 1 -Force
    }
    
    # Configure SMB settings for testing
    Set-SmbServerConfiguration -EnableSMB1Protocol $true -Force
    Set-SmbServerConfiguration -RequireSecuritySignature $false -Force
    
    # Create test users with weak passwords (for security testing)
    Write-Log "Creating test users for security testing..."
    
    $testUsers = @(
        @{Name="testuser"; Password="Password123"; Description="Test user for security testing"},
        @{Name="serviceaccount"; Password="Service123"; Description="Service account for testing"},
        @{Name="backup_admin"; Password="backup123"; Description="Backup administrator account"}
    )
    
    foreach ($user in $testUsers) {
        try {
            New-LocalUser -Name $user.Name -Password (ConvertTo-SecureString $user.Password -AsPlainText -Force) -Description $user.Description -PasswordNeverExpires
            Add-LocalGroupMember -Group "Users" -Member $user.Name
            Write-Log "Created test user: $($user.Name)"
        } catch {
            Write-Log "User $($user.Name) may already exist or error: $($_.Exception.Message)"
        }
    }
    
    # Enable Windows features that can be tested
    Write-Log "Enabling Windows features for testing..."
    Enable-WindowsOptionalFeature -Online -FeatureName "IIS-WebServerRole" -All -NoRestart
    Enable-WindowsOptionalFeature -Online -FeatureName "IIS-HttpRedirect" -All -NoRestart
    
    # Configure weak audit policies (for testing)
    auditpol /set /category:"Account Logon" /success:disable /failure:disable
    auditpol /set /category:"Logon/Logoff" /success:disable /failure:disable
    
    Write-Log "Security testing configurations applied"
    %{ endif }
    
    # Install and configure Zabbix Agent
    %{ if enable_zabbix_agent }
    Write-Log "Installing Zabbix Agent..."
    
    # Download Zabbix Agent
    $zabbixUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/6.4/6.4.0/zabbix_agent-6.4.0-windows-amd64-openssl.msi"
    $zabbixInstaller = "C:\Windows\Temp\zabbix_agent.msi"
    
    Write-Log "Downloading Zabbix Agent from $zabbixUrl"
    Invoke-WebRequest -Uri $zabbixUrl -OutFile $zabbixInstaller
    
    # Install Zabbix Agent
    Write-Log "Installing Zabbix Agent..."
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$zabbixInstaller`" /quiet SERVER=${zabbix_server_ip} HOSTNAME=${client_name}.${domain_name}" -Wait
    
    # Configure Zabbix Agent
    Write-Log "Configuring Zabbix Agent..."
    $zabbixConfig = @"
# Zabbix Agent configuration
Server=${zabbix_server_ip}
ServerActive=${zabbix_server_ip}
Hostname=${client_name}.${domain_name}
LogFile=C:\Program Files\Zabbix Agent\zabbix_agentd.log
EnableRemoteCommands=1
UnsafeUserParameters=1
RefreshActiveChecks=60
"@
    
    $zabbixConfig | Out-File -FilePath "C:\Program Files\Zabbix Agent\zabbix_agentd.conf" -Encoding UTF8
    
    # Start Zabbix Agent service
    Write-Log "Starting Zabbix Agent service..."
    Start-Service -Name "Zabbix Agent"
    Set-Service -Name "Zabbix Agent" -StartupType Automatic
    
    Write-Log "Zabbix Agent installed and configured"
    %{ endif }
    
    # Configure Windows Firewall
    Write-Log "Configuring Windows Firewall..."
    
    # Enable RDP
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
    
    # Allow Zabbix Agent
    %{ if enable_zabbix_agent }
    New-NetFirewallRule -DisplayName "Zabbix Agent" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 10050
    %{ endif }
    
    # Allow domain communication
    New-NetFirewallRule -DisplayName "Domain Communication" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 445,139
    New-NetFirewallRule -DisplayName "NetBIOS" -Direction Inbound -Action Allow -Protocol UDP -LocalPort 137,138
    
    # Create setup completion marker
    Write-Log "Creating completion markers..."
    New-Item -Path "C:\client-configured.txt" -ItemType File -Force
    "Client configuration completed at $(Get-Date)" | Out-File -FilePath "C:\client-configured.txt"
    
    # Create info file for user
    $infoContent = @"
=== ${client_name} - Windows Client Information ===

Configuration completed: $(Get-Date)

🔐 Domain Information:
   - Domain: ${domain_name}
   - Domain Controller: ${domain_controller_ip}
   - Computer Name: ${client_name}
   - Status: Domain Joined

👤 Local Accounts:
   - Administrator: ${local_admin_password}
%{ if enable_security_testing }
   - testuser: Password123
   - serviceaccount: Service123  
   - backup_admin: backup123
%{ endif }

📊 Monitoring:
%{ if enable_zabbix_agent }
   - Zabbix Server: ${zabbix_server_ip}
   - Agent Status: Installed and Running
   - Hostname: ${client_name}.${domain_name}
%{ endif }

🔧 Security Testing Features:
%{ if enable_security_testing }
   - LLMNR: Enabled (vulnerable to responder attacks)
   - NetBIOS: Enabled  
   - SMBv1: Enabled
   - Weak audit policies: Configured
   - Test users: Created with weak passwords
%{ endif }

🎯 Ready for Security Testing:
   - Hash dumping attacks (HHID)
   - Credential spraying
   - Lateral movement testing
   - Network responder attacks

⚠️  WARNING: This machine is configured for TESTING ONLY!
    Do not use in production environments.
"@
    
    $infoContent | Out-File -FilePath "C:\Users\Public\Desktop\CLIENT-INFO.txt" -Encoding UTF8
    
    Write-Log "Setup completed successfully! Computer will restart to complete domain join."
    
} catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    Write-Log "Full error details: $($_ | Out-String)"
}

# Schedule restart to complete domain join
Write-Log "Scheduling restart in 2 minutes to complete domain join..."
shutdown /r /t 120 /c "Completing domain join and configuration" 