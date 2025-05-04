# Wallpaper Changer

A Windows application to browse and set desktop wallpapers from an online API.

## Features

- Browse wallpapers from the aiwp.me API
- View thumbnails in a grid layout
- Select and apply wallpapers with a single click
- Choose from different wallpaper styles (Fill, Fit, Stretch, Tile, Center, Span)
- Caching for better performance

## Requirements

- Windows 10 or later
- Python 3.7 or later
- Required Python packages (see requirements.txt)

## Installation

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/wallpaper-changer.git
   cd wallpaper-changer
   ```

2. Install the required dependencies:
   ```
   pip install -r requirements.txt
   ```

## Usage

Run the application:
```
python main.py
```

### How to Use

1. Browse the available wallpapers in the grid
2. Click on an image to select it
3. Choose a wallpaper style (Fill, Fit, Stretch, etc.)
4. Click "Apply Selected Wallpaper" to set it as your desktop background
5. Use the "Refresh" button to reload the image list from the API

## API Information

This application uses the following API endpoints:

- `https://aiwp.me/api/images.json` - Returns an array of all image IDs
- `https://aiwp.me/api/images/{id}.json` - Returns information about a specific image by ID

## License

MIT

## Acknowledgements

- Thanks to aiwp.me for providing the wallpaper API
