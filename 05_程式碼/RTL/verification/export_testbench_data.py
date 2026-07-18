#!/usr/bin/env python3
"""
Export N test images + labels into $readmemh-compatible hex files
for the top-level RTL testbench (tb_top_baseline / tb_top_adapter).

Input can be either:
  * an .npy pair produced by validate_test.py on the Zynq side
    (shape (N,32,32,3) uint8 NHWC, labels shape (N,) int)
  * a class-folder dataset laid out like cifar10_finn_dataset/
      0/*.png  1/*.png  ...  9/*.png
    (same layout load_custom_data() in validate_test.py expects)

Output:
  images.hex   one hex byte per line, NHWC raster (N*32*32*3 lines)
  labels.hex   one hex byte per line (N lines)
"""
import argparse
import glob
import os

import numpy as np
from PIL import Image


def load_from_folder(root, per_class_cap=None):
    """Interleave classes so an early truncation still covers all labels."""
    classes = []
    for cls in sorted(os.listdir(root)):
        cls_dir = os.path.join(root, cls)
        if not os.path.isdir(cls_dir):
            continue
        try:
            label = int(cls)
        except ValueError:
            continue
        files = sorted(glob.glob(os.path.join(cls_dir, "*.png")) +
                       glob.glob(os.path.join(cls_dir, "*.jpg")))
        if per_class_cap is not None:
            files = files[:per_class_cap]
        classes.append((label, files))

    imgs, lbls = [], []
    max_len = max((len(f) for _, f in classes), default=0)
    for i in range(max_len):
        for label, files in classes:
            if i < len(files):
                try:
                    img = Image.open(files[i]).convert("RGB").resize((32, 32))
                    imgs.append(np.array(img, dtype=np.uint8))
                    lbls.append(label)
                except Exception as e:
                    print(f"skip {files[i]}: {e}")
    return np.stack(imgs), np.asarray(lbls, dtype=np.uint8)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--images_npy")
    ap.add_argument("--labels_npy")
    ap.add_argument("--dataset_dir",
                    help="class-folder root (fallback when no npy given)")
    ap.add_argument("--n", type=int, default=1000)
    ap.add_argument("--out_dir", default=".")
    ap.add_argument("--shuffle", action="store_true",
                    help="stratified shuffle so N images cover all classes")
    ap.add_argument("--seed", type=int, default=0)
    args = ap.parse_args()

    if args.images_npy and args.labels_npy:
        imgs = np.load(args.images_npy)
        lbls = np.load(args.labels_npy).astype(np.uint8)
        assert imgs.dtype == np.uint8 and imgs.shape[1:] == (32, 32, 3)
    elif args.dataset_dir:
        imgs, lbls = load_from_folder(args.dataset_dir)
    else:
        raise SystemExit("need --images_npy/--labels_npy or --dataset_dir")

    if args.shuffle:
        rng = np.random.default_rng(args.seed)
        idx = rng.permutation(len(imgs))
        imgs, lbls = imgs[idx], lbls[idx]

    N = min(args.n, len(imgs))
    imgs, lbls = imgs[:N], lbls[:N]

    os.makedirs(args.out_dir, exist_ok=True)
    img_path = os.path.join(args.out_dir, "images.hex")
    lbl_path = os.path.join(args.out_dir, "labels.hex")

    flat = imgs.reshape(-1)
    with open(img_path, "w") as f:
        f.write("\n".join(f"{b:02x}" for b in flat))
        f.write("\n")
    with open(lbl_path, "w") as f:
        f.write("\n".join(f"{b:02x}" for b in lbls))
        f.write("\n")

    print(f"wrote {img_path}  ({N} images, {flat.size} bytes)")
    print(f"wrote {lbl_path}  ({N} labels)")
    print(f"label histogram: {np.bincount(lbls, minlength=10).tolist()}")


if __name__ == "__main__":
    main()
