import tkinter as tk
from tkinter import ttk, messagebox
import threading
import os
import logging
from typing import Dict, List, Any, Optional
from PIL import Image, ImageTk

from api_client import WallpaperAPIClient
from wallpaper_manager import WallpaperManager, WallpaperStyle

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class WallpaperApp(tk.Tk):
    """Main application window for the wallpaper changer."""
    
    def __init__(self):
        """Initialize the application."""
        super().__init__()
        
        self.title("Wallpaper Changer")
        self.geometry("900x600")
        self.minsize(800, 500)
        
        # Initialize API client and wallpaper manager
        self.api_client = WallpaperAPIClient()
        self.wallpaper_manager = WallpaperManager()
        
        # State variables
        self.image_ids = []
        self.image_details_cache = {}
        self.thumbnail_images = {}  # Keep references to prevent garbage collection
        self.selected_image_id = None
        self.loading = False
        
        # Create UI
        self.create_ui()
        
        # Load images
        self.load_images()
    
    def create_ui(self):
        """Create the user interface."""
        # Main frame
        main_frame = ttk.Frame(self)
        main_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Top controls
        controls_frame = ttk.Frame(main_frame)
        controls_frame.pack(fill=tk.X, pady=(0, 10))
        
        refresh_button = ttk.Button(controls_frame, text="Refresh", command=self.load_images)
        refresh_button.pack(side=tk.LEFT)
        
        # Style selection
        style_frame = ttk.LabelFrame(controls_frame, text="Wallpaper Style")
        style_frame.pack(side=tk.RIGHT)
        
        self.style_var = tk.StringVar(value="Fill")
        for name, _ in self.wallpaper_manager.get_available_styles():
            ttk.Radiobutton(style_frame, text=name, value=name, variable=self.style_var).pack(side=tk.LEFT, padx=5)
        
        # Create a frame for the canvas and scrollbar
        canvas_frame = ttk.Frame(main_frame)
        canvas_frame.pack(fill=tk.BOTH, expand=True)
        
        # Create canvas and scrollbar
        self.canvas = tk.Canvas(canvas_frame)
        scrollbar = ttk.Scrollbar(canvas_frame, orient=tk.VERTICAL, command=self.canvas.yview)
        self.canvas.configure(yscrollcommand=scrollbar.set)
        
        # Pack scrollbar and canvas
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        self.canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        
        # Create a frame inside the canvas to hold the images
        self.images_frame = ttk.Frame(self.canvas)
        self.canvas_frame_id = self.canvas.create_window((0, 0), window=self.images_frame, anchor=tk.NW)
        
        # Configure canvas scrolling
        self.images_frame.bind("<Configure>", self.on_frame_configure)
        self.canvas.bind("<Configure>", self.on_canvas_configure)
        
        # Status bar
        self.status_var = tk.StringVar(value="Ready")
        status_bar = ttk.Label(self, textvariable=self.status_var, relief=tk.SUNKEN, anchor=tk.W)
        status_bar.pack(side=tk.BOTTOM, fill=tk.X)
        
        # Apply button
        self.apply_button = ttk.Button(main_frame, text="Apply Selected Wallpaper", command=self.apply_wallpaper, state=tk.DISABLED)
        self.apply_button.pack(pady=10)
    
    def on_frame_configure(self, event):
        """Update the scrollregion when the frame size changes."""
        self.canvas.configure(scrollregion=self.canvas.bbox("all"))
    
    def on_canvas_configure(self, event):
        """Resize the canvas frame when the canvas size changes."""
        canvas_width = event.width
        self.canvas.itemconfig(self.canvas_frame_id, width=canvas_width)
    
    def load_images(self):
        """Load images from the API."""
        if self.loading:
            return
        
        self.loading = True
        self.status_var.set("Loading images...")
        self.apply_button.config(state=tk.DISABLED)
        
        # Clear existing images
        for widget in self.images_frame.winfo_children():
            widget.destroy()
        
        # Start loading in a separate thread
        threading.Thread(target=self._load_images_thread, daemon=True).start()
    
    def _load_images_thread(self):
        """Background thread for loading images."""
        try:
            # Get all image IDs
            self.image_ids = self.api_client.get_all_image_ids()
            
            if not self.image_ids:
                self.status_var.set("No images found")
                self.loading = False
                return
            
            # Create a grid of images
            self._create_image_grid()
            
            self.status_var.set(f"Loaded {len(self.image_ids)} images")
        except Exception as e:
            logger.error(f"Error loading images: {e}")
            self.status_var.set(f"Error loading images: {str(e)}")
        finally:
            self.loading = False
    
    def _create_image_grid(self):
        """Create a grid of image thumbnails."""
        # Calculate number of columns based on window width
        columns = max(3, self.winfo_width() // 250)
        
        # Create frames for each image
        for i, image_id in enumerate(self.image_ids):
            row = i // columns
            col = i % columns
            
            # Create a frame for this image
            frame = ttk.Frame(self.images_frame, borderwidth=2, relief=tk.GROOVE, padding=5)
            frame.grid(row=row, column=col, padx=5, pady=5, sticky=tk.NSEW)
            
            # Add a loading label
            loading_label = ttk.Label(frame, text=f"Loading {image_id}...", anchor=tk.CENTER)
            loading_label.pack(fill=tk.BOTH, expand=True, pady=50)
            
            # Start loading the image details and thumbnail in a separate thread
            threading.Thread(
                target=self._load_image_details_thread, 
                args=(image_id, frame, loading_label),
                daemon=True
            ).start()
    
    def _load_image_details_thread(self, image_id, frame, loading_label):
        """Background thread for loading image details and thumbnail."""
        try:
            # Get image details
            image_details = self.api_client.get_image_details(image_id)
            if not image_details:
                loading_label.config(text=f"Failed to load {image_id}")
                return
            
            # Cache the details
            self.image_details_cache[image_id] = image_details
            
            # Download thumbnail
            thumbnail_path = self.api_client.download_thumbnail(image_details)
            if not thumbnail_path:
                loading_label.config(text=f"Failed to load thumbnail for {image_id}")
                return
            
            # Update UI in the main thread
            self.after(0, lambda: self._update_image_frame(image_id, frame, loading_label, thumbnail_path))
            
        except Exception as e:
            logger.error(f"Error loading image details for {image_id}: {e}")
            self.after(0, lambda: loading_label.config(text=f"Error: {str(e)}"))
    
    def _update_image_frame(self, image_id, frame, loading_label, thumbnail_path):
        """Update the image frame with the loaded thumbnail."""
        # Remove loading label
        loading_label.destroy()
        
        try:
            # Load and resize the thumbnail
            img = Image.open(thumbnail_path)
            img.thumbnail((200, 150))
            photo = ImageTk.PhotoImage(img)
            
            # Keep a reference to prevent garbage collection
            self.thumbnail_images[image_id] = photo
            
            # Create image label
            img_label = ttk.Label(frame, image=photo, cursor="hand2")
            img_label.pack(pady=(0, 5))
            
            # Add image ID label
            id_label = ttk.Label(frame, text=image_id, anchor=tk.CENTER)
            id_label.pack(fill=tk.X)
            
            # Bind click event
            img_label.bind("<Button-1>", lambda e, id=image_id: self.select_image(id, frame))
            id_label.bind("<Button-1>", lambda e, id=image_id: self.select_image(id, frame))
            frame.bind("<Button-1>", lambda e, id=image_id: self.select_image(id, frame))
            
        except Exception as e:
            logger.error(f"Error updating image frame for {image_id}: {e}")
            error_label = ttk.Label(frame, text=f"Error: {str(e)}", anchor=tk.CENTER)
            error_label.pack(fill=tk.BOTH, expand=True)
    
    def select_image(self, image_id, frame):
        """Select an image."""
        # Reset previous selection
        if self.selected_image_id:
            for widget in self.images_frame.winfo_children():
                widget.configure(style="")
        
        # Set new selection
        self.selected_image_id = image_id
        frame.configure(style="Selected.TFrame")
        
        # Enable apply button
        self.apply_button.config(state=tk.NORMAL)
        
        # Update status
        self.status_var.set(f"Selected image: {image_id}")
    
    def apply_wallpaper(self):
        """Apply the selected wallpaper."""
        if not self.selected_image_id:
            messagebox.showwarning("No Selection", "Please select an image first.")
            return
        
        # Get image details
        image_details = self.image_details_cache.get(self.selected_image_id)
        if not image_details:
            messagebox.showerror("Error", f"Image details not found for {self.selected_image_id}")
            return
        
        # Show loading status
        self.status_var.set(f"Downloading and applying wallpaper...")
        self.apply_button.config(state=tk.DISABLED)
        
        # Start in a separate thread
        threading.Thread(target=self._apply_wallpaper_thread, args=(image_details,), daemon=True).start()
    
    def _apply_wallpaper_thread(self, image_details):
        """Background thread for applying wallpaper."""
        try:
            # Download the full image
            image_path = self.api_client.download_image(image_details)
            if not image_path:
                self.after(0, lambda: messagebox.showerror("Error", "Failed to download image"))
                return
            
            # Get selected style
            style_name = self.style_var.get()
            style = next((s for n, s in self.wallpaper_manager.get_available_styles() if n == style_name), None)
            
            # Set as wallpaper
            success = self.wallpaper_manager.set_wallpaper(image_path, style)
            
            # Update UI in the main thread
            if success:
                self.after(0, lambda: self.status_var.set(f"Wallpaper applied successfully: {self.selected_image_id}"))
                self.after(0, lambda: messagebox.showinfo("Success", "Wallpaper applied successfully!"))
            else:
                self.after(0, lambda: self.status_var.set(f"Failed to apply wallpaper"))
                self.after(0, lambda: messagebox.showerror("Error", "Failed to apply wallpaper"))
            
        except Exception as e:
            logger.error(f"Error applying wallpaper: {e}")
            self.after(0, lambda: self.status_var.set(f"Error applying wallpaper: {str(e)}"))
            self.after(0, lambda: messagebox.showerror("Error", f"Error applying wallpaper: {str(e)}"))
        finally:
            self.after(0, lambda: self.apply_button.config(state=tk.NORMAL))
