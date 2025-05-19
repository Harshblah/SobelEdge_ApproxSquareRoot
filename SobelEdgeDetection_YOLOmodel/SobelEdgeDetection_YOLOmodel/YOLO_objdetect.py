import sys
import os
import torch
import cv2
import numpy as np

# === 1. Load Image ===
img_path = "C:\\Users\\DELL\\Desktop\\PE1\\Dataset\\deer.tiff"
img_bgr = cv2.imread(img_path)
if img_bgr is None:
    print(f"Error: cannot load image '{img_path}'")
    sys.exit(1)

gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
h, w = gray.shape

# === 2. Prepare Output Directory ===
out_dir = 'coe_outputs'
os.makedirs(out_dir, exist_ok=True)

# === 3. YOLOv5 Detection ===
model = torch.hub.load('ultralytics/yolov5', 'yolov5s', pretrained=True, trust_repo=True)
results = model(cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB))
boxes = results.xyxy[0].cpu().numpy()[:, :4].astype(int)

# === 4. Expand Bounding Boxes ===
pad = 5
expanded = []
for (x1, y1, x2, y2) in boxes:
    ex1 = max(0, x1 - pad)
    ey1 = max(0, y1 - pad)
    ex2 = min(w, x2 + pad)
    ey2 = min(h, y2 + pad)
    expanded.append((ex1, ey1, ex2, ey2))

if not expanded:
    print("No objects detected; nothing to do.")
    sys.exit(0)

# === 5. Pick the largest box ===
areas = [ (ex2-ex1)*(ey2-ey1) for ex1,ey1,ex2,ey2 in expanded ]
idx_max = int(np.argmax(areas))
ex1, ey1, ex2, ey2 = expanded[idx_max]
box_w, box_h = ex2 - ex1, ey2 - ey1

# === 6. Print largest box info ===
corners = {
    'Top-Left':     (ex1, ey1),
    'Top-Right':    (ex2, ey1),
    'Bottom-Right': (ex2, ey2),
    'Bottom-Left':  (ex1, ey2),
}
print(f"Largest Box (idx {idx_max}): W x H = {box_w} x {box_h}")
for label,(x,y) in corners.items():
    print(f"  {label}: ({x}, {y})")

# === 7. COE for Largest Box ===
roi = gray[ey1:ey2, ex1:ex2]
flat = roi.flatten().astype(int)
coe_path_box = os.path.join(out_dir, 'box_largest.coe')
with open(coe_path_box, 'w') as f:
    f.write('memory_initialization_radix=10;\n')
    f.write('memory_initialization_vector=\n')
    for k, val in enumerate(flat):
        sep = ',' if k < flat.size - 1 else ';'
        f.write(f"{val}{sep}\n")
print(f"Generated COE for largest box: {coe_path_box}")

# === 8. COE for Full Image with Largest Box Masked ===
masked = gray.copy()
masked[ey1:ey2, ex1:ex2] = 0
full_flat = masked.flatten().astype(int)
coe_path_full = os.path.join(out_dir, 'full_masked.coe')
with open(coe_path_full, 'w') as f:
    f.write('memory_initialization_radix=10;\n')
    f.write('memory_initialization_vector=\n')
    for k, val in enumerate(full_flat):
        sep = ',' if k < full_flat.size - 1 else ';'
        f.write(f"{val}{sep}\n")
print(f"Generated masked full-image COE: {coe_path_full}")

# === 9. Overlay Largest Box ===
overlay = img_bgr.copy()
cv2.rectangle(overlay, (ex1, ey1), (ex2, ey2), color=(0, 255, 0), thickness=2)

grid_path = os.path.join(out_dir, 'largest_box_overlay.jpg')
cv2.imwrite(grid_path, overlay)
print(f"Saved overlay with largest box: {grid_path}")
