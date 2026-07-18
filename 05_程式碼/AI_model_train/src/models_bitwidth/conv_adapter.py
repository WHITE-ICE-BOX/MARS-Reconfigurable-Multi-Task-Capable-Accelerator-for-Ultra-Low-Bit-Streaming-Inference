# ===========================================================================
# [交接導向註解]
# 單一 Conv-Adapter 定義：down-projection -> sign(二值化) -> up-projection，
# 並含 RC(Residual Correction = down-conv 的 Int8 bias)。對應硬體 RTL/adapter/。
# ===========================================================================

"""
v3 Conv-Adapter: aligned to user's previously-working non-brevitas implementation.

Differences from the original models.CNV.QuantAdapter / MultiBranchAdapter (v1/v2):
  1. Down conv kernel: 1x1 -> 3x3 (padding=0) for spatial filtering
  2. Activation: QuantIdentity (CommonActQuant signed) -> make_act rule:
       - 1-bit  -> QuantIdentity binary signed (sign function, same as backbone 1-bit act)
       - >=2-bit -> QuantReLU (unsigned), matches working-code behaviour
  3. alpha: scalar per-branch -> per-channel R^{C_out} learnable (init=ones)
  4. Single-branch (no num_branches loop). The `MultiBranchAdapter` wrapper is no longer used.

Spatial alignment with the official CNV backbone:
  Backbone uses 3x3 QuantConv2d with padding=0 (shrinks H,W by 2 per layer).
  Adapter 3x3 down also uses padding=0 -> output spatial size matches backbone exactly.
  No crop hack needed in CNV_param.forward.

Hardware note (FPGA / FINN): the 3x3 down here is NOT FPGA-deployable on the existing
1x1-tuned pipeline. This version is a software-side reference matching the user's
non-brevitas working code. v1/v2 (1x1 down) remains the deployable path.
"""

import os
import sys

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
PROJ_ROOT = os.path.abspath(os.path.join(THIS_DIR, '..', '..'))
if PROJ_ROOT not in sys.path:
    sys.path.insert(0, PROJ_ROOT)

import torch
import torch.nn as nn
from brevitas.nn import QuantConv2d, QuantIdentity, QuantReLU
from brevitas.quant.solver import BiasQuantSolver

from models.common import CommonActQuant, CommonQuant, CommonWeightQuant


class Int8Bias(CommonQuant, BiasQuantSolver):
    """Custom 8-bit bias quantizer (matches models/CNV.py).

    Brevitas built-in Int8Bias has requires_input_scale=True, which fails when
    the upstream activation isn't a QuantTensor (e.g., after plain MaxPool2d).
    This variant has its own scaling so it works regardless of input.
    """
    bit_width = 8
    requires_input_scale = False
    requires_weight_scale = False
    scaling_const = 1.0


def _adapter_act(bit_width, act_mode='relu'):
    """Adapter-internal activation.

    act_mode='relu'   (v3): 1-bit -> binary signed; >=2-bit -> QuantReLU (unsigned)
    act_mode='signed' (v4): all bits -> QuantIdentity + CommonActQuant signed (matches v1/v2)
    """
    if act_mode == 'signed':
        return QuantIdentity(act_quant=CommonActQuant, bit_width=bit_width)
    if bit_width == 1:
        return QuantIdentity(act_quant=CommonActQuant, bit_width=1)
    return QuantReLU(bit_width=bit_width)


class QuantConvAdapter(nn.Module):
    """Conv-Adapter with selectable kernel / activation / alpha mode.

    v3: kernel_size=3 or 1, act_mode='relu',   alpha_mode='per_channel'
    v4: kernel_size=3,      act_mode='signed', alpha_mode='scalar'   (v2 design + 3x3 down)
    """

    def __init__(self, in_channels, out_channels, bit_width, reduction=4,
                 kernel_size=3, act_mode='relu', alpha_mode='per_channel',
                 use_bias=False, mid_basis='out'):
        super().__init__()
        self.kernel_size = kernel_size
        self.alpha_mode = alpha_mode
        self.use_bias = use_bias
        self.mid_basis = mid_basis
        # mid_basis='out' (default, v3-v6): mid = out_ch // reduction
        # mid_basis='in'  (v1/v2 / HW-friendly): mid = in_ch // reduction
        basis_ch = in_channels if mid_basis == 'in' else out_channels
        mid_channels = max(1, basis_ch // reduction)

        # down-projection（降維卷積）。對應硬體 RTL/adapter 的 down ROM。
        # bias=use_bias 時的這個 Int8 bias 就是 RC(Residual Correction)；
        # 硬體上不另做加法，而是吸收進 accumulator 的 reset 初值（零成本）。
        self.down = QuantConv2d(
            in_channels=in_channels,
            out_channels=mid_channels,
            kernel_size=kernel_size,
            padding=0,
            bias=use_bias,
            bias_quant=(Int8Bias if use_bias else None),   # RC bias 量化器
            weight_quant=CommonWeightQuant,
            weight_bit_width=bit_width,
        )
        # 中間 activation：1-bit 時為 sign（與 backbone 二值 act 一致）→ 硬體 Sign Extract。
        self.act = _adapter_act(bit_width, act_mode=act_mode)
        # up-projection（升回 out_channels），1x1。對應硬體 up ROM。
        self.up = QuantConv2d(
            in_channels=mid_channels,
            out_channels=out_channels,
            kernel_size=1,
            padding=0,
            bias=False,
            weight_quant=CommonWeightQuant,
            weight_bit_width=bit_width,
        )
        # alpha：把 adapter 貢獻量做縮放。scalar=部署版(deployed)；per-channel=accuracy-best。
        # 硬體以合成期預算的 contribution LUT 實現（Stream_Adder_Threshold），零 DSP。
        if alpha_mode == 'scalar':
            self.alpha = nn.Parameter(torch.tensor(1.0))
        else:
            self.alpha = nn.Parameter(torch.ones(1, out_channels, 1, 1))

    def forward(self, x):
        # 完整 adapter 路徑（對應硬體 4-stage pipeline）：
        #   down(x)  → S0/S1/S2/S3：讀ROM→XNOR→popcount→accumulate(+RC)
        #   act(...) → Sign Extract（二值 hidden activation）
        #   up(...)  → up-projection
        #   * alpha  → contribution 縮放
        delta = self.alpha * self.up(self.act(self.down(x)))
        # Spatial alignment with backbone (3x3 padding=0 -> H-2, W-2):
        #   kernel=3: down already shrinks 2 px -> match
        #   kernel=1: down preserves H,W -> crop center 1px on each side
        if self.kernel_size == 1:
            delta = delta[:, :, 1:-1, 1:-1]
        return delta
