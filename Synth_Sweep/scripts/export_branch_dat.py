#!/usr/bin/env python3
"""
Export per-branch adapter .dat files for the multi-branch (M=2/3/4) RTL sim.

Source checkpoints: SVHN deployed-geometry (v1v2: 1x1 down / center-pixel,
sign act, scalar alpha, Cin/4 hidden) multi-branch RC checkpoints fetched from
the 4090 (Transfer_v7_v1v2_M{2,3,4}_rc_e200, accs 77.16/78.77/79.81 = thesis
deployed SVHN numbers).

Quantisation math is copied 1:1 from
~/mvau_pipeline_runtime_3ds_pe1/scripts/gen_3ds_cfg.py (the deployment
exporter), only the state-dict keys change:
    adapters.{site}.down.weight  ->  adapters.{site}.branches.{m}.down.weight  etc.

Output (per M, per site, per branch):
  sw/branch_dat/m{M}/mvau{n}/rom_rc_load_b{m}.dat      HIDDEN lines, 4-hex (int16)
  sw/branch_dat/m{M}/mvau{n}/rom_down_load_b{m}.dat    IN_CHUNKS lines, HIDDEN*SIMD-bit hex
  sw/branch_dat/m{M}/mvau{n}/rom_up_load_b{m}.dat      OUT_CH lines, UP_WIDTH-bit hex
  sw/branch_dat/m{M}/mvau{n}/contrib_lut_load_b{m}.dat 256 lines, 8-hex (int32)
Shared per site (from the same checkpoint's BN):
  sw/branch_dat/m{M}/mvau{n}/thresh_load.dat           OUT_CH lines, 8-hex (int32 Q8)
  sw/branch_dat/m{M}/mvau{n}/sign_load.dat             OUT_CH lines, single bit
"""
import os
import numpy as np
import torch

ROOT = "mvau_multibranch_synth"
CKPTS = {
    1: f"{ROOT}/sw/checkpoints/SVHN_v1v2_M1_rc_best.tar",
    2: f"{ROOT}/sw/checkpoints/SVHN_v1v2_M2_rc_best.tar",
    3: f"{ROOT}/sw/checkpoints/SVHN_v1v2_M3_rc_best.tar",
    4: f"{ROOT}/sw/checkpoints/SVHN_v1v2_M4_rc_best.tar",
}
OUT_BASE = f"{ROOT}/sw/branch_dat"

MVAU_CFG = {
    1: dict(IN_CH=64,  OUT_CH=64,  HIDDEN=16, UP_WIDTH=32),
    2: dict(IN_CH=64,  OUT_CH=128, HIDDEN=16, UP_WIDTH=32),
    3: dict(IN_CH=128, OUT_CH=128, HIDDEN=32, UP_WIDTH=32),
    4: dict(IN_CH=128, OUT_CH=256, HIDDEN=32, UP_WIDTH=32),
    5: dict(IN_CH=256, OUT_CH=256, HIDDEN=64, UP_WIDTH=64),
}
SIMD = 32
BN_IDX = {1: 5, 2: 9, 3: 12, 4: 16, 5: 19}
PE_TP = {1: 32, 2: 16, 3: 16, 4: 4, 5: 1}   # throughput-build adapter PE


def binarize(w):
    return (w >= 0).to(torch.uint8)


def pack_bits(bits, nbits):
    val = 0
    for i in range(nbits):
        if bits[i]:
            val |= (1 << i)
    return val


def quantize_bias_to_int16(bias_t, IN_CH):
    # same as gen_3ds_cfg.py: rc = floor(bias/2 - IN_CH/2)
    b = bias_t.to(torch.float64).numpy()
    rc = np.floor(b / 2.0 - IN_CH / 2.0).astype(np.int32)
    return np.clip(rc, -32768, 32767).astype(np.int16)


def gen_branch(sd, site, m):
    cfg = MVAU_CFG[site]
    IN_CH, OUT_CH = cfg["IN_CH"], cfg["OUT_CH"]
    HIDDEN, UP_WIDTH = cfg["HIDDEN"], cfg["UP_WIDTH"]
    IN_CHUNKS = IN_CH // SIMD

    pfx = f"adapters.{site}.branches.{m}"
    if f"{pfx}.down.weight" not in sd:
        # M=1 checkpoints store the single branch without the .branches. level
        assert m == 0, f"missing {pfx} for m={m}"
        pfx = f"adapters.{site}"
    down_w = sd[f"{pfx}.down.weight"]   # (HIDDEN, IN_CH, 1, 1)
    down_b = sd[f"{pfx}.down.bias"]     # (HIDDEN,)
    up_w   = sd[f"{pfx}.up.weight"]     # (OUT_CH, HIDDEN, 1, 1)
    alpha  = float(sd[f"{pfx}.alpha"])

    rc = quantize_bias_to_int16(down_b, IN_CH)

    rom_down = np.zeros((IN_CHUNKS, HIDDEN), dtype=np.uint32)
    for c in range(IN_CHUNKS):
        for h in range(HIDDEN):
            bits = binarize(down_w[h, c * SIMD:(c + 1) * SIMD, 0, 0])
            rom_down[c, h] = pack_bits(bits.tolist(), SIMD)

    rom_up = np.zeros((OUT_CH,), dtype=np.uint64)
    for oc in range(OUT_CH):
        bits = binarize(up_w[oc, :, 0, 0])
        padded = list(bits) + [0] * (UP_WIDTH - HIDDEN)
        rom_up[oc] = pack_bits(padded, UP_WIDTH)

    alpha_q8 = int(round(alpha * 256))
    OFFSET = UP_WIDTH - HIDDEN // 2
    contrib = np.zeros((256,), dtype=np.int64)
    for p in range(256):
        contrib[p] = (p - OFFSET) * alpha_q8
    contrib = np.clip(contrib, -(2**31), 2**31 - 1).astype(np.int32)
    return dict(rc=rc, rom_down=rom_down, rom_up=rom_up, contrib=contrib,
                alpha=alpha, HIDDEN=HIDDEN, IN_CHUNKS=IN_CHUNKS,
                OUT_CH=OUT_CH, UP_WIDTH=UP_WIDTH, IN_CH=IN_CH)


def gen_thresh_sign(sd, site):
    # copied 1:1 from gen_3ds_cfg.py gen_mvau_thresh_sign
    cfg = MVAU_CFG[site]
    OUT_CH, IN_CH = cfg["OUT_CH"], cfg["IN_CH"]
    K_TOTAL = 9 * IN_CH
    bn = BN_IDX[site]
    rm = sd[f"conv_features.{bn}.running_mean"].numpy()
    rv = sd[f"conv_features.{bn}.running_var"].numpy()
    gm = sd[f"conv_features.{bn}.weight"].numpy()
    bt = sd[f"conv_features.{bn}.bias"].numpy()
    eps = 1e-4
    sqrt_rv = np.sqrt(rv + eps)
    sign = (gm < 0).astype(np.uint8)
    t_bip = rm - bt * sqrt_rv / gm
    thr_pop = (K_TOTAL + t_bip) / 2
    thr_q8 = np.round(thr_pop * 256).astype(np.int64)
    for oc in range(OUT_CH):
        if sign[oc]:
            thr_q8[oc] = K_TOTAL * 256 - thr_q8[oc]
    thr_q8 = np.clip(thr_q8, -(2**31), 2**31 - 1).astype(np.int32)
    return thr_q8, sign


def w16(v):
    return f"{np.uint16(np.int16(v)):04x}"


def w32(v):
    return f"{np.uint32(np.int32(v)):08x}"


def main():
    for M, ck_path in CKPTS.items():
        ck = torch.load(ck_path, map_location="cpu", weights_only=False)
        sd = ck["state_dict"] if "state_dict" in ck else ck
        for site in range(1, 6):
            cfg = MVAU_CFG[site]
            d = os.path.join(OUT_BASE, f"m{M}", f"mvau{site}")
            os.makedirs(d, exist_ok=True)
            for m in range(M):
                br = gen_branch(sd, site, m)
                with open(f"{d}/rom_rc_load_b{m}.dat", "w") as f:
                    f.write("\n".join(w16(v) for v in br["rc"]) + "\n")
                hexw = cfg["HIDDEN"] * SIMD // 4
                with open(f"{d}/rom_down_load_b{m}.dat", "w") as f:
                    for c in range(br["IN_CHUNKS"]):
                        val = 0
                        for h in range(cfg["HIDDEN"]):
                            val |= int(br["rom_down"][c, h]) << (h * SIMD)
                        f.write(f"{val:0{hexw}x}\n")
                upw = cfg["UP_WIDTH"] // 4
                with open(f"{d}/rom_up_load_b{m}.dat", "w") as f:
                    for oc in range(cfg["OUT_CH"]):
                        f.write(f"{int(br['rom_up'][oc]):0{upw}x}\n")
                # wide-row format for the throughput (PE-parallel) adapters:
                # row s = concat over lanes p of the 32-bit up word of ch s*PE+p
                pe = PE_TP[site]
                if pe > 1:
                    steps = cfg["OUT_CH"] // pe
                    with open(f"{d}/rom_up_wide_b{m}.dat", "w") as f:
                        for s_ in range(steps):
                            val = 0
                            for p in range(pe):
                                val |= int(br["rom_up"][s_ * pe + p]) << (32 * p)
                            f.write(f"{val:0{pe*8}x}\n")
                with open(f"{d}/contrib_lut_load_b{m}.dat", "w") as f:
                    f.write("\n".join(w32(v) for v in br["contrib"]) + "\n")
                # baked alpha for the throughput adder's constant multiply
                with open(f"{d}/alpha_q8_b{m}.txt", "w") as f:
                    f.write(str(int(round(br["alpha"] * 256))) + "\n")
                print(f"M={M} mvau{site} b{m}: alpha={br['alpha']:+.4f} "
                      f"alpha_q8={int(round(br['alpha']*256)):+d}")
            thr, sg = gen_thresh_sign(sd, site)
            with open(f"{d}/thresh_load.dat", "w") as f:
                f.write("\n".join(w32(v) for v in thr) + "\n")
            with open(f"{d}/sign_load.dat", "w") as f:
                f.write("\n".join(str(int(v)) for v in sg) + "\n")
            # per-lane column files for the throughput per-PE adder
            # (lane p entry s = channel s*PE+p)
            pe = PE_TP[site]
            if pe > 1:
                steps = cfg["OUT_CH"] // pe
                for p in range(pe):
                    with open(f"{d}/thresh_lane{p}.dat", "w") as f:
                        f.write("\n".join(w32(thr[s_ * pe + p]) for s_ in range(steps)) + "\n")
                    with open(f"{d}/sign_lane{p}.dat", "w") as f:
                        f.write("\n".join(str(int(sg[s_ * pe + p])) for s_ in range(steps)) + "\n")
    print("EXPORT DONE ->", OUT_BASE)


if __name__ == "__main__":
    main()
