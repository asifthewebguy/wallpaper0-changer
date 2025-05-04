import sys
import logging
import tkinter as tk
from gui import WallpaperApp

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
