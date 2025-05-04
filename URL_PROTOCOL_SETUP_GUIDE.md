# Wallpaper Changer URL Protocol Setup Guide

This guide will help you set up the URL protocol for the Wallpaper Changer application, allowing you to change wallpapers directly from links.

## Method 1: Using the Registry File (Recommended)

1. **Right-click** on the `wallpaper_protocol.reg` file and select **Run as administrator**
2. Click **Yes** when prompted to add the information to the registry
3. You should see a confirmation message that the keys have been added to the registry

## Method 2: Using PowerShell Script

1. **Right-click** on the `run_protocol_register.bat` file and select **Run as administrator**
2. The script will register the URL protocol and create a test HTML file

## Testing the URL Protocol

After registering the URL protocol using one of the methods above, you can test it in several ways:

1. **Run the test batch file:**
   - Double-click on `test_protocol.bat` to test the direct command functionality

2. **Open the test HTML file:**
   - Open `test_protocol.html` in your web browser
   - Click on one of the test links to see if the wallpaper changes

3. **Create a custom URL:**
   - Create a shortcut with the URL `wallpaper0-changer:005TN27O78.png`
   - Double-click the shortcut to test

## Troubleshooting

If the URL protocol doesn't work:

1. **Check if the registry entries were created:**
   - Open Registry Editor (run `regedit` from the Start menu)
   - Navigate to `HKEY_CLASSES_ROOT\wallpaper0-changer`
   - Verify that the keys and values exist

2. **Check the log files:**
   - Look at `wallpaper_changer.log`, `url_protocol.log`, and `main_url_protocol.log` for error messages

3. **Try running the application directly with the URL parameter:**
   - Open Command Prompt
   - Navigate to the application directory
   - Run: `python main.py "wallpaper0-changer:005TN27O78.png"`

4. **Verify Python is in your PATH:**
   - The URL protocol relies on being able to run Python from any location
   - Make sure Python is properly installed and added to your system PATH

## Notes

- The URL protocol must be registered with administrator privileges
- The registry entries point to the specific location of your application
- If you move the application, you'll need to re-register the URL protocol
- The URL protocol format is: `wallpaper0-changer:IMAGE_ID.jpg`
