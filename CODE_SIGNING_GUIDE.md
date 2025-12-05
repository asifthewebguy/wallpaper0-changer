# Code Signing Guide for Wallpaper Changer

This guide explains how to eliminate the Windows SmartScreen "Unknown Publisher" warning by code signing your installer.

## Table of Contents
- [Why Code Signing Matters](#why-code-signing-matters)
- [Option 1: Commercial Code Signing Certificate](#option-1-commercial-code-signing-certificate-recommended)
- [Option 2: Self-Signed Certificate (Testing Only)](#option-2-self-signed-certificate-testing-only)
- [Signing the Installer](#signing-the-installer)
- [Verifying the Signature](#verifying-the-signature)
- [Troubleshooting](#troubleshooting)

---

## Why Code Signing Matters

Without code signing, Windows shows this warning:

```
Windows protected your PC
Microsoft Defender SmartScreen prevented an unrecognized app from starting.
Publisher: Unknown publisher
```

With proper code signing:
- ✅ Your company name appears as the publisher
- ✅ Users can verify the installer hasn't been tampered with
- ✅ Windows SmartScreen trust builds over time
- ✅ Professional appearance for distribution

---

## Option 1: Commercial Code Signing Certificate (Recommended)

### Step 1: Purchase a Code Signing Certificate

**Recommended Certificate Authorities:**

| Provider | Price (Annual) | Type | Notes |
|----------|---------------|------|-------|
| [DigiCert](https://www.digicert.com/signing/code-signing-certificates) | $474/year | Standard | Industry leader, high trust |
| [Sectigo (Comodo)](https://sectigo.com/ssl-certificates-tls/code-signing) | $179/year | Standard | Budget-friendly |
| [SSL.com](https://www.ssl.com/certificates/code-signing/) | $199/year | Standard | Good balance |
| [GlobalSign](https://www.globalsign.com/en/code-signing-certificate) | $299/year | Standard | Fast issuance |

**Requirements:**
- Business verification (company documents, DUNS number)
- Personal identity verification (government ID)
- Processing time: 1-7 days

**For Individual Developers:**
- Some CAs offer individual code signing certificates
- Requires government ID and address verification
- Sectigo and SSL.com support individual developers

### Step 2: Install the Certificate

After purchasing, you'll receive either:

#### A. **USB Token (EV Code Signing)** - Most Secure
```powershell
# Certificate comes on a hardware USB token
# Simply plug in the USB token - Windows will detect it automatically
# No installation needed
```

#### B. **PFX File (Standard Code Signing)**
```powershell
# Install PFX certificate to Windows Certificate Store
certutil -user -p "YOUR_PASSWORD" -importPFX "path\to\certificate.pfx"

# Or double-click the .pfx file and follow the wizard:
# 1. Current User
# 2. Browse to .pfx file
# 3. Enter password
# 4. Place in "Personal" store
```

### Step 3: Configure Inno Setup for Signing

The WallpaperChanger.iss file has been updated to support signing. You need to:

**3.1. Set Environment Variables (Recommended for CI/CD):**

```powershell
# Windows PowerShell
$env:SIGN_TOOL_PATH = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe"
$env:SIGN_CERT_SUBJECT = "Your Company Name"  # Or certificate thumbprint
$env:SIGN_TIMESTAMP_URL = "http://timestamp.digicert.com"
```

**3.2. Or Update the Script Directly:**

Edit the `[Setup]` section in `WallpaperChanger.iss`:

```ini
SignTool=signtool sign /n "Your Company Name" /t http://timestamp.digicert.com /fd SHA256 /v $f
```

Replace `"Your Company Name"` with the exact name on your certificate.

### Step 4: Build the Signed Installer

```powershell
# Build the application
dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -o publish

# Compile the installer with Inno Setup (signing happens automatically)
iscc WallpaperChanger.iss
```

The installer will be signed automatically during compilation!

---

## Option 2: Self-Signed Certificate (Testing Only)

⚠️ **Warning:** Self-signed certificates still show SmartScreen warnings. Use only for:
- Internal testing
- Development environments
- Learning about code signing

### Step 1: Create a Self-Signed Certificate

```powershell
# Run PowerShell as Administrator

# Create a self-signed code signing certificate
$cert = New-SelfSignedCertificate `
    -Type CodeSigningCert `
    -Subject "CN=ATWG, O=ATWG, C=US" `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -KeyAlgorithm RSA `
    -KeyLength 2048 `
    -NotAfter (Get-Date).AddYears(3) `
    -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3")

# Export certificate
$pwd = ConvertTo-SecureString -String "YourPassword123!" -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath "ATWG-CodeSigning.pfx" -Password $pwd

Write-Host "Certificate created and exported to ATWG-CodeSigning.pfx"
Write-Host "Thumbprint: $($cert.Thumbprint)"
```

### Step 2: Install to Trusted Root (Local Machine Only)

```powershell
# Import to Trusted Root Certificates Store (for local testing)
Import-Certificate -FilePath "ATWG-CodeSigning.cer" -CertStoreLocation "Cert:\LocalMachine\Root"

Write-Host "Certificate installed. Windows will now trust applications signed with this certificate."
```

⚠️ **Note:** This only works on YOUR machine. Other users will still see warnings!

### Step 3: Sign the Installer

```powershell
# Set the signtool path
$signtool = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe"

# Sign the installer
& $signtool sign `
    /f "ATWG-CodeSigning.pfx" `
    /p "YourPassword123!" `
    /fd SHA256 `
    /tr "http://timestamp.digicert.com" `
    /td SHA256 `
    /v `
    "installer\output\InnoSetup\WallpaperChanger-Setup-v1.2.0.exe"
```

---

## Signing the Installer

### Manual Signing (If Not Automated)

```powershell
# Find signtool.exe (part of Windows SDK)
$signtool = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe"

# Sign with certificate from store (by subject name)
& $signtool sign `
    /n "Your Company Name" `
    /fd SHA256 `
    /tr "http://timestamp.digicert.com" `
    /td SHA256 `
    /v `
    "installer\output\InnoSetup\WallpaperChanger-Setup-v1.2.0.exe"

# Or sign with PFX file
& $signtool sign `
    /f "path\to\certificate.pfx" `
    /p "certificate_password" `
    /fd SHA256 `
    /tr "http://timestamp.digicert.com" `
    /td SHA256 `
    /v `
    "installer\output\InnoSetup\WallpaperChanger-Setup-v1.2.0.exe"
```

### Timestamp Servers

Use these reliable timestamp servers (try in order if one is down):

```
http://timestamp.digicert.com
http://timestamp.sectigo.com
http://timestamp.globalsign.com
http://timestamp.comodoca.com
```

Timestamping is **critical** - it allows your signature to remain valid even after the certificate expires!

---

## Verifying the Signature

### Method 1: Windows Properties

1. Right-click the installer file
2. Click **Properties**
3. Go to **Digital Signatures** tab
4. You should see your signature with status "This digital signature is OK"

### Method 2: PowerShell

```powershell
# Check signature
Get-AuthenticodeSignature "installer\output\InnoSetup\WallpaperChanger-Setup-v1.2.0.exe" | Format-List

# Expected output:
# SignerCertificate : [Subject] CN=Your Company Name
# Status            : Valid
# StatusMessage     : Signature verified.
```

### Method 3: SignTool Verify

```powershell
$signtool = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe"

& $signtool verify /pa /v "installer\output\InnoSetup\WallpaperChanger-Setup-v1.2.0.exe"
```

---

## Building SmartScreen Reputation

Even with a valid code signature, new certificates may still trigger SmartScreen initially. To build reputation:

1. **Download Statistics**: More downloads = faster reputation building
2. **Clean Record**: No malware reports
3. **Time**: Reputation builds over weeks/months
4. **Consistent Identity**: Always use the same certificate for your releases

**Timeline:**
- Day 1-7: May still see SmartScreen warnings
- Week 2-4: Warnings become less frequent
- Month 2+: Most users won't see warnings

---

## GitHub Actions Integration

For automated signing in CI/CD, see [.github/workflows/release.yml](.github/workflows/release.yml):

```yaml
- name: Sign Installer
  if: env.SIGN_CERT_SUBJECT != ''
  run: |
    $signtool = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe"
    & $signtool sign `
      /n "$env:SIGN_CERT_SUBJECT" `
      /fd SHA256 `
      /tr "$env:SIGN_TIMESTAMP_URL" `
      /td SHA256 `
      /v `
      "installer\output\InnoSetup\WallpaperChanger-Setup-v${{ env.APP_VERSION }}.exe"
  env:
    SIGN_CERT_SUBJECT: ${{ secrets.SIGN_CERT_SUBJECT }}
    SIGN_TIMESTAMP_URL: ${{ secrets.SIGN_TIMESTAMP_URL }}
```

Store certificate in GitHub Secrets:
- `SIGN_CERT_SUBJECT`: Certificate subject name or thumbprint
- `SIGN_TIMESTAMP_URL`: Timestamp server URL

---

## Troubleshooting

### "SignTool not found"

**Install Windows SDK:**
1. Download from https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/
2. Select only "Windows App Certification Kit" component
3. signtool.exe will be installed

**Or find existing installation:**
```powershell
Get-ChildItem "C:\Program Files (x86)\Windows Kits\" -Recurse -Filter "signtool.exe" | Select-Object FullName
```

### "No certificates were found that met all the given criteria"

```powershell
# List all code signing certificates
Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert

# Or
certutil -user -store My
```

### "The specified timestamp server either could not be reached"

Try a different timestamp server from the list above, or retry after a few minutes.

### "SignTool Error: The file is being used by another process"

Close the installer file if it's open in another program.

### SmartScreen Still Showing After Signing

1. **Check Signature:** Use verification methods above
2. **Valid CA:** Ensure certificate is from a trusted CA (not self-signed)
3. **EV Certificate:** Consider upgrading to EV certificate for immediate trust
4. **Build Reputation:** Submit file to Microsoft for reputation building:
   - https://www.microsoft.com/en-us/wdsi/filesubmission

---

## Cost Comparison

| Option | Cost | SmartScreen Removed? | Effort | Best For |
|--------|------|---------------------|--------|----------|
| **No Signing** | $0 | ❌ No | None | Testing only |
| **Self-Signed** | $0 | ❌ No (still warns) | Low | Local dev |
| **Standard Cert** | $179-474/yr | ⚠️ Eventually | Medium | Small projects |
| **EV Certificate** | $300-600/yr | ✅ Immediately | Medium | Professional |

---

## Recommended Approach

### For Open Source / Personal Projects:
1. Start with **self-signed** for development
2. Get **Standard Certificate** from Sectigo ($179/year) when ready to distribute
3. Wait 2-4 weeks for reputation to build

### For Commercial / Professional Projects:
1. Get **EV Certificate** ($300-600/year)
2. Immediate trust without waiting for reputation
3. Best user experience

---

## Additional Resources

- [Microsoft: Code Signing Best Practices](https://docs.microsoft.com/en-us/windows-hardware/drivers/dashboard/code-signing-best-practices)
- [SignTool Documentation](https://docs.microsoft.com/en-us/windows/win32/seccrypto/signtool)
- [Inno Setup Code Signing](https://jrsoftware.org/ishelp/index.php?topic=setup_signtool)
- [SmartScreen Reputation Building](https://docs.microsoft.com/en-us/windows/security/threat-protection/windows-defender-smartscreen/windows-defender-smartscreen-overview)

---

## Quick Start Summary

**For Production:**
```bash
# 1. Buy certificate from Sectigo/DigiCert
# 2. Install certificate to Windows Store
# 3. Set environment variable
$env:SIGN_CERT_SUBJECT = "Your Company Name"
# 4. Build - signing happens automatically
iscc WallpaperChanger.iss
```

**For Testing:**
```powershell
# 1. Create self-signed cert
New-SelfSignedCertificate -Type CodeSigningCert -Subject "CN=ATWG" ...
# 2. Build installer
iscc WallpaperChanger.iss
# 3. Sign manually
signtool sign /f cert.pfx /p password ...
```

