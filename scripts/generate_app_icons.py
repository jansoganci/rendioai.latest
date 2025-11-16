#!/usr/bin/env python3
"""
Generate all required iOS app icon sizes from a source image.
Usage: python3 generate_app_icons.py <source_image_path>
"""

import sys
from PIL import Image
import os

# All required iOS app icon sizes
IOS_ICON_SIZES = {
    # iPhone
    'iphone': {
        'Icon-20@1x.png': 20,
        'Icon-20@2x.png': 40,
        'Icon-20@3x.png': 60,
        'Icon-29@1x.png': 29,
        'Icon-29@2x.png': 58,
        'Icon-29@3x.png': 87,
        'Icon-40@1x.png': 40,
        'Icon-40@2x.png': 80,
        'Icon-40@3x.png': 120,
        'Icon-60@2x.png': 120,
        'Icon-60@3x.png': 180,
    },
    # iPad
    'ipad': {
        'Icon-20@1x.png': 20,
        'Icon-20@2x.png': 40,
        'Icon-29@1x.png': 29,
        'Icon-29@2x.png': 58,
        'Icon-40@1x.png': 40,
        'Icon-40@2x.png': 80,
        'Icon-76@1x.png': 76,
        'Icon-76@2x.png': 152,
        'Icon-83.5@2x.png': 167,
    },
    # App Store
    'appstore': {
        'AppIcon-1024.png': 1024,
    }
}

def generate_icons(source_path, output_dir='AppIcons'):
    """Generate all required iOS app icon sizes."""

    if not os.path.exists(source_path):
        print(f"Error: Source image '{source_path}' not found!")
        sys.exit(1)

    # Open source image
    try:
        img = Image.open(source_path)
        print(f"✓ Loaded source image: {img.size[0]}x{img.size[1]}")
    except Exception as e:
        print(f"Error opening image: {e}")
        sys.exit(1)

    # Convert to RGBA if needed
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    # Create output directories
    os.makedirs(output_dir, exist_ok=True)

    total_icons = 0

    # Generate all sizes
    for category, sizes in IOS_ICON_SIZES.items():
        category_dir = os.path.join(output_dir, category)
        os.makedirs(category_dir, exist_ok=True)

        print(f"\nGenerating {category.upper()} icons:")

        for filename, size in sizes.items():
            output_path = os.path.join(category_dir, filename)

            # Resize with high-quality downsampling
            resized = img.resize((size, size), Image.Resampling.LANCZOS)

            # For App Store, flatten to RGB (no alpha)
            if category == 'appstore':
                # Create white background
                background = Image.new('RGB', (size, size), (255, 255, 255))
                # Paste with alpha mask
                background.paste(resized, (0, 0), resized)
                background.save(output_path, 'PNG', optimize=True)
            else:
                resized.save(output_path, 'PNG', optimize=True)

            print(f"  ✓ {filename} ({size}x{size})")
            total_icons += 1

    print(f"\n✅ Successfully generated {total_icons} icon files in '{output_dir}/'")
    print(f"\n📁 Directory structure:")
    print(f"   {output_dir}/")
    print(f"   ├── iphone/     ({len(IOS_ICON_SIZES['iphone'])} files)")
    print(f"   ├── ipad/       ({len(IOS_ICON_SIZES['ipad'])} files)")
    print(f"   └── appstore/   ({len(IOS_ICON_SIZES['appstore'])} file)")

    return output_dir

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python3 generate_app_icons.py <source_image_path>")
        print("\nExample:")
        print("  python3 generate_app_icons.py rendio.ai.icon.png")
        sys.exit(1)

    source_image = sys.argv[1]
    output_directory = 'AppIcons'

    if len(sys.argv) >= 3:
        output_directory = sys.argv[2]

    generate_icons(source_image, output_directory)
