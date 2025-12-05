# Fixing Windows SmartScreen "Unknown Publisher" Warning

## The Problem

When users try to run `WallpaperChanger-Setup-v1.2.0.exe`, they see:

```
Windows protected your PC
Microsoft Defender SmartScreen prevented an unrecognized app from starting.
Publisher: Unknown publisher
```

## The Solution: Code Signing

To fix this permanently and make your publisher identifiable, you need to **code sign** your installer with a digital certificate.

---

## Quick Start

### For Testing/Development (Free, but still shows warnings to others)

```powershell
# 1. Create a self-signed certificate (run as Administrator)
.\Create-SelfSignedCert.ps1

# 2. Build your installer with the generated certificate
iscc WallpaperChanger-Signed.iss

# 3. The installer will be signed automatically
# Located at: installer\output\InnoSetup\WallpaperChanger-Setup-v1.2.0.exe
```

**Result:** Works on your PC, but others still see warnings.

---

### For Production (Removes warnings for everyone)

```powershell
# 1. Purchase a code signing certificate ($179-474/year)
#    Recommended: Sectigo ($179/year) or DigiCert ($474/year)
#    See CODE_SIGNING_GUIDE.md for details

# 2. Install the certificate to Windows

# 3. Update WallpaperChanger-Signed.iss:
#    Uncomment SignTool line and add your company name:
#    SignTool=signtool sign /n "Your Company Name" /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 /v $f

# 4. Build the signed installer
iscc WallpaperChanger-Signed.iss
```

**Result:** ✅ Professional installer with your company name as publisher, no warnings after reputation builds.

---

## Three Options Explained

### Option 1: Do Nothing (Current State)
- **Cost:** $0
- **User Experience:** SmartScreen warning, "Unknown publisher"
- **Best For:** Development/testing only
- **Security:** Users can click "More info" → "Run anyway"

### Option 2: Self-Signed Certificate
- **Cost:** $0
- **User Experience:** Still shows SmartScreen warning (but signed on your PC)
- **Best For:** Local development and testing
- **Tool:** Use `Create-SelfSignedCert.ps1` script
- **Time:** 5 minutes

### Option 3: Commercial Certificate (Recommended)
- **Cost:** $179-474/year
- **User Experience:** ✅ Shows your company name, no warnings after 2-4 weeks
- **Best For:** Public distribution
- **Providers:** Sectigo, DigiCert, SSL.com, GlobalSign
- **Time:** 1-7 days for certificate issuance

---

## Step-by-Step: Self-Signed Certificate (For Testing)

### 1. Create the Certificate

```powershell
# Run PowerShell as Administrator
.\Create-SelfSignedCert.ps1
```

This creates:
- `ATWG-CodeSigning.pfx` - Certificate with private key
- `ATWG-CodeSigning.cer` - Public certificate
- `certificate-info.txt` - Certificate details
- Password: `DevCert123!` (default)

### 2. Update Inno Setup Script

Edit `WallpaperChanger-Signed.iss` and uncomment Option 3:

```ini
; Option 3: Sign using PFX file (for development/testing)
SignTool=signtool sign /f "C:\path\to\ATWG-CodeSigning.pfx" /p DevCert123! /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 /v $f
```

Replace `C:\path\to\` with the actual path to your PFX file.

### 3. Build the Installer

```powershell
# Build the application
dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -o publish

# Compile the signed installer
iscc WallpaperChanger-Signed.iss
```

### 4. Verify the Signature

```powershell
# Check if installer is signed
Get-AuthenticodeSignature "installer\output\InnoSetup\WallpaperChanger-Setup-v1.2.0.exe" | Format-List

# Expected output:
# Status: Valid (on your PC only)
# SignerCertificate: CN=ATWG
```

---

## Step-by-Step: Commercial Certificate (For Production)

### 1. Purchase Certificate

**Recommended Providers:**
- **Sectigo** ($179/year) - Budget-friendly, good for small projects
  - https://sectigo.com/ssl-certificates-tls/code-signing
- **DigiCert** ($474/year) - Industry leader, fastest reputation building
  - https://www.digicert.com/signing/code-signing-certificates
- **SSL.com** ($199/year) - Good balance of price and features
  - https://www.ssl.com/certificates/code-signing/

**What You'll Need:**
- Business documents (incorporation papers, tax ID)
- Government-issued ID
- Processing time: 1-7 business days

### 2. Install Certificate

You'll receive either:

**A. USB Token (EV Certificate)** - Most trusted
- Plug in USB token
- Windows automatically recognizes it
- Use for signing immediately

**B. PFX File (Standard Certificate)**
```powershell
# Double-click the PFX file and follow wizard
# Or use command line:
certutil -user -p "PASSWORD" -importPFX "certificate.pfx"
```

### 3. Configure Inno Setup

Edit `WallpaperChanger-Signed.iss` and uncomment Option 1:

```ini
; Option 1: Sign using certificate from Windows Certificate Store (by subject name)
SignTool=signtool sign /n "Your Company Name" /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 /v $f
```

Replace `"Your Company Name"` with the exact subject name from your certificate.

### 4. Build and Distribute

```powershell
# Build the signed installer
iscc WallpaperChanger-Signed.iss

# Installer is now professionally signed!
# Located at: installer\output\InnoSetup\WallpaperChanger-Setup-v1.2.0.exe
```

### 5. Wait for Reputation to Build

- **Week 1:** May still see SmartScreen warnings
- **Week 2-4:** Warnings become less frequent
- **Month 2+:** Most users won't see warnings

**Tips to build reputation faster:**
- Consistent downloads (10-100+ per day)
- No malware reports
- Always use the same certificate
- Submit to Microsoft SmartScreen: https://www.microsoft.com/en-us/wdsi/filesubmission

---

## Verifying Your Signed Installer

### Method 1: Windows Properties
1. Right-click `WallpaperChanger-Setup-v1.2.0.exe`
2. Select **Properties**
3. Go to **Digital Signatures** tab
4. Should show your signature with "This digital signature is OK"

### Method 2: PowerShell
```powershell
Get-AuthenticodeSignature "installer\output\InnoSetup\WallpaperChanger-Setup-v1.2.0.exe" | Format-List
```

**Expected Output (Commercial Cert):**
```
SignerCertificate : [Subject] CN=Your Company Name
Status            : Valid
StatusMessage     : Signature verified.
```

**Expected Output (Self-Signed):**
```
SignerCertificate : [Subject] CN=ATWG
Status            : Valid (on your PC only, NotTrusted on others)
```

---

## Files Reference

| File | Purpose |
|------|---------|
| `CODE_SIGNING_GUIDE.md` | Comprehensive guide with all options |
| `WallpaperChanger-Signed.iss` | Inno Setup script with signing support |
| `Create-SelfSignedCert.ps1` | PowerShell script to create test certificate |
| `SMARTSCREEN_FIX.md` | This quick reference guide |

---

## Cost Comparison

| Option | Annual Cost | Setup Time | Removes Warning? |
|--------|------------|------------|------------------|
| None | $0 | 0 min | ❌ No |
| Self-Signed | $0 | 5 min | ❌ No (shows on other PCs) |
| Standard Cert | $179-300 | 1-7 days | ⚠️ After 2-4 weeks |
| EV Certificate | $300-600 | 1-7 days | ✅ Immediately |

---

## Troubleshooting

### "signtool.exe not found"

Download Windows SDK: https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/

Or find existing installation:
```powershell
Get-ChildItem "C:\Program Files (x86)\Windows Kits\" -Recurse -Filter "signtool.exe"
```

### "No certificates were found"

List installed certificates:
```powershell
Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert
```

### Still seeing SmartScreen after signing

1. **Verify signature is valid:**
   ```powershell
   Get-AuthenticodeSignature "installer.exe" | Format-List
   ```

2. **Check certificate is from trusted CA** (not self-signed)

3. **Wait for reputation to build** (2-4 weeks)

4. **Submit to Microsoft SmartScreen:**
   https://www.microsoft.com/en-us/wdsi/filesubmission

---

## Recommended Approach

**For Open Source / Personal Projects:**
1. ✅ Start with self-signed for testing
2. ✅ Get **Sectigo Standard Certificate** ($179/year) when ready to distribute
3. ⏱️ Wait 2-4 weeks for reputation

**For Commercial / Professional:**
1. ✅ Get **EV Certificate** ($300-600/year)
2. ✅ Immediate trust without waiting
3. ✅ Professional appearance

---

## Need Help?

- 📖 **Detailed Guide:** See [CODE_SIGNING_GUIDE.md](CODE_SIGNING_GUIDE.md)
- 🐛 **Issues:** https://github.com/asifthewebguy/wallpaper0-changer/issues
- 📧 **Contact:** Create an issue on GitHub

---

**Remember:** Code signing doesn't just remove warnings - it also:
- ✅ Proves authenticity (installer hasn't been tampered with)
- ✅ Builds user trust
- ✅ Professional appearance
- ✅ Required for many enterprise environments
