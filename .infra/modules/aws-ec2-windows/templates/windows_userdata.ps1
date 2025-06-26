# Windows Server 2022 User Data Script - Free Tier Optimized
# Domain Controller Setup for AWS EC2

# Enable logging
Start-Transcript -Path "C:\userdata-execution.log" -Append

Write-Host "=== Starting Windows Server Configuration for Domain Controller ===" -ForegroundColor Green
Write-Host "Free Tier Optimized Setup" -ForegroundColor Yellow

# Variables from Terraform
$DomainName = "${domain_name}"
$SafeModePassword = "${safe_mode_password}"
$AdminUsername = "${admin_username}"
$AdminPassword = "${admin_password}"
$EnableCloudWatch = ${enable_cloudwatch}
$EnableSSM = ${enable_ssm}

# Free Tier: Single volume setup (all on C:)
$DataPath = "C:\NTDS"
$LogPath = "C:\Logs" 
$SysvolPath = "C:\SYSVOL"

Write-Host "Domain: $DomainName" -ForegroundColor Cyan
Write-Host "Admin User: $AdminUsername" -ForegroundColor Cyan

try {
    # 1. Basic Windows Configuration
    Write-Host "=== Configuring Basic Windows Settings ===" -ForegroundColor Green
    
    # Set timezone to UTC (recommended for servers)
    Set-TimeZone -Name "UTC"
    
    # Disable Windows Defender real-time protection (Free Tier optimization)
    Write-Host "Disabling Windows Defender real-time protection for better performance..."
    Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
    
    # Set high performance power plan
    powercfg.exe /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    
    # Disable Windows Update automatic restart (prevent unexpected reboots)
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoRebootWithLoggedOnUsers /t REG_DWORD /d 1 /f
    
    # 2. Create Directory Structure (Free Tier: all on C: drive)
    Write-Host "=== Creating Directory Structure ===" -ForegroundColor Green
    
    $Directories = @($DataPath, $LogPath, $SysvolPath)
    foreach ($Dir in $Directories) {
        if (!(Test-Path $Dir)) {
            New-Item -Path $Dir -ItemType Directory -Force
            Write-Host "Created directory: $Dir" -ForegroundColor Green
        }
    }
    
    # 3. Configure WinRM for Ansible (Essential for automation)
    Write-Host "=== Configuring WinRM for Ansible ===" -ForegroundColor Green
    
    # Enable WinRM
    Enable-PSRemoting -Force -SkipNetworkProfileCheck
    
    # Configure WinRM settings
    winrm quickconfig -quiet
    winrm set winrm/config/service '@{AllowUnencrypted="true"}'
    winrm set winrm/config/service/auth '@{Basic="true"}'
    winrm set winrm/config/client '@{TrustedHosts="*"}'
    
    # Create HTTPS listener
    $cert = New-SelfSignedCertificate -DnsName $env:COMPUTERNAME -CertStoreLocation cert:\LocalMachine\My
    winrm create winrm/config/Listener?Address=*+Transport=HTTPS "@{Hostname=`"$env:COMPUTERNAME`"; CertificateThumbprint=`"$($cert.Thumbprint)`"}"
    
    # Configure firewall for WinRM
    New-NetFirewallRule -DisplayName "WinRM HTTPS" -Direction Inbound -Protocol TCP -LocalPort 5986 -Action Allow
    New-NetFirewallRule -DisplayName "WinRM HTTP" -Direction Inbound -Protocol TCP -LocalPort 5985 -Action Allow
    
    Write-Host "WinRM configured successfully" -ForegroundColor Green
    
    # 4. Install Active Directory Windows Features
    Write-Host "=== Installing Active Directory Features ===" -ForegroundColor Green
    
    # Install AD Domain Services and DNS
    $Features = @(
        "AD-Domain-Services",
        "DNS",
        "RSAT-AD-Tools",
        "RSAT-DNS-Server"
    )
    
    foreach ($Feature in $Features) {
        Write-Host "Installing feature: $Feature"
        Install-WindowsFeature -Name $Feature -IncludeManagementTools
    }
    
    Write-Host "Active Directory features installed successfully" -ForegroundColor Green
    
    # 5. Configure CloudWatch (Free Tier)
    if ($EnableCloudWatch -eq "true") {
        Write-Host "=== Configuring CloudWatch (Free Tier) ===" -ForegroundColor Green
        
        try {
            # Download and install CloudWatch agent (Free Tier eligible)
            $CloudWatchInstallerPath = "C:\amazon-cloudwatch-agent.msi"
            Invoke-WebRequest -Uri "https://s3.amazonaws.com/amazoncloudwatch-agent/windows/amd64/latest/amazon-cloudwatch-agent.msi" -OutFile $CloudWatchInstallerPath
            
            # Install CloudWatch agent
            Start-Process msiexec.exe -ArgumentList "/i $CloudWatchInstallerPath /quiet" -Wait
            
            # Basic CloudWatch configuration (Free Tier optimized)
            $CloudWatchConfig = @{
                logs = @{
                    logs_collected = @{
                        windows_events = @{
                            collect_list = @(
                                @{
                                    event_name = "System"
                                    event_levels = @("ERROR", "WARNING")
                                    log_group_name = "${log_group_name}"
                                    log_stream_name = "{instance_id}/System"
                                },
                                @{
                                    event_name = "Application"
                                    event_levels = @("ERROR", "WARNING")
                                    log_group_name = "${log_group_name}"
                                    log_stream_name = "{instance_id}/Application"
                                }
                            )
                        }
                    }
                }
            }
            
            $CloudWatchConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath "C:\ProgramData\Amazon\AmazonCloudWatchAgent\amazon-cloudwatch-agent.json"
            
            Write-Host "CloudWatch agent configured" -ForegroundColor Green
        }
        catch {
            Write-Warning "CloudWatch configuration failed: $($_.Exception.Message)"
        }
    }
    
    # 6. Install Chocolatey for package management (Free)
    Write-Host "=== Installing Chocolatey ===" -ForegroundColor Green
    
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    
    # Install essential tools via Chocolatey
    choco install notepadplusplus -y
    choco install 7zip -y
    
    Write-Host "Chocolatey and tools installed" -ForegroundColor Green
    
    # 7. Optimize for Free Tier performance
    Write-Host "=== Applying Free Tier Performance Optimizations ===" -ForegroundColor Green
    
    # Disable unnecessary services for better performance
    $ServicesToDisable = @(
        "Themes",
        "TabletInputService", 
        "Fax",
        "WSearch"  # Windows Search (can be resource intensive)
    )
    
    foreach ($Service in $ServicesToDisable) {
        try {
            Set-Service -Name $Service -StartupType Disabled -ErrorAction SilentlyContinue
            Stop-Service -Name $Service -Force -ErrorAction SilentlyContinue
            Write-Host "Disabled service: $Service" -ForegroundColor Yellow
        }
        catch {
            Write-Warning "Could not disable service $Service"
        }
    }
    
    # Configure virtual memory (important for t2.micro)
    $ComputerSystem = Get-WmiObject -Class Win32_ComputerSystem
    $ComputerSystem.AutomaticManagedPagefile = $false
    $ComputerSystem.Put()
    
    # Set page file to 2GB (good for t2.micro with 1GB RAM)
    $PageFile = Get-WmiObject -Class Win32_PageFileSetting
    if ($PageFile) {
        $PageFile.Delete()
    }
    Set-WmiInstance -Class Win32_PageFileSetting -Arguments @{SettingID="pagefile.sys @ C:"; InitialSize=2048; MaximumSize=2048}
    
    Write-Host "Performance optimizations applied" -ForegroundColor Green
    
    # 8. Create domain setup script for later execution
    Write-Host "=== Creating Domain Setup Script ===" -ForegroundColor Green
    
    $DomainSetupScript = @"
# Domain Controller Promotion Script
Write-Host "Starting Domain Controller promotion..." -ForegroundColor Green

# Convert password to secure string
`$SecurePassword = ConvertTo-SecureString "$SafeModePassword" -AsPlainText -Force

# Promote server to Domain Controller
Install-ADDSForest ``
    -DomainName "$DomainName" ``
    -DomainNetbiosName "$((${domain_name} -split '\.')[0].ToUpper())" ``
    -DatabasePath "$DataPath" ``
    -LogPath "$LogPath" ``
    -SysvolPath "$SysvolPath" ``
    -SafeModeAdministratorPassword `$SecurePassword ``
    -InstallDns ``
    -Force ``
    -NoRebootOnCompletion

Write-Host "Domain Controller promotion completed. Reboot required." -ForegroundColor Green
"@

    $DomainSetupScript | Out-File -FilePath "C:\setup-domain.ps1" -Encoding UTF8
    
    Write-Host "Domain setup script created at C:\setup-domain.ps1" -ForegroundColor Green
    
    # 9. Final configurations
    Write-Host "=== Final Configurations ===" -ForegroundColor Green
    
    # Create post-reboot script to finalize domain setup
    $PostRebootScript = @"
# Post-reboot domain configuration
if ((Get-WmiObject -Class Win32_ComputerSystem).Domain -eq "$DomainName") {
    Write-Host "Domain Controller promotion successful!" -ForegroundColor Green
    
    # Configure DNS forwarders (Google DNS for internet resolution)
    Add-DnsServerForwarder -IPAddress 8.8.8.8, 8.8.4.4
    
    # Create basic OU structure
    New-ADOrganizationalUnit -Name "Servers" -Path "DC=$((${domain_name} -replace '\.',',DC='))"
    New-ADOrganizationalUnit -Name "Workstations" -Path "DC=$((${domain_name} -replace '\.',',DC='))"
    New-ADOrganizationalUnit -Name "Users" -Path "DC=$((${domain_name} -replace '\.',',DC='))"
    
    Write-Host "Basic AD structure created" -ForegroundColor Green
    
    # Remove this startup script
    Remove-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "PostRebootScript" -ErrorAction SilentlyContinue
} else {
    Write-Host "Executing domain setup..." -ForegroundColor Yellow
    PowerShell.exe -ExecutionPolicy Bypass -File "C:\setup-domain.ps1"
    Restart-Computer -Force
}
"@

    $PostRebootScript | Out-File -FilePath "C:\post-reboot.ps1" -Encoding UTF8
    
    # Set script to run after reboot
    Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "PostRebootScript" -Value "PowerShell.exe -ExecutionPolicy Bypass -File C:\post-reboot.ps1"
    
    Write-Host "Post-reboot script configured" -ForegroundColor Green
    
    Write-Host "=== Windows Server Configuration Completed Successfully ===" -ForegroundColor Green
    Write-Host "The server is ready for Domain Controller promotion." -ForegroundColor Green
    Write-Host "Rebooting to apply all changes..." -ForegroundColor Yellow
    
    # Schedule reboot in 2 minutes to allow userdata to complete
    shutdown.exe /r /t 120 /c "Rebooting to complete Domain Controller setup"
    
} catch {
    Write-Error "Configuration failed: $($_.Exception.Message)"
    Write-Error $_.ScriptStackTrace
} finally {
    Stop-Transcript
} 