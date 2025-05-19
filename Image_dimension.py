from PIL import Image

# Provide input and output image paths
input_image_path = r"C:\\Users\\DELL\\Desktop\\PE1\\Dataset\\deer.tiff"
output_image_path = r"C:\\Users\\DELL\\Desktop\\PE1\\Dataset\\deer.tiff"

try:
    img = Image.open(input_image_path)

    # Convert to grayscale if not already
    if img.mode != 'L':
        img = img.convert('L')

    # Resize to 256x256
    img_resized = img.resize((256, 256), Image.Resampling.LANCZOS)

    # Save to output path
    img_resized.save(output_image_path)
    print(f"Resized and saved: {output_image_path}")

except Exception as e:
    print(f"Failed to process the image: {e}")
