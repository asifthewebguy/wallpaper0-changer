import requests
import json
import os
from typing import List, Dict, Any, Optional
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class WallpaperAPIClient:
    """Client for interacting with the wallpaper API."""
    
    BASE_URL = "https://aiwp.me/api"
    IMAGES_ENDPOINT = "/images.json"
    IMAGE_DETAILS_ENDPOINT = "/images/{id}.json"
    CACHE_DIR = "cache"
    
    def __init__(self):
        """Initialize the API client."""
        # Create cache directory if it doesn't exist
        if not os.path.exists(self.CACHE_DIR):
            os.makedirs(self.CACHE_DIR)
            
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
    
    def download_thumbnail(self, image_details: Dict[str, Any]) -> Optional[str]:
        """
        Download a thumbnail and save it to the cache directory.
        
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
            response = requests.get(thumbnail_url, stream=True)
            response.raise_for_status()
            
            with open(cache_path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)
            
            logger.info(f"Downloaded thumbnail for {image_id} to {cache_path}")
            return cache_path
        except requests.RequestException as e:
            logger.error(f"Error downloading thumbnail for {image_id}: {e}")
            return None
