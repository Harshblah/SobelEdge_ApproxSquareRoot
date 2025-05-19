import numpy as np
import imageio
import matplotlib.pyplot as plt

# ─── CONFIGURATION ────────────────────────────────────────────────────────────
BIG_HEX_PATH             = "C:\\Users\\DELL\\Desktop\\PE1\\SobelEdgeDetection\\SobelEdgeDetection.sim\\sim_1\\behav\\xsim\\output_image_256x256.hex"
SMALL_HEX_PATH           = "C:\\Users\\DELL\\Desktop\\PE1\\SobelEdgeDetection\\SobelEdgeDetection.sim\\sim_1\\behav\\xsim\\output_image_192x251.hex"
RECONSTRUCTED_IMAGE_PATH = "C:\\Users\\DELL\\Desktop\\PE1\\Output_YOLO_256x256\\deer_reconstructed.png"

# Bounding-box parameters (modify as needed)
BOX_X0, BOX_Y0 = 62, 5
BOX_W,  BOX_H  = 192, 251

# Image dimensions
BIG_H, BIG_W = 256, 256

def load_hex(path, expected_count):
    vals = []
    with open(path, 'r') as f:
        for line in f:
            s = line.strip()
            if not s:
                continue
            if s.upper() == 'XX':
                vals.append(0)
                continue
            try:
                v = int(s, 0)
            except ValueError:
                v = int(s, 16)
            vals.append(v)
    arr = np.array(vals, dtype=np.uint8)
    if arr.size != expected_count:
        raise ValueError(f"{path}: expected {expected_count} values, got {arr.size}")
    return arr

def smooth_border_transition(image, x0, y0, w, h, margin=5):
    """
    Smooth the borders between the inserted patch and the surrounding image
    by linear blending over a margin width.
    """
    x1, y1 = x0 + w, y0 + h

    for i in range(1, margin + 1):
        alpha = i / (margin + 1)

        # Top border
        if y0 - i >= 0:
            image[y0 - i, x0:x1] = (
                (1 - alpha) * image[y0 - i, x0:x1] + alpha * image[y0, x0:x1]
            ).astype(np.uint8)

        # Bottom border
        if y1 + i - 1 < image.shape[0]:
            image[y1 + i - 1, x0:x1] = (
                (1 - alpha) * image[y1 + i - 1, x0:x1] + alpha * image[y1 - 1, x0:x1]
            ).astype(np.uint8)

        # Left border
        if x0 - i >= 0:
            image[y0:y1, x0 - i] = (
                (1 - alpha) * image[y0:y1, x0 - i] + alpha * image[y0:y1, x0]
            ).astype(np.uint8)

        # Right border
        if x1 + i - 1 < image.shape[1]:
            image[y0:y1, x1 + i - 1] = (
                (1 - alpha) * image[y0:y1, x1 + i - 1] + alpha * image[y0:y1, x1 - 1]
            ).astype(np.uint8)

# ─── LOAD & RECONSTRUCT ───────────────────────────────────────────────────────
# 1. Load flat arrays
big_flat   = load_hex(BIG_HEX_PATH,   BIG_H * BIG_W)
small_flat = load_hex(SMALL_HEX_PATH, BOX_H * BOX_W)

# 2. Reshape to 2D
big_img   = big_flat.reshape((BIG_H, BIG_W))
small_img = small_flat.reshape((BOX_H, BOX_W))

# 3. Insert small patch into big image at the bounding-box coords
big_img[BOX_Y0:BOX_Y0+BOX_H, BOX_X0:BOX_X0+BOX_W] = small_img

# 4. Optional hard-border padding (can be commented out if not needed)
# Leave here in case you still want to fill one-pixel edges
y0, y1 = BOX_Y0, BOX_Y0 + BOX_H
x0, x1 = BOX_X0, BOX_X0 + BOX_W
if y0 > 0:
    big_img[y0-1, x0:x1] = big_img[y0, x0:x1]
if y1 < BIG_H:
    big_img[y1, x0:x1] = big_img[y1-1, x0:x1]
if x0 > 0:
    big_img[y0:y1, x0-1] = big_img[y0:y1, x0]
if x1 < BIG_W:
    big_img[y0:y1, x1] = big_img[y0:y1, x1-1]

# 5. Smooth transition at patch borders
smooth_border_transition(big_img, BOX_X0, BOX_Y0, BOX_W, BOX_H, margin=3)

# 6. Save reconstructed image
imageio.imsave(RECONSTRUCTED_IMAGE_PATH, big_img)

# 7. Display for quick check
plt.figure(figsize=(5,5))
plt.imshow(big_img, cmap='gray', vmin=0, vmax=255)
plt.axis('off')
plt.title('Reconstructed Image (Smoothed)')
plt.show()
