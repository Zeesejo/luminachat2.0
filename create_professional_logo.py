#!/usr/bin/env python3
"""
LumiChat Professional Logo Creator
Creates a carefully planned, modern logo for LumiChat AI messaging app
"""

from PIL import Image, ImageDraw, ImageFont
import math

def create_professional_logo(size=512):
    """Create a professional LumiChat logo based on careful design planning"""
    
    # Create canvas with transparent background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Brand colors (carefully chosen)
    primary_blue = (74, 144, 226)      # #4A90E2 - Main brand color
    light_blue = (107, 182, 255)      # #6BB6FF - Highlight
    dark_blue = (46, 91, 186)         # #2E5BBA - Deep shade
    white = (255, 255, 255)           # Pure white
    gray = (248, 250, 254)            # Off-white for subtle contrast
    
    center = size // 2
    main_radius = size // 2 - 20
    
    # Create subtle outer glow rings
    for i in range(3, 0, -1):
        alpha = int(20 - i * 5)
        glow_radius = main_radius + i * 3
        draw.ellipse(
            [center - glow_radius, center - glow_radius, 
             center + glow_radius, center + glow_radius],
            outline=(*primary_blue, alpha), width=1
        )
    
    # Main circular background with radial gradient effect
    gradient_steps = 40
    for i in range(gradient_steps, 0, -1):
        # Create radial gradient from light to dark blue
        ratio = i / gradient_steps
        radius = main_radius * ratio
        
        # Color interpolation for radial gradient
        if ratio > 0.7:
            # Outer area: darker blue
            color = dark_blue
        elif ratio > 0.3:
            # Middle area: main blue
            color = primary_blue  
        else:
            # Inner area: lighter blue
            color = light_blue
        
        draw.ellipse(
            [center - radius, center - radius, center + radius, center + radius],
            fill=color
        )
    
    # Chat bubble design (centered, professional proportions)
    bubble_width = size // 3
    bubble_height = int(bubble_width * 0.65)  # Professional aspect ratio
    bubble_x = center - bubble_width // 2
    bubble_y = center - bubble_height // 2 - size // 20
    corner_radius = bubble_width // 8
    
    # Chat bubble shadow (subtle)
    shadow_offset = 2
    draw.rounded_rectangle(
        [bubble_x + shadow_offset, bubble_y + shadow_offset, 
         bubble_x + bubble_width + shadow_offset, bubble_y + bubble_height + shadow_offset],
        radius=corner_radius,
        fill=(0, 0, 0, 30)
    )
    
    # Main chat bubble (clean white with subtle gradient)
    draw.rounded_rectangle(
        [bubble_x, bubble_y, bubble_x + bubble_width, bubble_y + bubble_height],
        radius=corner_radius,
        fill=white
    )
    
    # Bubble tail (properly proportioned)
    tail_size = bubble_width // 6
    tail_points = [
        (bubble_x + bubble_width // 4, bubble_y + bubble_height),
        (bubble_x + bubble_width // 6, bubble_y + bubble_height + tail_size),
        (bubble_x + bubble_width // 3, bubble_y + bubble_height)
    ]
    draw.polygon(tail_points, fill=white)
    
    # AI Neural Network Design (minimalist, professional)
    node_positions = [
        (center - bubble_width // 5, center - bubble_height // 6),     # Top row
        (center, center - bubble_height // 6),
        (center + bubble_width // 5, center - bubble_height // 6),
        (center - bubble_width // 8, center + bubble_height // 8),     # Bottom row  
        (center + bubble_width // 8, center + bubble_height // 8),
    ]
    
    # Connection lines (subtle, professional)
    connection_color = (*primary_blue, 60)
    line_width = max(1, size // 256)
    
    # Draw minimal connections
    connections = [
        (0, 1), (1, 2),  # Top row connections
        (0, 3), (2, 4),  # Cross connections
        (3, 4)           # Bottom connection
    ]
    
    for start_idx, end_idx in connections:
        start_pos = node_positions[start_idx]
        end_pos = node_positions[end_idx]
        draw.line([start_pos, end_pos], fill=primary_blue, width=line_width)
    
    # Neural nodes (clean, professional circles)
    node_radius = max(3, size // 128)
    inner_radius = max(2, size // 170)
    
    for i, pos in enumerate(node_positions):
        # Outer node circle
        node_color = primary_blue if i < 3 else light_blue
        draw.ellipse(
            [pos[0] - node_radius, pos[1] - node_radius, 
             pos[0] + node_radius, pos[1] + node_radius],
            fill=node_color
        )
        
        # Inner highlight
        draw.ellipse(
            [pos[0] - inner_radius, pos[1] - inner_radius,
             pos[0] + inner_radius, pos[1] + inner_radius],
            fill=white
        )
    
    # Subtle highlight on main circle (professional lighting)
    highlight_x = center - main_radius // 3
    highlight_y = center - main_radius // 3
    highlight_radius_x = main_radius // 3
    highlight_radius_y = main_radius // 2
    
    for i in range(highlight_radius_x, 0, -2):
        alpha = int(15 * (1 - i / highlight_radius_x))
        draw.ellipse(
            [highlight_x - i, highlight_y - int(i * 1.5),
             highlight_x + i, highlight_y + int(i * 1.5)],
            fill=(*white, alpha)
        )
    
    return img

def create_app_icons():
    """Create various sizes for app icons"""
    sizes = {
        'mdpi': 48,
        'hdpi': 72, 
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192
    }
    
    icons = {}
    for density, size in sizes.items():
        icon = create_professional_logo(size)
        filename = f'ic_launcher_{density}.png'
        icon.save(filename, 'PNG')
        icons[density] = filename
        print(f"✓ Created {density} icon: {size}x{size}")
    
    return icons

def main():
    print("🎨 Creating Professional LumiChat Logo...")
    print("📋 Design Plan:")
    print("   • Modern circular design with gradient background")
    print("   • Clean white chat bubble with professional proportions") 
    print("   • Minimalist AI neural network (5 nodes, strategic connections)")
    print("   • Brand colors: #4A90E2 primary, #6BB6FF highlight, #2E5BBA deep")
    print("   • Subtle lighting and shadow effects")
    print()
    
    # Create main logo sizes
    main_logo = create_professional_logo(512)
    main_logo.save('logo.png', 'PNG')
    print("✓ Created main logo (512x512)")
    
    # Create HD version
    hd_logo = create_professional_logo(1024)
    hd_logo.save('logo_hd.png', 'PNG')
    print("✓ Created HD logo (1024x1024)")
    
    # Create app icons
    print("\n📱 Creating Android app icons...")
    icons = create_app_icons()
    
    print(f"\n🎉 Professional LumiChat logo completed!")
    print("📁 Files created:")
    print("   • logo.png (512x512) - Main app logo")
    print("   • logo_hd.png (1024x1024) - HD version")
    for density, filename in icons.items():
        print(f"   • {filename} - Android {density} icon")

if __name__ == "__main__":
    main()
