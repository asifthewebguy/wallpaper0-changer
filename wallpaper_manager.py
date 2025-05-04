import ctypes
import os
import logging
import random
import threading
import time
import datetime
from enum import Enum, auto
from typing import List, Dict, Any, Optional, Callable

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

class ScheduleType(Enum):
    """Enum for wallpaper change schedule types."""
    HOURLY = "hourly"
    SPECIFIC_TIME = "specific_time"
    DISABLED = "disabled"

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

        # Random wallpaper scheduler
        self.scheduler_thread = None
        self.scheduler_running = False
        self.schedule_type = ScheduleType.DISABLED
        self.specific_time = "12:00"  # Default time
        self.available_images = []
        self.current_style = WallpaperStyle.FILL
        self.on_wallpaper_changed = None  # Callback function

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

    def set_available_images(self, image_paths: List[str]):
        """
        Set the list of available images for random selection.

        Args:
            image_paths (List[str]): List of paths to available images
        """
        self.available_images = [path for path in image_paths if os.path.exists(path)]
        logger.info(f"Set {len(self.available_images)} available images for random selection")

    def set_random_wallpaper_schedule(self, schedule_type: ScheduleType, specific_time: str = None, style: WallpaperStyle = None):
        """
        Set the schedule for random wallpaper changes.

        Args:
            schedule_type (ScheduleType): Type of schedule (hourly, specific time, disabled)
            specific_time (str, optional): Specific time in HH:MM format (24-hour). Required if schedule_type is SPECIFIC_TIME.
            style (WallpaperStyle, optional): Wallpaper style to use. If None, uses the current style.
        """
        # Stop any existing scheduler
        self.stop_scheduler()

        # Update settings
        self.schedule_type = schedule_type
        if specific_time and schedule_type == ScheduleType.SPECIFIC_TIME:
            self.specific_time = specific_time
        if style:
            self.current_style = style

        # Start scheduler if not disabled
        if schedule_type != ScheduleType.DISABLED:
            self.start_scheduler()

        logger.info(f"Set random wallpaper schedule: {schedule_type.value}, time: {self.specific_time if schedule_type == ScheduleType.SPECIFIC_TIME else 'N/A'}")

    def start_scheduler(self):
        """Start the wallpaper change scheduler."""
        if self.scheduler_running:
            return

        if not self.available_images:
            logger.warning("Cannot start scheduler: No available images")
            return

        self.scheduler_running = True
        self.scheduler_thread = threading.Thread(target=self._scheduler_loop, daemon=True)
        self.scheduler_thread.start()
        logger.info("Wallpaper scheduler started")

    def stop_scheduler(self):
        """Stop the wallpaper change scheduler."""
        self.scheduler_running = False
        if self.scheduler_thread and self.scheduler_thread.is_alive():
            self.scheduler_thread.join(1.0)  # Wait for thread to finish
        logger.info("Wallpaper scheduler stopped")

    def _scheduler_loop(self):
        """Background thread for scheduling wallpaper changes."""
        last_hour = -1

        while self.scheduler_running:
            try:
                now = datetime.datetime.now()

                if self.schedule_type == ScheduleType.HOURLY:
                    # Change wallpaper at the start of each hour
                    current_hour = now.hour
                    if current_hour != last_hour:
                        self._set_random_wallpaper()
                        last_hour = current_hour

                elif self.schedule_type == ScheduleType.SPECIFIC_TIME:
                    # Change wallpaper at the specific time
                    try:
                        hour, minute = map(int, self.specific_time.split(':'))
                        if now.hour == hour and now.minute == minute and now.second < 60:
                            self._set_random_wallpaper()
                    except ValueError:
                        logger.error(f"Invalid time format: {self.specific_time}")

                # Sleep for a short time to avoid high CPU usage
                time.sleep(30)  # Check every 30 seconds

            except Exception as e:
                logger.error(f"Error in scheduler loop: {e}")
                time.sleep(60)  # Wait a bit longer if there was an error

    def _set_random_wallpaper(self):
        """Set a random wallpaper from the available images."""
        if not self.available_images:
            logger.warning("No available images for random wallpaper")
            return

        # Select a random image
        image_path = random.choice(self.available_images)

        # Set as wallpaper
        success = self.set_wallpaper(image_path, self.current_style)

        if success and self.on_wallpaper_changed:
            # Call the callback function if set
            try:
                self.on_wallpaper_changed(image_path)
            except Exception as e:
                logger.error(f"Error in wallpaper changed callback: {e}")

        return success
