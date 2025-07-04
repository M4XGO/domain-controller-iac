# Manual Startup Script for Windows Client
# Use this if userdata fails to execute automatically  
# Run as Administrator

# Variables - Edit these as needed
$DomainName = "${domain_name}"
$DomainControllerIP = "${domain_controller_ip}"
$DomainAdminUsername = "${domain_admin_username}"
$DomainAdminPassword = "${domain_admin_password}"
$LocalAdminPassword = "${local_admin_password}"
$ClientName = "${client_name}"
$ZabbixServerIP = "${zabbix_server_ip}"
$EnableZabbixAgent = "${enable_zabbix_agent}"
$EnableSecurityTesting = "${enable_security_testing}"

# Log function
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor Cyan
    Add-Content -Path "C:\client-setup-manual.log" -Value "[$timestamp] $Message"
}

Write-Log "Starting MANUAL Windows Client setup..."

try {
    # Set execution policy
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force
    Write-Log "Execution policy set to Unrestricted"

    # Check if userdata already ran
    if (Test-Path "C:\client-configured.txt") {
        Write-Log "WARNING: Windows Client appears to already be configured!"
        $choice = Read-Host "Continue anyway? (y/N)"
        if ($choice -ne "y" -and $choice -ne "Y") {
            Write-Log "Exiting..."
            exit
        }
    }

    # Display current configuration
    Write-Log "Current Configuration:"
    Write-Log "- Domain: $DomainName"
    Write-Log "- Domain Controller: $DomainControllerIP"
    Write-Log "- Client Name: $ClientName"
    Write-Log "- Zabbix Enabled: $EnableZabbixAgent"
    Write-Log "- Security Testing: $EnableSecurityTesting"

    # Run the original userdata script
    $scriptPath = "C:\Windows\Temp\client-userdata.ps1"
    if (Test-Path $scriptPath) {
        Write-Log "Found existing userdata script, executing..."
        & $scriptPath
    } else {
        Write-Log "Userdata script not found. Checking if domain join is needed..."
        
        # Check if already joined to domain
        $computerInfo = Get-ComputerInfo
        if ($computerInfo.CsDomain -eq $DomainName) {
            Write-Log "Computer is already joined to domain: $($computerInfo.CsDomain)"
        } else {
            Write-Log "Computer needs to be joined to domain."
            Write-Log "Manual steps:"
            Write-Log "1. Set DNS to $DomainControllerIP"
            Write-Log "2. Join domain $DomainName with credentials $DomainAdminUsername"
            Write-Log "3. Restart the computer"
        }
    }

    # Check userdata logs
    $userdataLogs = "C:\ProgramData\Amazon\EC2-Windows\Launch\Log"
    if (Test-Path $userdataLogs) {
        Write-Log "Userdata logs location: $userdataLogs"
        $latestLog = Get-ChildItem $userdataLogs -Filter "*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($latestLog) {
            Write-Log "Latest userdata log: $($latestLog.FullName)"
        }
    }

} catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    Write-Log "Full error: $($_ | Out-String)"
}

Write-Log "Manual setup completed. Check logs for details."
Write-Log "Log file: C:\client-setup-manual.log"
Read-Host "Press Enter to continue..." 