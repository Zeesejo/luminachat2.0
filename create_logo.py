#!/usr/bin/env python3
"""
LumiChat Logo Creator
Creates a modern, professional HD logo for the LumiChat AI messaging app
"""

from PIL import Image, ImageDraw, ImageFont
import numpy as np
import math

def create_lumichat_logo(size=512):
    """Create a modern LumiChat logo with AI-inspired design"""
    
    # Create canvas with transparent background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Define colors
    primary_color = (74, 144, 226)  # Modern blue from AppTheme
    secondary_color = (138, 43, 226)  # Purple gradient
    accent_color = (255, 255, 255)  # White
    glow_color = (74, 144, 226, 80)  # Semi-transparent blue for glow
    
    center = size // 2
    
    # Create gradient background circle
    gradient_radius = size // 2 - 20
    
    # Draw outer glow effect
    for i in range(15, 0, -1):
        alpha = int(20 - i)
        glow_radius = gradient_radius + i * 2
        draw.ellipse(
            [center - glow_radius, center - glow_radius, 
             center + glow_radius, center + glow_radius],
            fill=(*primary_color, alpha)
        )
    
    # Main gradient circle (simulate with concentric circles)
    for i in range(gradient_radius, 0, -2):
        # Calculate gradient color
        ratio = i / gradient_radius
        r = int(primary_color[0] * ratio + secondary_color[0] * (1 - ratio))
        g = int(primary_color[1] * ratio + secondary_color[1] * (1 - ratio))
        b = int(primary_color[2] * ratio + secondary_color[2] * (1 - ratio))
        
        draw.ellipse(
            [center - i, center - i, center + i, center + i],
            fill=(r, g, b, 255)
        )
    
    # Create modern chat bubble with AI twist
    bubble_size = size // 3
    bubble_x = center - bubble_size // 2
    bubble_y = center - bubble_size // 2 - size // 20
    
    # Main chat bubble
    draw.rounded_rectangle(
        [bubble_x, bubble_y, bubble_x + bubble_size, bubble_y + bubble_size * 0.8],
        radius=bubble_size // 6,
        fill=accent_color
    )
    
    # Chat bubble tail
    tail_points = [
        (bubble_x + bubble_size // 4, bubble_y + bubble_size * 0.8),
        (bubble_x + bubble_size // 6, bubble_y + bubble_size * 0.95),
        (bubble_x + bubble_size // 3, bubble_y + bubble_size * 0.8)
    ]
    draw.polygon(tail_points, fill=accent_color)
    
    # AI-inspired neural network dots inside bubble
    dot_positions = [
        (center - bubble_size // 6, center - bubble_size // 8),
        (center, center - bubble_size // 8),
        (center + bubble_size // 6, center - bubble_size // 8),
        (center - bubble_size // 8, center + bubble_size // 12),
        (center + bubble_size // 8, center + bubble_size // 12),
    ]
    
    # Draw neural network connections
    connection_color = (*primary_color, 100)
    for i, pos1 in enumerate(dot_positions):
        for j, pos2 in enumerate(dot_positions[i+1:], i+1):
            draw.line([pos1, pos2], fill=connection_color, width=2)
    
    # Draw neural network nodes
    for pos in dot_positions:
        draw.ellipse(
            [pos[0] - 6, pos[1] - 6, pos[0] + 6, pos[1] + 6],
            fill=primary_color
        )
        draw.ellipse(
            [pos[0] - 4, pos[1] - 4, pos[0] + 4, pos[1] + 4],
            fill=accent_color
        )
    
    # Add subtle shine effect
    shine_gradient = gradient_radius // 2
    shine_center_x = center - gradient_radius // 4
    shine_center_y = center - gradient_radius // 4
    
    for i in range(shine_gradient, 0, -1):
        alpha = int(30 * (1 - i / shine_gradient))
        draw.ellipse(
            [shine_center_x - i, shine_center_y - i,
             shine_center_x + i, shine_center_y + i],
            fill=(255, 255, 255, alpha)
        )
    
    return img

def create_app_icon_set():
    """Create various sizes for Android app icons"""
    sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192
    }
    
    for density, size in sizes.items():
        logo = create_lumichat_logo(size)
        logo.save(f'lumichat_icon_{density}_{size}x{size}.png', 'PNG')
        print(f"Created {density} icon: {size}x{size}")

def main():
    # Create main logo (1024x1024 for HD quality)
    print("Creating LumiChat HD Logo...")
    main_logo = create_lumichat_logo(1024)
    main_logo.save('lumichat_logo_hd.png', 'PNG')
    print("✓ Created HD logo (1024x1024)")
    
    # Create standard app logo (512x512)
    standard_logo = create_lumichat_logo(512)
    standard_logo.save('lumichat_logo.png', 'PNG')
    print("✓ Created standard logo (512x512)")
    
    # Create app icon set
    print("\nCreating Android app icon set...")
    create_app_icon_set()
    print("✓ Created Android app icons")
    
    # Create favicon size
    favicon = create_lumichat_logo(64)
    favicon.save('lumichat_favicon.png', 'PNG')
    print("✓ Created favicon (64x64)")
    
    print("\n🎉 All LumiChat logos created successfully!")
    print("\nFiles created:")
    print("- lumichat_logo_hd.png (1024x1024) - Main HD logo")
    print("- lumichat_logo.png (512x512) - Standard app logo") 
    print("- lumichat_favicon.png (64x64) - Small icon/favicon")
    print("- lumichat_icon_*.png - Android app icons (various densities)")

if __name__ == "__main__":
    main()
