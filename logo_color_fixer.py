#!/usr/bin/env python3
"""
Logo and App Color Fixer for LumiChat
Fixes logo colors to perfectly match app theme and creates optimized versions
"""

from PIL import Image, ImageEnhance, ImageFilter, ImageOps
import os
import colorsys

def rgb_to_hsl(r, g, b):
    """Convert RGB to HSL"""
    r, g, b = r/255.0, g/255.0, b/255.0
    return colorsys.rgb_to_hls(r, g, b)

def hsl_to_rgb(h, l, s):
    """Convert HSL to RGB"""
    r, g, b = colorsys.hls_to_rgb(h, l, s)
    return int(r*255), int(g*255), int(b*255)

def adjust_color_to_theme(pixel, theme_hue, saturation_boost=1.5, lightness_adjust=0):
    """Adjust pixel color to match app theme"""
    if len(pixel) == 4 and pixel[3] == 0:  # Transparent pixel
        return pixel
        
    r, g, b = pixel[:3]
    alpha = pixel[3] if len(pixel) == 4 else 255
    
    # Convert to HSL
    h, l, s = rgb_to_hsl(r, g, b)
    
    # Adjust to theme hue with enhanced saturation and lightness
    new_h = theme_hue
    new_s = min(1.0, s * saturation_boost)
    new_l = max(0.1, min(0.9, l + lightness_adjust))
    
    # Convert back to RGB
    new_r, new_g, new_b = hsl_to_rgb(new_h, new_l, new_s)
    
    return (new_r, new_g, new_b, alpha) if len(pixel) == 4 else (new_r, new_g, new_b)

def create_theme_matched_logo():
    """Create logo with perfect theme color matching"""
    
    # App theme colors
    primary_color = (20, 184, 166)  # #14B8A6 - Teal
    secondary_color = (139, 92, 246)  # #8B5CF6 - Purple
    
    # Get theme hue from primary color
    theme_hue = rgb_to_hsl(*primary_color)[0]
    
    # Load the base logo
    logo_path = "assets/images/luminachat-tempo-logo.png"
    if not os.path.exists(logo_path):
        logo_path = "assets/images/logo.png"
    
    print(f"Loading logo from: {logo_path}")
    base_logo = Image.open(logo_path).convert("RGBA")
    
    # Create enhanced versions
    sizes = [
        (150, 150, "splash_small"),
        (200, 200, "splash_medium"), 
        (280, 280, "splash_large"),
        (350, 350, "splash_xl"),
        (500, 500, "ultra_hd"),
        (1024, 1024, "xxl")
    ]
    
    for width, height, suffix in sizes:
        print(f"Creating {suffix} version ({width}x{height})...")
        
        # Resize with high quality
        logo = base_logo.resize((width, height), Image.Resampling.LANCZOS)
        
        # Enhance colors to match theme
        pixels = logo.load()
        for y in range(logo.height):
            for x in range(logo.width):
                pixel = pixels[x, y]
                pixels[x, y] = adjust_color_to_theme(pixel, theme_hue, 1.8, 0.1)
        
        # Enhance contrast and vibrancy
        enhancer = ImageEnhance.Contrast(logo)
        logo = enhancer.enhance(1.4)
        
        enhancer = ImageEnhance.Color(logo)
        logo = enhancer.enhance(1.6)
        
        # Add subtle glow effect for larger sizes
        if width >= 280:
            # Create glow layer
            glow = logo.copy()
            glow = glow.filter(ImageFilter.GaussianBlur(radius=8))
            
            # Composite glow with original
            final_logo = Image.new("RGBA", logo.size)
            final_logo = Image.alpha_composite(final_logo, glow)
            final_logo = Image.alpha_composite(final_logo, logo)
            logo = final_logo
        
        # Save the enhanced logo
        output_path = f"assets/images/logo_{suffix}.png"
        logo.save(output_path, "PNG", optimize=True, quality=100)
        print(f"✅ Saved: {output_path}")

def create_themed_android_icons():
    """Create Android app icons with perfect theme integration"""
    
    # Load base logo
    logo_path = "assets/images/luminachat-tempo-logo.png"
    if not os.path.exists(logo_path):
        logo_path = "assets/images/logo.png"
    
    base_logo = Image.open(logo_path).convert("RGBA")
    
    # App theme colors
    primary_color = (20, 184, 166)  # #14B8A6 - Teal
    secondary_color = (139, 92, 246)  # #8B5CF6 - Purple
    
    # Android icon sizes (enhanced for better visibility)
    icon_sizes = [
        ("mdpi", 56),      # Enhanced from 48
        ("hdpi", 84),      # Enhanced from 72  
        ("xhdpi", 112),    # Enhanced from 96
        ("xxhdpi", 168),   # Enhanced from 144
        ("xxxhdpi", 224),  # Enhanced from 192
    ]
    
    for density, size in icon_sizes:
        print(f"Creating Android icon for {density} ({size}x{size})...")
        
        # Create background with gradient
        background = Image.new("RGBA", (size, size))
        
        # Create gradient background
        for y in range(size):
            for x in range(size):
                # Calculate gradient position
                progress = ((x + y) / (size * 2))
                
                # Interpolate between primary and secondary colors
                r = int(primary_color[0] + (secondary_color[0] - primary_color[0]) * progress)
                g = int(primary_color[1] + (secondary_color[1] - primary_color[1]) * progress)
                b = int(primary_color[2] + (secondary_color[2] - primary_color[2]) * progress)
                
                background.putpixel((x, y), (r, g, b, 255))
        
        # Add rounded corners for modern look
        mask = Image.new("L", (size, size), 0)
        for y in range(size):
            for x in range(size):
                # Calculate distance from corners
                corner_radius = size // 5
                distance_from_corner = min(
                    ((x - corner_radius)**2 + (y - corner_radius)**2)**0.5 if x < corner_radius and y < corner_radius else float('inf'),
                    ((x - (size - corner_radius))**2 + (y - corner_radius)**2)**0.5 if x > size - corner_radius and y < corner_radius else float('inf'),
                    ((x - corner_radius)**2 + (y - (size - corner_radius))**2)**0.5 if x < corner_radius and y > size - corner_radius else float('inf'),
                    ((x - (size - corner_radius))**2 + (y - (size - corner_radius))**2)**0.5 if x > size - corner_radius and y > size - corner_radius else float('inf')
                )
                
                if distance_from_corner < corner_radius or (x >= corner_radius and x < size - corner_radius) or (y >= corner_radius and y < size - corner_radius):
                    mask.putpixel((x, y), 255)
        
        # Apply rounded corners to background
        background.putalpha(mask)
        
        # Resize and overlay logo
        logo_size = int(size * 0.7)  # Logo takes 70% of icon space
        logo_offset = (size - logo_size) // 2
        
        logo_resized = base_logo.resize((logo_size, logo_size), Image.Resampling.LANCZOS)
        
        # Enhance logo colors
        theme_hue = rgb_to_hsl(*primary_color)[0]
        pixels = logo_resized.load()
        for y in range(logo_resized.height):
            for x in range(logo_resized.width):
                pixel = pixels[x, y]
                if len(pixel) == 4 and pixel[3] > 0:  # Non-transparent
                    pixels[x, y] = adjust_color_to_theme(pixel, theme_hue, 2.0, 0.2)
        
        # Add white stroke around logo for contrast
        stroke_logo = ImageOps.expand(logo_resized, border=2, fill=(255, 255, 255, 200))
        stroke_size = logo_size + 4
        stroke_offset = (size - stroke_size) // 2
        
        # Composite final icon
        final_icon = background.copy()
        final_icon.paste(stroke_logo, (stroke_offset, stroke_offset), stroke_logo)
        final_icon.paste(logo_resized, (logo_offset, logo_offset), logo_resized)
        
        # Save icon
        icon_dir = f"android/app/src/main/res/mipmap-{density}"
        os.makedirs(icon_dir, exist_ok=True)
        
        output_path = f"{icon_dir}/ic_launcher.png"
        final_icon.save(output_path, "PNG", optimize=True, quality=100)
        print(f"✅ Saved Android icon: {output_path}")

def update_app_constants():
    """Update app constants with theme-matched assets"""
    
    constants_path = "lib/core/utils/constants.dart"
    if os.path.exists(constants_path):
        print("Updating app constants...")
        
        with open(constants_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Update logo path to use the enhanced splash version
        if "class AppImages" in content:
            content = content.replace(
                "static const String logo = 'assets/images/logo.png';",
                "static const String logo = 'assets/images/logo_splash_large.png';"
            )
            
            with open(constants_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print("✅ Updated app constants with new logo path")

def main():
    """Main execution function"""
    print("🚀 LumiChat Logo & Color Fixer")
    print("=" * 50)
    
    try:
        # Change to project directory
        os.chdir("e:/luminachat-2.0")
        
        print("📱 Creating theme-matched logo versions...")
        create_theme_matched_logo()
        
        print("\n🤖 Creating themed Android app icons...")
        create_themed_android_icons()
        
        print("\n⚙️  Updating app constants...")
        update_app_constants()
        
        print("\n" + "=" * 50)
        print("✅ Logo and color fixes completed successfully!")
        print("\nEnhancements applied:")
        print("• Perfect theme color matching (Teal/Purple)")
        print("• Enhanced contrast and vibrancy (+60%)")
        print("• Multiple optimized sizes for different uses")
        print("• Android icons with gradient backgrounds")
        print("• Subtle glow effects for premium look")
        print("• Rounded corners with white stroke for visibility")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())
