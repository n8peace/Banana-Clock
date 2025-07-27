#!/usr/bin/env python3
"""
iOS 26 App Icon Generator for Banana Clock
Generates all required icon sizes from the master SVG
"""

import os
import subprocess
from pathlib import Path

# Icon size configurations for iOS 26
ICON_SIZES = [
    (40, "icon-40.png"),      # 20pt @2x
    (60, "icon-60.png"),      # 20pt @3x
    (58, "icon-58.png"),      # 29pt @2x
    (87, "icon-87.png"),      # 29pt @3x
    (80, "icon-80.png"),      # 40pt @2x
    (120, "icon-120.png"),    # 40pt @3x, 60pt @2x
    (180, "icon-180.png"),    # 60pt @3x
    (1024, "icon-1024.png"),  # App Store
]

def check_dependencies():
    """Check if required tools are installed"""
    tools = {
        "Inkscape": ["inkscape", "--version"],
        "ImageMagick": ["convert", "-version"],
        "rsvg-convert": ["rsvg-convert", "--version"]
    }
    
    available = {}
    for name, cmd in tools.items():
        try:
            subprocess.run(cmd, capture_output=True, check=True)
            available[name] = True
            print(f"✓ {name} is installed")
        except:
            available[name] = False
            print(f"✗ {name} is not installed")
    
    return available

def generate_with_inkscape(svg_path, output_dir):
    """Generate icons using Inkscape"""
    print("\nGenerating icons with Inkscape...")
    
    for size, filename in ICON_SIZES:
        output_path = output_dir / filename
        cmd = [
            "inkscape",
            str(svg_path),
            f"--export-filename={output_path}",
            f"--export-width={size}",
            f"--export-height={size}",
            "--export-background=#000000",
            "--export-background-opacity=1"
        ]
        
        print(f"  Generating {filename} ({size}x{size})...", end="")
        result = subprocess.run(cmd, capture_output=True)
        if result.returncode == 0:
            print(" ✓")
        else:
            print(f" ✗ Error: {result.stderr.decode()}")

def generate_with_imagemagick(svg_path, output_dir):
    """Generate icons using ImageMagick"""
    print("\nGenerating icons with ImageMagick...")
    
    for size, filename in ICON_SIZES:
        output_path = output_dir / filename
        cmd = [
            "convert",
            "-background", "black",
            "-density", "300",
            str(svg_path),
            "-resize", f"{size}x{size}",
            "-gravity", "center",
            "-extent", f"{size}x{size}",
            str(output_path)
        ]
        
        print(f"  Generating {filename} ({size}x{size})...", end="")
        result = subprocess.run(cmd, capture_output=True)
        if result.returncode == 0:
            print(" ✓")
        else:
            print(f" ✗ Error: {result.stderr.decode()}")

def generate_with_rsvg(svg_path, output_dir):
    """Generate icons using rsvg-convert"""
    print("\nGenerating icons with rsvg-convert...")
    
    for size, filename in ICON_SIZES:
        output_path = output_dir / filename
        cmd = [
            "rsvg-convert",
            "-w", str(size),
            "-h", str(size),
            "-b", "black",
            str(svg_path),
            "-o", str(output_path)
        ]
        
        print(f"  Generating {filename} ({size}x{size})...", end="")
        result = subprocess.run(cmd, capture_output=True)
        if result.returncode == 0:
            print(" ✓")
        else:
            print(f" ✗ Error: {result.stderr.decode()}")

def create_xcassets_structure(output_dir):
    """Create the proper Xcode asset structure"""
    print("\nCreating Xcode asset structure...")
    
    # Copy Contents.json
    contents_src = Path("AppIcon-Contents.json")
    contents_dst = output_dir / "Contents.json"
    
    if contents_src.exists():
        contents_dst.write_text(contents_src.read_text())
        print("  ✓ Copied Contents.json")
    else:
        print("  ✗ AppIcon-Contents.json not found")

def main():
    print("🍌 Banana Clock iOS 26 Icon Generator")
    print("=====================================")
    
    # Check for SVG file
    svg_path = Path("banana-clock-ios26-icon.svg")
    if not svg_path.exists():
        print(f"\n❌ Error: {svg_path} not found!")
        print("Please ensure the iOS 26 style SVG is in the current directory.")
        return
    
    # Create output directory
    output_dir = Path("AppIcon.appiconset")
    output_dir.mkdir(exist_ok=True)
    print(f"\n📁 Output directory: {output_dir}")
    
    # Check dependencies
    tools = check_dependencies()
    
    # Generate icons with available tool
    if tools.get("Inkscape"):
        generate_with_inkscape(svg_path, output_dir)
    elif tools.get("ImageMagick"):
        generate_with_imagemagick(svg_path, output_dir)
    elif tools.get("rsvg-convert"):
        generate_with_rsvg(svg_path, output_dir)
    else:
        print("\n❌ No supported tools found!")
        print("Please install one of: Inkscape, ImageMagick, or rsvg-convert")
        return
    
    # Create Xcode structure
    create_xcassets_structure(output_dir)
    
    print("\n✅ Icon generation complete!")
    print(f"📱 Icons saved to: {output_dir}")
    print("\nNext steps:")
    print("1. Drag the AppIcon.appiconset folder to Assets.xcassets in Xcode")
    print("2. Set 'App Icons Source' to 'AppIcon' in project settings")
    print("3. Clean build folder and run")

if __name__ == "__main__":
    main()