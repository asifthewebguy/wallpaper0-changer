import ctypes
import os
import logging
from enum import Enum, auto

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class WallpaperStyle(Enum):
    """Enum for wallpaper styles."""
    FILL = 10
    FIT = 6
    STRETCH = 2
    TILE = 1
    CENTER = 0
    SPAN = 22  # For multiple monitors

class WallpaperManager:
    """Class to manage wallpaper settings on Windows."""
    
    # Windows API constants
    SPI_SETDESKWALLPAPER = 0x0014
    SPIF_UPDATEINIFILE = 0x01
    SPIF_SENDCHANGE = 0x02
    
    def __init__(self):
        """Initialize the wallpaper manager."""
        self.user32 = ctypes.windll.user32
        self.systemParametersInfo = self.user32.SystemParametersInfoW
    
    def set_wallpaper(self, image_path: str, style: WallpaperStyle = WallpaperStyle.FILL) -> bool:
        """
        Set the desktop wallpaper.
        
        Args:
            image_path (str): Path to the image file
            style (WallpaperStyle): Wallpaper style (fill, fit, stretch, etc.)
            
        Returns:
            bool: True if successful, False otherwise
        """
        if not os.path.exists(image_path):
            logger.error(f"Image file not found: {image_path}")
            return False
        
        # Get absolute path
        abs_path = os.path.abspath(image_path)
        
        try:
            # Set the wallpaper style in registry
            import winreg
            with winreg.OpenKey(winreg.HKEY_CURRENT_USER, "Control Panel\\Desktop", 0, winreg.KEY_SET_VALUE) as key:
                if style == WallpaperStyle.TILE:
                    winreg.SetValueEx(key, "TileWallpaper", 0, winreg.REG_SZ, "1")
                    winreg.SetValueEx(key, "WallpaperStyle", 0, winreg.REG_SZ, "0")
                else:
                    winreg.SetValueEx(key, "TileWallpaper", 0, winreg.REG_SZ, "0")
                    winreg.SetValueEx(key, "WallpaperStyle", 0, winreg.REG_SZ, str(style.value))
            
            # Set the wallpaper
            result = self.systemParametersInfo(
                self.SPI_SETDESKWALLPAPER, 
                0, 
                abs_path, 
                self.SPIF_UPDATEINIFILE | self.SPIF_SENDCHANGE
            )
            
            if result:
                logger.info(f"Wallpaper set successfully: {abs_path}")
                return True
            else:
                logger.error(f"Failed to set wallpaper: {abs_path}")
                return False
                
        except Exception as e:
            logger.error(f"Error setting wallpaper: {e}")
            return False
    
    def get_available_styles(self) -> list:
        """
        Get a list of available wallpaper styles.
        
        Returns:
            list: List of (name, WallpaperStyle) tuples
        """
        return [
            ("Fill", WallpaperStyle.FILL),
            ("Fit", WallpaperStyle.FIT),
            ("Stretch", WallpaperStyle.STRETCH),
            ("Tile", WallpaperStyle.TILE),
            ("Center", WallpaperStyle.CENTER),
            ("Span", WallpaperStyle.SPAN)
        ]
