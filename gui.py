import tkinter as tk
from tkinter import ttk, messagebox
import threading
import os
import logging
import re
from typing import Dict, List, Any, Optional
from PIL import Image, ImageTk

from api_client import WallpaperAPIClient
from wallpaper_manager import WallpaperManager, WallpaperStyle, ScheduleType

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
        self.api_client = WallpaperAPIClient(compress_existing_thumbnails=True)
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

        # Set up cleanup on exit
        self.protocol("WM_DELETE_WINDOW", self.on_close)

    def create_ui(self):
        """Create the user interface."""
        # Main frame
        main_frame = ttk.Frame(self)
        main_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)

        # Top controls
        controls_frame = ttk.Frame(main_frame)
        controls_frame.pack(fill=tk.X, pady=(0, 10))

        refresh_button = ttk.Button(controls_frame, text="Refresh", command=self.load_images)
        refresh_button.pack(side=tk.LEFT, padx=(0, 5))

        compress_button = ttk.Button(controls_frame, text="Compress Thumbnails", command=self.compress_thumbnails)
        compress_button.pack(side=tk.LEFT)

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

        # Random wallpaper scheduler frame
        scheduler_frame = ttk.LabelFrame(main_frame, text="Random Wallpaper Scheduler")
        scheduler_frame.pack(fill=tk.X, pady=10)

        # Schedule type selection
        schedule_type_frame = ttk.Frame(scheduler_frame)
        schedule_type_frame.pack(fill=tk.X, padx=10, pady=5)

        ttk.Label(schedule_type_frame, text="Change wallpaper:").pack(side=tk.LEFT, padx=(0, 10))

        self.schedule_type_var = tk.StringVar(value=ScheduleType.DISABLED.value)

        ttk.Radiobutton(
            schedule_type_frame,
            text="Disabled",
            value=ScheduleType.DISABLED.value,
            variable=self.schedule_type_var,
            command=self.on_schedule_type_changed
        ).pack(side=tk.LEFT, padx=5)

        ttk.Radiobutton(
            schedule_type_frame,
            text="Every Hour",
            value=ScheduleType.HOURLY.value,
            variable=self.schedule_type_var,
            command=self.on_schedule_type_changed
        ).pack(side=tk.LEFT, padx=5)

        ttk.Radiobutton(
            schedule_type_frame,
            text="At Specific Time",
            value=ScheduleType.SPECIFIC_TIME.value,
            variable=self.schedule_type_var,
            command=self.on_schedule_type_changed
        ).pack(side=tk.LEFT, padx=5)

        # Specific time entry
        time_frame = ttk.Frame(scheduler_frame)
        time_frame.pack(fill=tk.X, padx=10, pady=5)

        ttk.Label(time_frame, text="Time (HH:MM):").pack(side=tk.LEFT, padx=(0, 10))

        self.time_entry = ttk.Entry(time_frame, width=10)
        self.time_entry.insert(0, "12:00")
        self.time_entry.pack(side=tk.LEFT)
        self.time_entry.config(state=tk.DISABLED)

        # Apply scheduler button
        self.apply_scheduler_button = ttk.Button(
            scheduler_frame,
            text="Apply Scheduler Settings",
            command=self.apply_scheduler_settings,
            state=tk.DISABLED
        )
        self.apply_scheduler_button.pack(pady=10)

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

    def on_schedule_type_changed(self):
        """Handle schedule type change."""
        schedule_type = self.schedule_type_var.get()

        # Enable/disable time entry based on schedule type
        if schedule_type == ScheduleType.SPECIFIC_TIME.value:
            self.time_entry.config(state=tk.NORMAL)
        else:
            self.time_entry.config(state=tk.DISABLED)

        # Enable apply button
        self.apply_scheduler_button.config(state=tk.NORMAL)

    def apply_scheduler_settings(self):
        """Apply the scheduler settings."""
        schedule_type_str = self.schedule_type_var.get()
        schedule_type = next((t for t in ScheduleType if t.value == schedule_type_str), ScheduleType.DISABLED)

        # Validate time format if specific time is selected
        specific_time = None
        if schedule_type == ScheduleType.SPECIFIC_TIME:
            specific_time = self.time_entry.get()
            if not self._validate_time_format(specific_time):
                messagebox.showerror("Invalid Time", "Please enter a valid time in HH:MM format (24-hour)")
                return

        # Get the cached images for random selection
        cached_images = []
        for image_id, details in self.image_details_cache.items():
            image_path = os.path.join(self.api_client.CACHE_DIR, image_id)
            if os.path.exists(image_path):
                cached_images.append(image_path)

        if not cached_images and schedule_type != ScheduleType.DISABLED:
            messagebox.showwarning(
                "No Images Available",
                "No cached images available for random selection. Please browse and select some images first."
            )
            return

        # Get selected style
        style_name = self.style_var.get()
        style = next((s for n, s in self.wallpaper_manager.get_available_styles() if n == style_name), None)

        # Set available images
        self.wallpaper_manager.set_available_images(cached_images)

        # Set the callback function
        self.wallpaper_manager.on_wallpaper_changed = self._on_random_wallpaper_changed

        # Apply scheduler settings
        self.wallpaper_manager.set_random_wallpaper_schedule(schedule_type, specific_time, style)

        # Show confirmation
        if schedule_type == ScheduleType.DISABLED:
            messagebox.showinfo("Scheduler Disabled", "Random wallpaper scheduler has been disabled")
        elif schedule_type == ScheduleType.HOURLY:
            messagebox.showinfo("Scheduler Enabled", "Wallpaper will change every hour")
        elif schedule_type == ScheduleType.SPECIFIC_TIME:
            messagebox.showinfo("Scheduler Enabled", f"Wallpaper will change daily at {specific_time}")

    def _validate_time_format(self, time_str):
        """Validate time format (HH:MM in 24-hour format)."""
        if not time_str:
            return False

        # Check format using regex
        if not re.match(r'^([01]\d|2[0-3]):([0-5]\d)$', time_str):
            return False

        return True

    def _on_random_wallpaper_changed(self, image_path):
        """Callback when random wallpaper is changed."""
        # Find the image ID from the path
        image_id = os.path.basename(image_path)

        # Update status
        self.status_var.set(f"Random wallpaper applied: {image_id}")

        # Log the change
        logger.info(f"Random wallpaper changed to: {image_id}")

    def compress_thumbnails(self):
        """Compress all thumbnails in the cache to reduce disk space."""
        # Show confirmation dialog
        if not messagebox.askyesno(
            "Compress Thumbnails",
            "This will compress all thumbnails in the cache to reduce disk space. Continue?"
        ):
            return

        # Disable UI during compression
        self.status_var.set("Compressing thumbnails...")

        # Start compression in a separate thread
        threading.Thread(target=self._compress_thumbnails_thread, daemon=True).start()

    def _compress_thumbnails_thread(self):
        """Background thread for compressing thumbnails."""
        try:
            # Compress thumbnails
            self.api_client.compress_existing_thumbnails()

            # Update UI in the main thread
            self.after(0, lambda: self.status_var.set("Thumbnail compression completed"))
            self.after(0, lambda: messagebox.showinfo(
                "Compression Complete",
                "All thumbnails have been compressed successfully."
            ))

        except Exception as e:
            logger.error(f"Error compressing thumbnails: {e}")
            self.after(0, lambda: self.status_var.set(f"Error compressing thumbnails: {str(e)}"))
            self.after(0, lambda: messagebox.showerror(
                "Compression Error",
                f"Error compressing thumbnails: {str(e)}"
            ))

    def on_close(self):
        """Handle application close."""
        try:
            # Stop the scheduler
            if hasattr(self, 'wallpaper_manager'):
                self.wallpaper_manager.stop_scheduler()
                logger.info("Stopped wallpaper scheduler")

            # Destroy the window
            self.destroy()

        except Exception as e:
            logger.error(f"Error during application close: {e}")
            self.destroy()
