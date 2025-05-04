import logging
import re
import sys
import os
import traceback
import datetime
from api_client import WallpaperAPIClient
from wallpaper_manager import WallpaperManager, WallpaperStyle

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

def extract_image_id_from_url(url):
    """
    Extract the image ID from a URL protocol string.

    Args:
        url (str): URL in the format 'wallpaper0-changer:IMAGE_ID.jpg'

    Returns:
        str: Image ID or None if not found
    """
    if not url:
        return None

    logger.info(f"Original URL: {url}")

    # Remove protocol prefix
    if "wallpaper0-changer:" in url:
        # Find the position of the protocol
        protocol_pos = url.find("wallpaper0-changer:")
        # Extract everything after the protocol
        url = url[protocol_pos + len("wallpaper0-changer:"):]

    # Clean up any remaining special characters
    image_id = url.strip()

    # Remove any URL encoding or extra characters
    image_id = image_id.replace("%20", " ")
    image_id = re.sub(r'["\']', '', image_id)

    logger.info(f"Cleaned URL: {image_id}")

    # If there's no file extension, try to add .jpg as a default
    if not re.search(r'\.(jpg|png|jpeg)$', image_id, re.IGNORECASE):
        image_id += ".jpg"
        logger.info(f"Added extension: {image_id}")

    return image_id if image_id else None

def set_wallpaper_by_id(image_id, style_name="Fill"):
    """
    Set wallpaper directly by image ID.

    Args:
        image_id (str): Image ID to set as wallpaper
        style_name (str): Wallpaper style name (Fill, Fit, Stretch, etc.)

    Returns:
        bool: True if successful, False otherwise
    """
    try:
        logger.info(f"Setting wallpaper directly with ID: {image_id}, Style: {style_name}")

        # Initialize API client and wallpaper manager
        api_client = WallpaperAPIClient()
        wallpaper_manager = WallpaperManager()

        # Get image details
        image_details = api_client.get_image_details(image_id)
        if not image_details:
            logger.error(f"Failed to get image details for ID: {image_id}")
            return False

        # Download the full image
        image_path = api_client.download_image(image_details)
        if not image_path:
            logger.error(f"Failed to download image for ID: {image_id}")
            return False

        # Get the wallpaper style
        available_styles = wallpaper_manager.get_available_styles()
        style = next((s for n, s in available_styles if n == style_name), WallpaperStyle.FILL)

        # Set as wallpaper
        success = wallpaper_manager.set_wallpaper(image_path, style)

        if success:
            logger.info(f"Wallpaper set successfully: {image_id}")
        else:
            logger.error(f"Failed to set wallpaper: {image_id}")

        return success

    except Exception as e:
        logger.error(f"Error setting wallpaper by ID: {e}", exc_info=True)
        return False

def process_url_command(url):
    """
    Process a URL protocol command.

    Args:
        url (str): URL protocol string

    Returns:
        bool: True if successful, False otherwise
    """
    try:
        # Create a log file specifically for URL protocol debugging
        with open("url_protocol.log", "a") as log_file:
            log_file.write(f"{'-'*50}\n")
            log_file.write(f"Timestamp: {datetime.datetime.now()}\n")
            log_file.write(f"Processing URL command: {url}\n")

        # Log the URL being processed
        logger.info(f"Processing URL command: {url}")

        # Extract image ID from URL
        image_id = extract_image_id_from_url(url)
        if not image_id:
            logger.error(f"Invalid URL format: {url}")
            with open("url_protocol.log", "a") as log_file:
                log_file.write(f"Invalid URL format: {url}\n")
            return False

        logger.info(f"Extracted image ID: {image_id}")
        with open("url_protocol.log", "a") as log_file:
            log_file.write(f"Extracted image ID: {image_id}\n")

        # Set the wallpaper
        success = set_wallpaper_by_id(image_id)

        if success:
            logger.info(f"Successfully set wallpaper from URL command: {url}")
            with open("url_protocol.log", "a") as log_file:
                log_file.write(f"Successfully set wallpaper with ID: {image_id}\n")
        else:
            logger.error(f"Failed to set wallpaper from URL command: {url}")
            with open("url_protocol.log", "a") as log_file:
                log_file.write(f"Failed to set wallpaper with ID: {image_id}\n")

        return success

    except Exception as e:
        # Get detailed error information
        error_details = traceback.format_exc()
        logger.error(f"Error processing URL command: {url}")
        logger.error(f"Exception: {str(e)}")
        logger.error(f"Traceback: {error_details}")

        # Write to the URL protocol log file
        with open("url_protocol.log", "a") as log_file:
            log_file.write(f"Error processing URL command: {url}\n")
            log_file.write(f"Exception: {str(e)}\n")
            log_file.write(f"Traceback: {error_details}\n")

        return False
