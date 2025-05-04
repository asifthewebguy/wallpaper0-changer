import os
import io
import json
import time
import shutil
import logging
from typing import Dict, List, Optional, Tuple, Any
from PIL import Image
import requests
from collections import OrderedDict
from datetime import datetime

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class ImageCacheManager:
    """
    Manages image caching, compression, and retrieval with advanced features like:
    - LRU (Least Recently Used) cache eviction
    - Metadata tracking for cached images
    - Size limits and automatic cleanup
    - On-demand thumbnail generation
    """

    def __init__(
        self, 
        cache_dir: str = "cache",
        max_cache_size_mb: int = 500,  # 500MB default max cache size
        thumbnail_max_width: int = 200,
        thumbnail_max_height: int = 150,
        thumbnail_quality: int = 85,
        metadata_file: str = "cache_metadata.json"
    ):
        """
        Initialize the image cache manager.

        Args:
            cache_dir (str): Directory to store cached images
            max_cache_size_mb (int): Maximum cache size in MB
            thumbnail_max_width (int): Maximum width for thumbnails
            thumbnail_max_height (int): Maximum height for thumbnails
            thumbnail_quality (int): JPEG quality for thumbnails (0-100)
            metadata_file (str): File to store cache metadata
        """
        self.cache_dir = cache_dir
        self.max_cache_size_bytes = max_cache_size_mb * 1024 * 1024
        self.thumbnail_max_width = thumbnail_max_width
        self.thumbnail_max_height = thumbnail_max_height
        self.thumbnail_quality = thumbnail_quality
        self.metadata_file = os.path.join(cache_dir, metadata_file)
        
        # Cache metadata: {filename: {size, created, last_accessed, type}}
        self.metadata = {}
        
        # LRU tracking for cache eviction
        self.lru_cache = OrderedDict()
        
        # Create cache directory if it doesn't exist
        if not os.path.exists(self.cache_dir):
            os.makedirs(self.cache_dir)
            
        # Load existing metadata if available
        self._load_metadata()
        
        # Validate cache on startup
        self._validate_cache()

    def _load_metadata(self):
        """Load cache metadata from file if it exists."""
        try:
            if os.path.exists(self.metadata_file):
                with open(self.metadata_file, 'r') as f:
                    self.metadata = json.load(f)
                logger.info(f"Loaded metadata for {len(self.metadata)} cached items")
                
                # Initialize LRU cache from metadata
                for filename, data in self.metadata.items():
                    self.lru_cache[filename] = data['last_accessed']
                
                # Sort LRU cache by last accessed time
                self.lru_cache = OrderedDict(
                    sorted(self.lru_cache.items(), key=lambda x: x[1])
                )
        except Exception as e:
            logger.error(f"Error loading cache metadata: {e}")
            self.metadata = {}
            self.lru_cache = OrderedDict()

    def _save_metadata(self):
        """Save cache metadata to file."""
        try:
            with open(self.metadata_file, 'w') as f:
                json.dump(self.metadata, f)
            logger.debug("Cache metadata saved")
        except Exception as e:
            logger.error(f"Error saving cache metadata: {e}")

    def _validate_cache(self):
        """
        Validate cache contents against metadata and update metadata.
        Remove any files not in metadata and any metadata entries without files.
        """
        try:
            # Get all files in cache directory
            cache_files = set(os.listdir(self.cache_dir))
            
            # Remove metadata file from the set
            if os.path.basename(self.metadata_file) in cache_files:
                cache_files.remove(os.path.basename(self.metadata_file))
            
            # Get all files in metadata
            metadata_files = set(self.metadata.keys())
            
            # Files in cache but not in metadata
            orphaned_files = cache_files - metadata_files
            for filename in orphaned_files:
                if filename != os.path.basename(self.metadata_file):
                    file_path = os.path.join(self.cache_dir, filename)
                    # Add to metadata if it's an image file
                    if self._is_image_file(filename):
                        file_size = os.path.getsize(file_path)
                        self.metadata[filename] = {
                            'size': file_size,
                            'created': datetime.now().isoformat(),
                            'last_accessed': datetime.now().isoformat(),
                            'type': 'image' if not filename.startswith('thumb_') else 'thumbnail'
                        }
                        self.lru_cache[filename] = datetime.now().isoformat()
                    else:
                        # Remove non-image files
                        os.remove(file_path)
                        logger.info(f"Removed non-image file from cache: {filename}")
            
            # Files in metadata but not in cache
            missing_files = metadata_files - cache_files
            for filename in missing_files:
                del self.metadata[filename]
                if filename in self.lru_cache:
                    del self.lru_cache[filename]
                logger.info(f"Removed missing file from metadata: {filename}")
            
            # Check cache size and enforce limit
            self._enforce_cache_size_limit()
            
            # Save updated metadata
            self._save_metadata()
            
            logger.info(f"Cache validation complete. {len(self.metadata)} valid items in cache.")
        except Exception as e:
            logger.error(f"Error validating cache: {e}")

    def _is_image_file(self, filename: str) -> bool:
        """Check if a file is an image based on extension."""
        image_extensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp']
        _, ext = os.path.splitext(filename.lower())
        return ext in image_extensions

    def _enforce_cache_size_limit(self):
        """
        Enforce the cache size limit by removing least recently used items.
        """
        try:
            # Calculate current cache size
            current_size = sum(data['size'] for data in self.metadata.values())
            
            # If we're under the limit, no need to remove anything
            if current_size <= self.max_cache_size_bytes:
                return
            
            logger.info(f"Cache size ({current_size/1024/1024:.2f}MB) exceeds limit ({self.max_cache_size_bytes/1024/1024:.2f}MB). Cleaning up...")
            
            # Remove items until we're under the limit
            bytes_to_remove = current_size - self.max_cache_size_bytes
            bytes_removed = 0
            
            # Get items sorted by last accessed time (oldest first)
            for filename in list(self.lru_cache.keys()):
                if bytes_removed >= bytes_to_remove:
                    break
                
                # Skip the metadata file
                if filename == os.path.basename(self.metadata_file):
                    continue
                
                file_path = os.path.join(self.cache_dir, filename)
                if os.path.exists(file_path):
                    file_size = self.metadata[filename]['size']
                    os.remove(file_path)
                    bytes_removed += file_size
                    
                    # Remove from metadata and LRU cache
                    del self.metadata[filename]
                    del self.lru_cache[filename]
                    
                    logger.info(f"Removed {filename} from cache ({file_size/1024:.2f}KB)")
            
            logger.info(f"Cache cleanup complete. Removed {bytes_removed/1024/1024:.2f}MB.")
        except Exception as e:
            logger.error(f"Error enforcing cache size limit: {e}")

    def get_image_path(self, image_id: str) -> Optional[str]:
        """
        Get the path to a cached image.
        
        Args:
            image_id (str): Image ID
            
        Returns:
            Optional[str]: Path to the cached image or None if not found
        """
        cache_path = os.path.join(self.cache_dir, image_id)
        if os.path.exists(cache_path):
            # Update last accessed time
            self._update_access_time(image_id)
            return cache_path
        return None

    def get_thumbnail_path(self, image_id: str) -> Optional[str]:
        """
        Get the path to a cached thumbnail.
        
        Args:
            image_id (str): Image ID
            
        Returns:
            Optional[str]: Path to the cached thumbnail or None if not found
        """
        cache_path = os.path.join(self.cache_dir, f"thumb_{image_id}")
        if os.path.exists(cache_path):
            # Update last accessed time
            self._update_access_time(f"thumb_{image_id}")
            return cache_path
        return None

    def _update_access_time(self, filename: str):
        """
        Update the last accessed time for a cached item.
        
        Args:
            filename (str): Filename in the cache
        """
        try:
            if filename in self.metadata:
                now = datetime.now().isoformat()
                self.metadata[filename]['last_accessed'] = now
                
                # Update LRU cache
                if filename in self.lru_cache:
                    del self.lru_cache[filename]
                self.lru_cache[filename] = now
                
                # Save metadata periodically (not on every access to reduce disk I/O)
                # This is a simple approach - could be improved with a timer
                if len(self.lru_cache) % 10 == 0:
                    self._save_metadata()
        except Exception as e:
            logger.error(f"Error updating access time for {filename}: {e}")

    def download_image(self, image_id: str, image_url: str) -> Optional[str]:
        """
        Download an image and save it to the cache.
        
        Args:
            image_id (str): Image ID
            image_url (str): URL to download the image from
            
        Returns:
            Optional[str]: Path to the cached image or None if download failed
        """
        # Check if image is already in cache
        cache_path = self.get_image_path(image_id)
        if cache_path:
            return cache_path
            
        # Download the image
        try:
            response = requests.get(image_url, stream=True)
            response.raise_for_status()
            
            cache_path = os.path.join(self.cache_dir, image_id)
            
            with open(cache_path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)
                    
            # Add to metadata
            file_size = os.path.getsize(cache_path)
            now = datetime.now().isoformat()
            self.metadata[image_id] = {
                'size': file_size,
                'created': now,
                'last_accessed': now,
                'type': 'image'
            }
            
            # Update LRU cache
            self.lru_cache[image_id] = now
            
            # Save metadata
            self._save_metadata()
            
            # Check cache size and enforce limit
            self._enforce_cache_size_limit()
            
            logger.info(f"Downloaded image {image_id} to {cache_path}")
            return cache_path
        except Exception as e:
            logger.error(f"Error downloading image {image_id}: {e}")
            return None

    def download_thumbnail(self, image_id: str, thumbnail_url: str) -> Optional[str]:
        """
        Download a thumbnail, compress it, and save it to the cache.
        
        Args:
            image_id (str): Image ID
            thumbnail_url (str): URL to download the thumbnail from
            
        Returns:
            Optional[str]: Path to the cached thumbnail or None if download failed
        """
        # Check if thumbnail is already in cache
        thumbnail_id = f"thumb_{image_id}"
        cache_path = self.get_thumbnail_path(image_id)
        if cache_path:
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
                self.thumbnail_max_width,
                self.thumbnail_max_height,
                self.thumbnail_quality
            )
            
            # Save the compressed image
            cache_path = os.path.join(self.cache_dir, thumbnail_id)
            with open(cache_path, 'wb') as f:
                f.write(compressed_data)
                
            # Add to metadata
            file_size = os.path.getsize(cache_path)
            now = datetime.now().isoformat()
            self.metadata[thumbnail_id] = {
                'size': file_size,
                'created': now,
                'last_accessed': now,
                'type': 'thumbnail'
            }
            
            # Update LRU cache
            self.lru_cache[thumbnail_id] = now
            
            # Save metadata
            self._save_metadata()
            
            # Check cache size and enforce limit
            self._enforce_cache_size_limit()
            
            logger.info(f"Downloaded and compressed thumbnail for {image_id} to {cache_path}")
            return cache_path
        except Exception as e:
            logger.error(f"Error downloading thumbnail for {image_id}: {e}")
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

    def compress_existing_thumbnails(self):
        """Compress all existing thumbnails in the cache to reduce disk space."""
        try:
            # Get all thumbnail files
            thumbnail_files = [f for f in os.listdir(self.cache_dir) if f.startswith("thumb_")]
            
            if not thumbnail_files:
                logger.info("No existing thumbnails found to compress")
                return
                
            logger.info(f"Compressing {len(thumbnail_files)} existing thumbnails...")
            
            # Process each thumbnail
            for i, filename in enumerate(thumbnail_files):
                file_path = os.path.join(self.cache_dir, filename)
                
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
                        self.thumbnail_max_width,
                        self.thumbnail_max_height,
                        self.thumbnail_quality
                    )
                    
                    # Save the compressed image back to the same file
                    with open(file_path, 'wb') as f:
                        f.write(compressed_data)
                        
                    # Update metadata
                    if filename in self.metadata:
                        self.metadata[filename]['size'] = len(compressed_data)
                        
                    # Log progress periodically
                    if (i + 1) % 10 == 0 or i == len(thumbnail_files) - 1:
                        logger.info(f"Compressed {i + 1}/{len(thumbnail_files)} thumbnails")
                        
                except Exception as e:
                    logger.error(f"Error compressing thumbnail {filename}: {e}")
                    continue
                    
            # Save updated metadata
            self._save_metadata()
            
            logger.info("Finished compressing existing thumbnails")
            
        except Exception as e:
            logger.error(f"Error during thumbnail compression: {e}")

    def clear_cache(self):
        """Clear all cached images and thumbnails."""
        try:
            # Get all files in cache directory
            cache_files = [f for f in os.listdir(self.cache_dir) 
                          if f != os.path.basename(self.metadata_file)]
            
            for filename in cache_files:
                file_path = os.path.join(self.cache_dir, filename)
                if os.path.isfile(file_path):
                    os.remove(file_path)
            
            # Reset metadata and LRU cache
            self.metadata = {}
            self.lru_cache = OrderedDict()
            
            # Save empty metadata
            self._save_metadata()
            
            logger.info("Cache cleared successfully")
        except Exception as e:
            logger.error(f"Error clearing cache: {e}")

    def get_cache_stats(self) -> Dict[str, Any]:
        """
        Get statistics about the cache.
        
        Returns:
            Dict[str, Any]: Cache statistics
        """
        try:
            total_size = sum(data['size'] for data in self.metadata.values())
            image_count = sum(1 for k, v in self.metadata.items() if v['type'] == 'image')
            thumbnail_count = sum(1 for k, v in self.metadata.items() if v['type'] == 'thumbnail')
            
            return {
                'total_size_bytes': total_size,
                'total_size_mb': total_size / (1024 * 1024),
                'image_count': image_count,
                'thumbnail_count': thumbnail_count,
                'total_items': len(self.metadata),
                'max_size_mb': self.max_cache_size_bytes / (1024 * 1024)
            }
        except Exception as e:
            logger.error(f"Error getting cache stats: {e}")
            return {}

    def cleanup(self):
        """Perform cleanup operations before application exit."""
        try:
            # Save metadata
            self._save_metadata()
            logger.info("Cache cleanup completed")
        except Exception as e:
            logger.error(f"Error during cache cleanup: {e}")
