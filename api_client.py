import requests
import json
import os
from typing import List, Dict, Any, Optional, Tuple
import logging

from image_cache_manager import ImageCacheManager

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class WallpaperAPIClient:
    """Client for interacting with the wallpaper API."""

    BASE_URL = "https://aiwp.me/api"
    IMAGES_ENDPOINT = "/images.json"
    IMAGE_DETAILS_ENDPOINT = "/images/{id}.json"
    CACHE_DIR = "cache"

    def __init__(self, compress_existing_thumbnails=False, max_cache_size_mb=500):
        """
        Initialize the API client.

        Args:
            compress_existing_thumbnails (bool): Whether to compress existing thumbnails in the cache
            max_cache_size_mb (int): Maximum cache size in MB
        """
        # Initialize the image cache manager
        self.cache_manager = ImageCacheManager(
            cache_dir=self.CACHE_DIR,
            max_cache_size_mb=max_cache_size_mb
        )

        # Compress existing thumbnails if requested
        if compress_existing_thumbnails:
            self.compress_existing_thumbnails()

    def compress_existing_thumbnails(self):
        """Compress all existing thumbnails in the cache to reduce disk space."""
        self.cache_manager.compress_existing_thumbnails()

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

        # Use the cache manager to get or download the image
        return self.cache_manager.download_image(image_id, image_url)

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

        # Use the cache manager to get or download the thumbnail
        return self.cache_manager.download_thumbnail(image_id, thumbnail_url)

    def get_cache_stats(self) -> Dict[str, Any]:
        """
        Get statistics about the cache.

        Returns:
            Dict[str, Any]: Cache statistics
        """
        return self.cache_manager.get_cache_stats()

    def clear_cache(self):
        """Clear all cached images and thumbnails."""
        self.cache_manager.clear_cache()

    def cleanup(self):
        """Perform cleanup operations before application exit."""
        self.cache_manager.cleanup()
