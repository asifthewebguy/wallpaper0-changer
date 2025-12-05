# Create Self-Signed Code Signing Certificate for Development
# This script creates a self-signed certificate for testing code signing locally
# WARNING: This will NOT remove SmartScreen warnings for other users!

param(
    [string]$SubjectName = "ATWG",
    [string]$Password = "DevCert123!",
    [int]$ValidYears = 3
)

Write-Host "================================================" -ForegroundColor Cyan
Write-Host " Creating Self-Signed Code Signing Certificate" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "WARNING: Not running as Administrator!" -ForegroundColor Yellow
    Write-Host "The certificate will be created, but you'll need admin rights to install it to Trusted Root." -ForegroundColor Yellow
    Write-Host ""
}

# Create certificate
Write-Host "Creating self-signed certificate..." -ForegroundColor Green
Write-Host "  Subject: CN=$SubjectName" -ForegroundColor Gray
Write-Host "  Valid for: $ValidYears years" -ForegroundColor Gray
Write-Host ""

try {
    $cert = New-SelfSignedCertificate `
        -Type CodeSigningCert `
        -Subject "CN=$SubjectName, O=$SubjectName, C=US" `
        -CertStoreLocation "Cert:\CurrentUser\My" `
        -KeyAlgorithm RSA `
        -KeyLength 2048 `
        -NotAfter (Get-Date).AddYears($ValidYears) `
        -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3") `
        -KeyUsage DigitalSignature `
        -FriendlyName "$SubjectName Code Signing (Self-Signed)"

    Write-Host "✓ Certificate created successfully!" -ForegroundColor Green
    Write-Host "  Thumbprint: $($cert.Thumbprint)" -ForegroundColor Gray
    Write-Host ""

    # Export certificate (without private key) for import to Trusted Root
    $cerPath = ".\$SubjectName-CodeSigning.cer"
    Export-Certificate -Cert $cert -FilePath $cerPath | Out-Null
    Write-Host "✓ Exported public certificate to: $cerPath" -ForegroundColor Green

    # Export PFX (with private key) for signing
    $pfxPath = ".\$SubjectName-CodeSigning.pfx"
    $securePassword = ConvertTo-SecureString -String $Password -Force -AsPlainText
    Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password $securePassword | Out-Null
    Write-Host "✓ Exported PFX certificate to: $pfxPath" -ForegroundColor Green
    Write-Host "  Password: $Password" -ForegroundColor Yellow
    Write-Host ""

    # Try to import to Trusted Root
    Write-Host "Attempting to install certificate to Trusted Root Certificates..." -ForegroundColor Green

    if ($isAdmin) {
        try {
            Import-Certificate -FilePath $cerPath -CertStoreLocation "Cert:\LocalMachine\Root" | Out-Null
            Write-Host "✓ Certificate installed to Trusted Root!" -ForegroundColor Green
            Write-Host "  Windows will now trust applications signed with this certificate (on this PC only)" -ForegroundColor Gray
        }
        catch {
            Write-Host "✗ Failed to install to Trusted Root: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    else {
        Write-Host "⚠ Skipped - Administrator rights required" -ForegroundColor Yellow
        Write-Host "  Run this script as Administrator to install to Trusted Root" -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host " Next Steps" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. To sign your installer, use one of these commands:" -ForegroundColor White
    Write-Host ""
    Write-Host "   Option A - Sign with PFX file:" -ForegroundColor Yellow
    Write-Host '   signtool sign /f "'$pfxPath'" /p "'$Password'" /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 /v "installer\output\InnoSetup\WallpaperChanger-Setup-v1.2.0.exe"' -ForegroundColor Gray
    Write-Host ""
    Write-Host "   Option B - Sign from certificate store:" -ForegroundColor Yellow
    Write-Host '   signtool sign /sha1 '$cert.Thumbprint' /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 /v "installer\output\InnoSetup\WallpaperChanger-Setup-v1.2.0.exe"' -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. To use with Inno Setup, edit WallpaperChanger-Signed.iss:" -ForegroundColor White
    Write-Host '   Uncomment and update Option 3 with your PFX path and password' -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. If you ran as Admin and installed to Trusted Root:" -ForegroundColor White
    Write-Host "   - Signed installers will run without warnings on THIS PC only" -ForegroundColor Gray
    Write-Host "   - Other PCs will still show SmartScreen warnings" -ForegroundColor Gray
    Write-Host ""
    Write-Host "4. For production, get a commercial certificate:" -ForegroundColor White
    Write-Host "   - See CODE_SIGNING_GUIDE.md for certificate authority options" -ForegroundColor Gray
    Write-Host "   - Commercial certs cost $179-474/year but remove warnings for all users" -ForegroundColor Gray
    Write-Host ""

    # Save certificate info to file
    $infoPath = ".\certificate-info.txt"
    @"
Self-Signed Code Signing Certificate Information
================================================

Created: $(Get-Date)
Subject: CN=$SubjectName
Thumbprint: $($cert.Thumbprint)
Valid Until: $($cert.NotAfter)

Files Created:
- $cerPath (public certificate)
- $pfxPath (with private key)

PFX Password: $Password

Sign Command (PFX):
signtool sign /f "$pfxPath" /p "$Password" /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 /v "installer\output\InnoSetup\WallpaperChanger-Setup-v1.2.0.exe"

Sign Command (Store):
signtool sign /sha1 $($cert.Thumbprint) /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 /v "installer\output\InnoSetup\WallpaperChanger-Setup-v1.2.0.exe"

Inno Setup SignTool Configuration:
SignTool=signtool sign /f "$pfxPath" /p "$Password" /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 /v `$f

IMPORTANT: This is a self-signed certificate for development only.
It will NOT eliminate SmartScreen warnings for other users.
For production, purchase a commercial code signing certificate.
"@ | Out-File -FilePath $infoPath -Encoding UTF8

    Write-Host "ℹ Certificate information saved to: $infoPath" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "✓ Done! Certificate is ready to use." -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "✗ Error creating certificate: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    exit 1
}
