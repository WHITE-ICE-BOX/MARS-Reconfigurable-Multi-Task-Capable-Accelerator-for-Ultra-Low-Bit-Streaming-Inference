#!/usr/bin/env python3
"""
Generate RTL-accurate golden in/expected data for the multi-branch (M=2/3/4)
adapter sites, both build styles. Integer math copied 1:1 from the verified
M=1 golden generators:
  compact: ~/mvau_pipeline_runtime_3ds_pe1/mvau_adapter/regen_mvau_golden.py
  tp     : ~/mvau_pipeline_runtime/mvau_adapter/generate_mvau1234_golden.py
extended to M branches: adapter contribution = sum over branches of
contrib_lut_b[adp_pop_b]; thresh/sign shared. Site 5 uses the pol-XOR form.

Branch weights = real deployed-geometry SVHN M-branch checkpoints
(sw/branch_dat, exported by export_branch_dat.py). MVAU weights = the baked
memblock.dat each style's wstrm streams in simulation.
"""
import os
import random

ROOT = "mvau_multibranch_synth"
MEMBLOCK = {
    "compact": "mvau_pipeline_runtime_3ds_pe1/mvau_adapter/mvau{n}/data/memblock.dat",
    "tp":      "mvau_pipeline_runtime/mvau_adapter/mvau{n}/data/memblock.dat",
}
SITE = {
    1: dict(IN_CH=64,  OUT_CH=64,  HIDDEN=16, UPW=32, K=576,  pol=False),
    2: dict(IN_CH=64,  OUT_CH=128, HIDDEN=16, UPW=32, K=576,  pol=False),
    3: dict(IN_CH=128, OUT_CH=128, HIDDEN=32, UPW=32, K=1152, pol=False),
    4: dict(IN_CH=128, OUT_CH=256, HIDDEN=32, UPW=32, K=1152, pol=False),
    5: dict(IN_CH=256, OUT_CH=256, HIDDEN=64, UPW=64, K=2304, pol=True),
}
PE_TP = {1: 32, 2: 16, 3: 16, 4: 4, 5: 1}
OUTW_TP = {1: 32, 2: 16, 3: 16, 4: 8, 5: 8}
SIMD = 32
NUM_SAMPLES = 10


def load_hex(path):
    return [int(ln.strip(), 16) for ln in open(path) if ln.strip()]


def s16(x):
    return x - (1 << 16) if x & (1 << 15) else x


def s32(x):
    return x - (1 << 32) if x & (1 << 31) else x


def popcount(x):
    return bin(x).count("1")


def gen(style, M, n):
    cfg = SITE[n]
    IN_CH, OUT_CH, HIDDEN, UPW, K, pol = (cfg["IN_CH"], cfg["OUT_CH"],
                                          cfg["HIDDEN"], cfg["UPW"],
                                          cfg["K"], cfg["pol"])
    PE = 1 if style == "compact" else PE_TP[n]
    OUT_STEPS = OUT_CH // PE
    IN_CHUNKS = IN_CH // SIMD
    WIN_CYCLES = 9 * IN_CHUNKS
    WORDS_PER_STEP = K // SIMD          # = 9 * IN_CHUNKS
    CENTER_START = 4 * IN_CHUNKS
    upmask = (1 << UPW) - 1

    bd = os.path.join(ROOT, "sw", "branch_dat", f"m{M}", f"mvau{n}")
    memblock = load_hex(MEMBLOCK[style].format(n=n))
    assert len(memblock) == OUT_STEPS * WORDS_PER_STEP, \
        f"{style} mvau{n}: memblock {len(memblock)} != {OUT_STEPS*WORDS_PER_STEP}"

    thresh = [s32(v) for v in load_hex(os.path.join(bd, "thresh_load.dat"))]
    sign_l = load_hex(os.path.join(bd, "sign_load.dat"))
    assert len(thresh) == OUT_CH and len(sign_l) == OUT_CH

    branches = []
    for b in range(M):
        rc = [s16(v) for v in load_hex(os.path.join(bd, f"rom_rc_load_b{b}.dat"))]
        down_rows = load_hex(os.path.join(bd, f"rom_down_load_b{b}.dat"))
        up = load_hex(os.path.join(bd, f"rom_up_load_b{b}.dat"))
        contrib = [s32(v) for v in load_hex(os.path.join(bd, f"contrib_lut_load_b{b}.dat"))]
        assert len(rc) == HIDDEN and len(down_rows) == IN_CHUNKS
        assert len(up) == OUT_CH and len(contrib) == 256
        branches.append(dict(rc=rc, down=down_rows, up=up, contrib=contrib))

    # ---- deterministic random input ----
    random.seed(20260703 + 1000 * M + 10 * n + (0 if style == "compact" else 5))
    in_words = [random.getrandbits(32) for _ in range(NUM_SAMPLES * WIN_CYCLES)]

    outdir = os.path.join(ROOT, "sim_data", style, f"m{M}", f"mvau{n}")
    os.makedirs(outdir, exist_ok=True)
    with open(os.path.join(outdir, "in.dat"), "w") as f:
        for w in in_words:
            f.write(f"{w:08x}\n")

    # ---- expected output ----
    if PE == 1:
        hexw = None                      # 1-bit lines "0"/"1"
    else:
        hexw = OUTW_TP[n] // 4
    out_lines = []
    for img in range(NUM_SAMPLES):
        off = img * WIN_CYCLES
        window = in_words[off:off + WIN_CYCLES]
        center = window[CENTER_START:CENTER_START + IN_CHUNKS]

        # per-branch hidden activation + per-oc adapter pop
        hidden_acts = []
        for br in branches:
            acc = list(br["rc"])
            for c in range(IN_CHUNKS):
                row = br["down"][c]
                for h in range(HIDDEN):
                    wbits = (row >> (h * SIMD)) & 0xFFFFFFFF
                    acc[h] += popcount((~(center[c] ^ wbits)) & 0xFFFFFFFF)
            act = 0
            for h in range(HIDDEN):
                if acc[h] >= 0:
                    act |= (1 << h)
            hidden_acts.append(act)

        for s in range(OUT_STEPS):
            out_val = 0
            for p in range(PE):
                ch = s * PE + p
                # MVAU popcount
                mvau_pop = 0
                for w in range(WORDS_PER_STEP):
                    mem_word = memblock[s * WORDS_PER_STEP + w]
                    wbits = (mem_word >> (p * SIMD)) & 0xFFFFFFFF
                    mvau_pop += popcount((~(window[w] ^ wbits)) & 0xFFFFFFFF)
                # summed branch contributions
                csum = 0
                for b, br in enumerate(branches):
                    xnor_up = (~(hidden_acts[b] ^ br["up"][ch])) & upmask
                    csum += br["contrib"][popcount(xnor_up)]
                if not pol:
                    signed_c = -csum if sign_l[ch] else csum
                    total = (mvau_pop << 8) + signed_c
                    bit = 1 if total >= thresh[ch] else 0
                else:
                    adj = (K - mvau_pop) if sign_l[ch] else mvau_pop
                    total = (adj << 8) + csum
                    bit = (1 if total >= thresh[ch] else 0) ^ sign_l[ch]
                out_val |= (bit << p)
            if hexw is None:
                out_lines.append(f"{out_val:x}")
            else:
                out_lines.append(f"{out_val:0{hexw}x}")

    with open(os.path.join(outdir, "expected.dat"), "w") as f:
        f.write("\n".join(out_lines) + "\n")
    print(f"{style} m{M} mvau{n}: {len(in_words)} in words, {len(out_lines)} out beats")


def main():
    for style in ("compact", "tp"):
        for M in (1, 2, 3, 4):
            for n in range(1, 6):
                gen(style, M, n)
    print("GOLDEN DONE ->", os.path.join(ROOT, "sim_data"))


if __name__ == "__main__":
    main()
