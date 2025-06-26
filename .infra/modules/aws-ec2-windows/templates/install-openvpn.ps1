# Install OpenVPN on Domain Controller
# This script installs OpenVPN Access Server on Windows

Write-Host "Installing OpenVPN Access Server..." -ForegroundColor Green

# Download OpenVPN Access Server
$OpenVPNUrl = "https://openvpn.net/downloads/openvpn-as-latest-windows.msi"
$InstallerPath = "C:\openvpn-as-installer.msi"

try {
    # Download installer
    Invoke-WebRequest -Uri $OpenVPNUrl -OutFile $InstallerPath
    
    # Install OpenVPN AS
    Start-Process msiexec.exe -ArgumentList "/i $InstallerPath /quiet" -Wait
    
    # Configure firewall for OpenVPN
    New-NetFirewallRule -DisplayName "OpenVPN TCP" -Direction Inbound -Protocol TCP -LocalPort 943 -Action Allow
    New-NetFirewallRule -DisplayName "OpenVPN UDP" -Direction Inbound -Protocol UDP -LocalPort 1194 -Action Allow
    New-NetFirewallRule -DisplayName "OpenVPN Admin" -Direction Inbound -Protocol TCP -LocalPort 945 -Action Allow
    
    Write-Host "OpenVPN installed successfully!" -ForegroundColor Green
    Write-Host "Access admin panel at: https://[DC-IP]:943/admin" -ForegroundColor Yellow
    Write-Host "Default admin credentials: openvpn/openvpn" -ForegroundColor Yellow
    
} catch {
    Write-Error "OpenVPN installation failed: $($_.Exception.Message)"
} 