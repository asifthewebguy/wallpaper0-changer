import requests
import json
import os
import io
from typing import List, Dict, Any, Optional, Tuple
import logging
from PIL import Image

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class WallpaperAPIClient:
    """Client for interacting with the wallpaper API."""

    BASE_URL = "https://aiwp.me/api"
    IMAGES_ENDPOINT = "/images.json"
    IMAGE_DETAILS_ENDPOINT = "/images/{id}.json"
    CACHE_DIR = "cache"

    # Thumbnail settings
    THUMBNAIL_MAX_WIDTH = 200
    THUMBNAIL_MAX_HEIGHT = 150
    THUMBNAIL_QUALITY = 85  # JPEG quality (0-100)

    def __init__(self, compress_existing_thumbnails=False):
        """
        Initialize the API client.

        Args:
            compress_existing_thumbnails (bool): Whether to compress existing thumbnails in the cache
        """
        # Create cache directory if it doesn't exist
        if not os.path.exists(self.CACHE_DIR):
            os.makedirs(self.CACHE_DIR)

        # Compress existing thumbnails if requested
        if compress_existing_thumbnails:
            self.compress_existing_thumbnails()

    def compress_existing_thumbnails(self):
        """Compress all existing thumbnails in the cache to reduce disk space."""
        try:
            # Get all thumbnail files
            thumbnail_files = [f for f in os.listdir(self.CACHE_DIR) if f.startswith("thumb_")]

            if not thumbnail_files:
                logger.info("No existing thumbnails found to compress")
                return

            logger.info(f"Compressing {len(thumbnail_files)} existing thumbnails...")

            # Process each thumbnail
            for i, filename in enumerate(thumbnail_files):
                file_path = os.path.join(self.CACHE_DIR, filename)

                try:
                    # Read the file
                    with open(file_path, 'rb') as f:
                        image_data = f.read()

                    # Skip small files (already compressed)
                    if len(image_data) < 100 * 1024:  # Skip files smaller than 100KB
                        continue

                    # Compress the image
                    compressed_data = self._compress_image(
                        image_data,
                        self.THUMBNAIL_MAX_WIDTH,
                        self.THUMBNAIL_MAX_HEIGHT,
                        self.THUMBNAIL_QUALITY
                    )

                    # Save the compressed image back to the same file
                    with open(file_path, 'wb') as f:
                        f.write(compressed_data)

                    # Log progress periodically
                    if (i + 1) % 10 == 0 or i == len(thumbnail_files) - 1:
                        logger.info(f"Compressed {i + 1}/{len(thumbnail_files)} thumbnails")

                except Exception as e:
                    logger.error(f"Error compressing thumbnail {filename}: {e}")
                    continue

            logger.info("Finished compressing existing thumbnails")

        except Exception as e:
            logger.error(f"Error during thumbnail compression: {e}")

    def get_all_image_ids(self) -> List[str]:
        """
        Fetch all available image IDs from the API.

        Returns:
            List[str]: List of image IDs
        """
        try:
            response = requests.get(f"{self.BASE_URL}{self.IMAGES_ENDPOINT}")
            response.raise_for_status()
            return response.json()
        except requests.RequestException as e:
            logger.error(f"Error fetching image IDs: {e}")
            return []

    def get_image_details(self, image_id: str) -> Optional[Dict[str, Any]]:
        """
        Fetch details for a specific image by ID.

        Args:
            image_id (str): The ID of the image

        Returns:
            Optional[Dict[str, Any]]: Image details or None if not found
        """
        try:
            response = requests.get(f"{self.BASE_URL}{self.IMAGE_DETAILS_ENDPOINT.format(id=image_id)}")
            response.raise_for_status()
            return response.json()
        except requests.RequestException as e:
            logger.error(f"Error fetching image details for {image_id}: {e}")
            return None

    def download_image(self, image_details: Dict[str, Any]) -> Optional[str]:
        """
        Download an image and save it to the cache directory.

        Args:
            image_details (Dict[str, Any]): Image details from the API

        Returns:
            Optional[str]: Path to the downloaded image or None if download failed
        """
        image_id = image_details.get("id")
        image_url = image_details.get("path")

        if not image_id or not image_url:
            logger.error(f"Invalid image details: {image_details}")
            return None

        # Check if image is already in cache
        cache_path = os.path.join(self.CACHE_DIR, image_id)
        if os.path.exists(cache_path):
            logger.info(f"Image {image_id} found in cache")
            return cache_path

        # Download the image
        try:
            response = requests.get(image_url, stream=True)
            response.raise_for_status()

            with open(cache_path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)

            logger.info(f"Downloaded image {image_id} to {cache_path}")
            return cache_path
        except requests.RequestException as e:
            logger.error(f"Error downloading image {image_id}: {e}")
            return None

    def _compress_image(self, image_data: bytes, max_width: int, max_height: int, quality: int) -> bytes:
        """
        Compress and resize an image.

        Args:
            image_data (bytes): Raw image data
            max_width (int): Maximum width for the resized image
            max_height (int): Maximum height for the resized image
            quality (int): JPEG quality (0-100)

        Returns:
            bytes: Compressed image data
        """
        try:
            # Open the image from bytes
            img = Image.open(io.BytesIO(image_data))

            # Convert to RGB if needed (for PNG with transparency or palette mode)
            if img.mode in ('RGBA', 'LA'):
                background = Image.new('RGB', img.size, (255, 255, 255))
                background.paste(img, mask=img.split()[3] if img.mode == 'RGBA' else None)
                img = background
            elif img.mode == 'P':
                img = img.convert('RGB')
            elif img.mode != 'RGB':
                img = img.convert('RGB')

            # Resize the image while maintaining aspect ratio
            img.thumbnail((max_width, max_height))

            # Save to bytes with compression
            output = io.BytesIO()
            img.save(output, format='JPEG', quality=quality, optimize=True)

            return output.getvalue()
        except Exception as e:
            logger.error(f"Error compressing image: {e}")
            return image_data  # Return original data if compression fails

    def download_thumbnail(self, image_details: Dict[str, Any]) -> Optional[str]:
        """
        Download a thumbnail, compress it, and save it to the cache directory.

        Args:
            image_details (Dict[str, Any]): Image details from the API

        Returns:
            Optional[str]: Path to the downloaded thumbnail or None if download failed
        """
        image_id = image_details.get("id")
        thumbnail_url = image_details.get("thumbnailUrl")

        if not image_id or not thumbnail_url:
            logger.error(f"Invalid image details for thumbnail: {image_details}")
            return None

        # Check if thumbnail is already in cache
        cache_path = os.path.join(self.CACHE_DIR, f"thumb_{image_id}")
        if os.path.exists(cache_path):
            logger.info(f"Thumbnail for {image_id} found in cache")
            return cache_path

        # Download the thumbnail
        try:
            response = requests.get(thumbnail_url)
            response.raise_for_status()

            # Get the image data
            image_data = response.content

            # Compress the image
            compressed_data = self._compress_image(
                image_data,
                self.THUMBNAIL_MAX_WIDTH,
                self.THUMBNAIL_MAX_HEIGHT,
                self.THUMBNAIL_QUALITY
            )

            # Save the compressed image
            with open(cache_path, 'wb') as f:
                f.write(compressed_data)

            logger.info(f"Downloaded and compressed thumbnail for {image_id} to {cache_path}")
            return cache_path
        except requests.RequestException as e:
            logger.error(f"Error downloading thumbnail for {image_id}: {e}")
            return None
        except Exception as e:
            logger.error(f"Error processing thumbnail for {image_id}: {e}")
            return None
