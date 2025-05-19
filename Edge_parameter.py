import cv2
import numpy as np

def compute_edge_param(img_input):
    """
    Compute normalized edge parameter for a 256×256 8-bit image.

    Parameters:
        img_input (str or np.ndarray):
            - If str: path to an image file.
            - If np.ndarray: a 2D uint8 array of shape (256,256).

    Returns:
        float: normalized edge parameter in [0, 1].
    """
    # --- 1) Load image ---
    if isinstance(img_input, str):
        img = cv2.imread(img_input, cv2.IMREAD_GRAYSCALE)
        if img is None:
            raise ValueError(f"Cannot read image at '{img_input}'")
    else:
        img = img_input.copy()
    if img.dtype != np.uint8 or img.shape != (256, 256):
        raise ValueError("Input must be a 256×256 uint8 image.")

    # --- 2) Compute Sobel gradients Gx and Gy ---
    # cv2.Sobel outputs a larger depth (int16 or float64), so we keep it signed
    Gx = cv2.Sobel(img, cv2.CV_64F, 1, 0, ksize=3)  # horizontal derivative
    Gy = cv2.Sobel(img, cv2.CV_64F, 0, 1, ksize=3)  # vertical derivative

    # --- 3) Sum abs gradients over all pixels ---
    abs_sum = np.sum(np.abs(Gx) + np.abs(Gy))

    # --- 4) Normalize by (max_pixel_value * total_pixels) ---
    max_val = 255  # since 8-bit image
    total_pixels = 256 * 256
    normalized = abs_sum / (2*max_val * total_pixels)

    return normalized

# --- Example usage ---
if __name__ == "__main__":
    img_path = "C:\\Users\\DELL\\Desktop\\PE1\\SobelEdgeDetection\\Dataset\\4.2.07.tiff"
    edge_param = compute_edge_param(img_path)
    print(f"Edge parameter: {edge_param:.6f}")
