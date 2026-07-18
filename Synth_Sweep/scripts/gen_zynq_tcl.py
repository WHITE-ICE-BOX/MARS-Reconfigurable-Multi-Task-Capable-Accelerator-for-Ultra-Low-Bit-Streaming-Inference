#!/usr/bin/env python3
"""
Generate a per-variant Zynq top-level build tcl (synthesis-only) adapted from
the proven ~/mvau_pipeline_runtime_3ds_pe1/vivado_zynq_proj/ip_config.tcl:
same top.bd (PS7 + smartconnect + interconnect + idma0 + partition + odma0,
NUM_AXILITE=3 with s_axilite_cfg on M02), same synth strategy
(Flow_PerfOptimized_high / AlternateRoutability / retiming), but the
StreamingDataflowPartition_1 IP comes from the variant's freshly exported
stitch IP and the variant's repackaged adapter IPs are added to the repo list.

Ends after synth_1 + linked-design reports (+ best-effort opt_design reports);
no implementation.

Usage: gen_zynq_tcl.py <variant_dir> <style: compact|tp>
"""
import re
import sys

VAR = sys.argv[1].rstrip("/")
STYLE = sys.argv[2]

FC = "/home/barkie1/thesis/finn/finn_cifar10"
FPA = "/home/barkie1/mvau_pipeline_runtime/finn/finn_pipeline_adapter"
DMA = {
    "compact": dict(
        idma=[f"{FC}/code_gen_ipgen_StreamingDataflowPartition_0_IODMA_hls_0_ro2p7i1_/project_StreamingDataflowPartition_0_IODMA_hls_0/sol1/impl/ip",
              f"{FC}/vivado_stitch_proj_28igu6ys/ip"],
        odma=[f"{FC}/code_gen_ipgen_StreamingDataflowPartition_2_IODMA_hls_0_l5chhp38/project_StreamingDataflowPartition_2_IODMA_hls_0/sol1/impl/ip",
              f"{FC}/vivado_stitch_proj_cpjiag0b/ip"],
    ),
    "tp": dict(
        idma=[f"{FPA}/code_gen_ipgen_StreamingDataflowPartition_0_IODMA_hls_0_vqifveuo/project_StreamingDataflowPartition_0_IODMA_hls_0/sol1/impl/ip",
              f"{FPA}/vivado_stitch_proj_y_fh1yul/ip"],
        odma=[f"{FPA}/code_gen_ipgen_StreamingDataflowPartition_2_IODMA_hls_0_nu56tw7u/project_StreamingDataflowPartition_2_IODMA_hls_0/sol1/impl/ip",
              f"{FPA}/vivado_stitch_proj_0re6vyby/ip"],
    ),
}[STYLE]

# resolve the variant stitch project's IP repo list ($PPRDIR-relative)
xpr = f"{VAR}/vivado_stitch_proj/finn_vivado_stitch_proj.xpr"
pprdir = f"{VAR}/vivado_stitch_proj"
repos = []
for m in re.finditer(r'Option Name="IPRepoPath" Val="([^"]+)"', open(xpr).read()):
    p = m.group(1).replace("$PPRDIR", pprdir)
    repos.append(p)
repos.append(f"{VAR}/vivado_stitch_proj/ip")

tcl = f"""#============================================================================
# auto-generated Zynq top synthesis for {VAR} ({STYLE})
#============================================================================
set FREQ_MHZ 100
set NUM_AXILITE 3
set NUM_AXIMM 2
set FPGA_PART xc7z020clg400-1
create_project finn_zynq_link ./ -part $FPGA_PART

set paths_prop [get_property BOARD_PART_REPO_PATHS [current_project]]
set paths_param [get_param board.repoPaths]
lappend paths_prop $::env(FINN_ROOT)/deps/board_files
lappend paths_param $::env(FINN_ROOT)/deps/board_files
set_property BOARD_PART_REPO_PATHS $paths_prop [current_project]
set_param board.repoPaths $paths_param
set_property board_part tul.com.tw:pynq-z2:part0:1.0 [current_project]

create_bd_design "top"
set zynq_ps_vlnv [get_property VLNV [get_ipdefs "xilinx.com:ip:processing_system7:*"]]
create_bd_cell -type ip -vlnv $zynq_ps_vlnv zynq_ps
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {{make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" }}  [get_bd_cells zynq_ps]
set_property -dict [list CONFIG.PCW_USE_S_AXI_HP0 {{1}}] [get_bd_cells zynq_ps]
set_property -dict [list CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ [expr int($FREQ_MHZ)]] [get_bd_cells zynq_ps]

set interconnect_vlnv [get_property VLNV [get_ipdefs -all "xilinx.com:ip:axi_interconnect:*" -filter design_tool_contexts=~*IPI*]]
set smartconnect_vlnv [get_property VLNV [get_ipdefs "xilinx.com:ip:smartconnect:*"]]
create_bd_cell -type ip -vlnv $interconnect_vlnv axi_interconnect_0
create_bd_cell -type ip -vlnv $smartconnect_vlnv smartconnect_0
set_property -dict [list CONFIG.NUM_SI $NUM_AXIMM] [get_bd_cells smartconnect_0]
set_property -dict [list CONFIG.NUM_MI $NUM_AXILITE] [get_bd_cells axi_interconnect_0]

set axi_peripheral_base 0x40000000
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins zynq_ps/M_AXI_GP0] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins smartconnect_0/M00_AXI] [get_bd_intf_pins zynq_ps/S_AXI_HP0]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {{ Clk {{/zynq_ps/FCLK_CLK0}} Freq {{}} Ref_Clk0 {{}} Ref_Clk1 {{}} Ref_Clk2 {{}}}}  [get_bd_pins axi_interconnect_0/ACLK]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {{ Clk {{/zynq_ps/FCLK_CLK0}} Freq {{}} Ref_Clk0 {{}} Ref_Clk1 {{}} Ref_Clk2 {{}}}}  [get_bd_pins axi_interconnect_0/S00_ACLK]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {{ Clk {{/zynq_ps/FCLK_CLK0}} Freq {{}} Ref_Clk0 {{}} Ref_Clk1 {{}} Ref_Clk2 {{}}}}  [get_bd_pins zynq_ps/S_AXI_HP0_ACLK]
connect_bd_net [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins smartconnect_0/aresetn]

proc assign_axi_addr_proc {{axi_intf_path}} {{
    global axi_peripheral_base
    set range [expr 2**[get_property CONFIG.ADDR_WIDTH [get_bd_intf_pins $axi_intf_path]]]
    set range [expr $range < 4096 ? 4096 : $range]
    set offset [expr ($axi_peripheral_base + ($range-1)) & ~($range-1)]
    assign_bd_address [get_bd_addr_segs $axi_intf_path/Reg*] -offset $offset -range $range
    set axi_peripheral_base [expr $offset + $range]
}}

# ---- idma (Partition 0) ----
set_property ip_repo_paths [concat [get_property ip_repo_paths [current_project]] [list \\
  {DMA["idma"][0]} \\
  {DMA["idma"][1]} \\
]] [current_project]
update_ip_catalog -rebuild -scan_changes
create_bd_cell -type ip -vlnv xilinx_finn:finn:StreamingDataflowPartition_0:1.0 idma0
connect_bd_intf_net [get_bd_intf_pins idma0/m_axi_gmem0] [get_bd_intf_pins smartconnect_0/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins idma0/s_axi_control_0] [get_bd_intf_pins axi_interconnect_0/M00_AXI]
assign_axi_addr_proc idma0/s_axi_control_0
connect_bd_net [get_bd_pins idma0/ap_clk] [get_bd_pins smartconnect_0/aclk]
connect_bd_net [get_bd_pins idma0/ap_rst_n] [get_bd_pins smartconnect_0/aresetn]

# ---- variant streaming partition (multi-branch adapter IPs included) ----
set_property ip_repo_paths [concat [get_property ip_repo_paths [current_project]] [list \\
""" + "".join(f"  {p} \\\n" for p in repos) + f"""]] [current_project]
update_ip_catalog -rebuild -scan_changes

create_bd_cell -type ip -vlnv xilinx_finn:finn:StreamingDataflowPartition_1:1.0 StreamingDataflowPartition_1
connect_bd_net [get_bd_pins StreamingDataflowPartition_1/ap_clk] [get_bd_pins smartconnect_0/aclk]
connect_bd_net [get_bd_pins StreamingDataflowPartition_1/ap_rst_n] [get_bd_pins smartconnect_0/aresetn]
connect_bd_intf_net [get_bd_intf_pins StreamingDataflowPartition_1/s_axis_0] [get_bd_intf_pins idma0/m_axis_0]

# ---- odma (Partition 2) ----
set_property ip_repo_paths [concat [get_property ip_repo_paths [current_project]] [list \\
  {DMA["odma"][0]} \\
  {DMA["odma"][1]} \\
]] [current_project]
update_ip_catalog -rebuild -scan_changes
create_bd_cell -type ip -vlnv xilinx_finn:finn:StreamingDataflowPartition_2:1.0 odma0
connect_bd_intf_net [get_bd_intf_pins odma0/m_axi_gmem0] [get_bd_intf_pins smartconnect_0/S01_AXI]
connect_bd_intf_net [get_bd_intf_pins odma0/s_axi_control_0] [get_bd_intf_pins axi_interconnect_0/M01_AXI]
assign_axi_addr_proc odma0/s_axi_control_0
connect_bd_net [get_bd_pins odma0/ap_clk] [get_bd_pins smartconnect_0/aclk]
connect_bd_net [get_bd_pins odma0/ap_rst_n] [get_bd_pins smartconnect_0/aresetn]
connect_bd_intf_net [get_bd_intf_pins odma0/s_axis_0] [get_bd_intf_pins StreamingDataflowPartition_1/m_axis_0]

# cfg_hub AXI-Lite on M02
connect_bd_intf_net [get_bd_intf_pins StreamingDataflowPartition_1/s_axilite_cfg] [get_bd_intf_pins axi_interconnect_0/M02_AXI]
assign_axi_addr_proc StreamingDataflowPartition_1/s_axilite_cfg

apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {{ Clk {{/zynq_ps/FCLK_CLK0}} }}  [get_bd_pins axi_interconnect_0/M*_ACLK]

save_bd_design
assign_bd_address
validate_bd_design

set_property SYNTH_CHECKPOINT_MODE "Hierarchical" [ get_files top.bd ]
make_wrapper -files [get_files top.bd] -import -fileset sources_1 -top

# same synthesis strategy as the deployed builds
set_property strategy Flow_PerfOptimized_high [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.DIRECTIVE AlternateRoutability [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.RETIMING true [get_runs synth_1]

launch_runs synth_1 -jobs 8
wait_on_run synth_1
set st [get_property STATUS [get_runs synth_1]]
puts "SYNTH STATUS: $st"
if {{$st ne "synth_design Complete!"}} {{ puts "ERROR: synthesis failed"; exit 1 }}

# linked post-synth design (resolves OOC checkpoints) -> real top-level numbers
open_run synth_1
file mkdir {VAR}/reports_top
report_utilization                 -file {VAR}/reports_top/utilization_synth.rpt
report_utilization -hierarchical -hierarchical_depth 4 -file {VAR}/reports_top/utilization_synth_hier.rpt
report_power                       -file {VAR}/reports_top/power_synth.rpt
report_timing_summary -max_paths 3 -file {VAR}/reports_top/timing_synth.rpt

puts "TOP REPORTS WRITTEN TO {VAR}/reports_top"
close_project
exit 0
"""

out = f"{VAR}/zynq/zynq_build.tcl"
import os
os.makedirs(f"{VAR}/zynq", exist_ok=True)
open(out, "w").write(tcl)
print(out)
