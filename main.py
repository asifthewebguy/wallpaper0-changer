import sys
import logging
import tkinter as tk
import re
from gui import WallpaperApp
from direct_wallpaper import process_url_command

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("wallpaper_changer.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

def main():
    """Main entry point for the application."""
    try:
        logger.info("Starting Wallpaper Changer application")

        # Check if we have a URL protocol command
        if len(sys.argv) > 1:
            url_param = sys.argv[1]
            logger.info(f"Command line parameter detected: {url_param}")

            # Check if it's a URL protocol command
            if "wallpaper0-changer:" in url_param:
                logger.info(f"URL protocol command detected: {url_param}")

                # Process the URL command
                success = process_url_command(url_param)

                # Exit with appropriate code
                if success:
                    logger.info("URL command processed successfully")
                    return 0
                else:
                    logger.error("Failed to process URL command")
                    return 1
            else:
                logger.info(f"Not a valid URL protocol command: {url_param}")
                # Continue with normal startup

        # No URL command, start the GUI application
        logger.info("Starting GUI application")

        # Create and run the application
        app = WallpaperApp()

        # Set theme (if available)
        try:
            from ttkthemes import ThemedTk
            app = ThemedTk(theme="arc")
            app.title("Wallpaper Changer")
        except ImportError:
            logger.info("ttkthemes not available, using default theme")

        # Configure style for selected frames
        style = tk.ttk.Style()
        style.configure("Selected.TFrame", borderwidth=2, relief=tk.GROOVE, background="#4a6984")

        # Run the application
        app.mainloop()

        logger.info("Application closed")

    except Exception as e:
        logger.error(f"Unhandled exception: {e}", exc_info=True)
        return 1

    return 0

if __name__ == "__main__":
    sys.exit(main())
