# Manual Startup Script for Domain Controller
# Use this if userdata fails to execute automatically
# Run as Administrator

# Variables - Edit these as needed
$DomainName = "${domain_name}"
$DomainNetBiosName = "${domain_netbios_name}"  
$AdminPassword = "${admin_password}"
$SafeModePassword = "${safe_mode_password}"

# Log function
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor Green
    Add-Content -Path "C:\dc-setup-manual.log" -Value "[$timestamp] $Message"
}

Write-Log "Starting MANUAL Domain Controller setup..."

try {
    # Set execution policy
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force
    Write-Log "Execution policy set to Unrestricted"

    # Check if userdata already ran
    if (Test-Path "C:\dc-configured.txt") {
        Write-Log "WARNING: Domain Controller appears to already be configured!"
        $choice = Read-Host "Continue anyway? (y/N)"
        if ($choice -ne "y" -and $choice -ne "Y") {
            Write-Log "Exiting..."
            exit
        }
    }

    # Run the original userdata script
    $scriptPath = "C:\Windows\Temp\userdata.ps1"
    if (Test-Path $scriptPath) {
        Write-Log "Found existing userdata script, executing..."
        & $scriptPath
    } else {
        Write-Log "Userdata script not found, downloading and running inline script..."
        
        # Include the original script content inline here
        Write-Log "Please run the original userdata script manually or check logs at C:\ProgramData\Amazon\EC2-Windows\Launch\Log\"
    }

} catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    Write-Log "Full error: $($_ | Out-String)"
}

Write-Log "Manual setup completed. Check logs for details."
Read-Host "Press Enter to continue..." 