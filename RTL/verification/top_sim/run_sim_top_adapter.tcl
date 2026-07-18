# -----------------------------------------------------------------------------
# run_sim_top_adapter.tcl
#
# Open the FINN stitched project, register the patched top
# (StreamingDataflowPartition_1_Adapter.v) + adapter-fused MVAU5 sources, add
# tb_top_adapter.sv as a simulation source, and launch behavioral simulation.
#
# Prerequisite: run patch_stitch_adapter.py first to generate
#   StreamingDataflowPartition_1_Adapter.v
#
# Usage (from mvau_adapter/golden/):
#   vivado -mode batch -source run_sim_top_adapter.tcl
# -----------------------------------------------------------------------------

set script_dir    [file normalize [file dirname [info script]]]
set stitch_proj   "/home/barkie1/mvau_pipeline/finn/finn_pipeline_adapter/vivado_stitch_proj_hv26s5y4/finn_vivado_stitch_proj.xpr"
set adapter_dir   [file join $script_dir adapter_assets]
set patched_top   [file join $script_dir StreamingDataflowPartition_1_Adapter.v]

foreach f [list $stitch_proj $patched_top] {
  if {![file exists $f]} {
    puts "ERROR: required file not found: $f"
    exit 1
  }
}

open_project $stitch_proj

# ensure sim_1 exists
if {[lsearch -exact [get_filesets -quiet] sim_1] < 0} {
  create_fileset -simset sim_1
}

# Remove any previous tb_top_* + patched top to avoid duplicate defs
foreach f [get_files -of [get_filesets sim_1] -quiet "tb_top_*.sv"] {
  remove_files -fileset sim_1 $f
}
foreach f [get_files -of [get_filesets sim_1] -quiet "StreamingDataflowPartition_1_Adapter.v"] {
  remove_files -fileset sim_1 $f
}
foreach pat {MVAU?_Super_Wrapper.v Adapter_MVAU?.v Adapter_Generic.v
             Stream_Splitter.v Simple_FIFO.v Stream_Adder_Threshold_MVAU?.v} {
  foreach f [get_files -of [get_filesets sim_1] -quiet $pat] {
    remove_files -fileset sim_1 $f
  }
}

# Adapter branch RTL — staged by stage_adapter_ips.py
set adapter_srcs [list \
  [file join $adapter_dir Stream_Splitter.v] \
  [file join $adapter_dir Simple_FIFO.v] \
  [file join $adapter_dir Adapter_MVAU1.v] \
  [file join $adapter_dir Adapter_MVAU2.v] \
  [file join $adapter_dir Adapter_MVAU3.v] \
  [file join $adapter_dir Adapter_MVAU4.v] \
  [file join $adapter_dir Adapter_Generic.v] \
  [file join $adapter_dir Stream_Adder_Threshold_MVAU1.v] \
  [file join $adapter_dir Stream_Adder_Threshold_MVAU2.v] \
  [file join $adapter_dir Stream_Adder_Threshold_MVAU3.v] \
  [file join $adapter_dir Stream_Adder_Threshold_MVAU4.v] \
  [file join $adapter_dir Stream_Adder_Threshold_MVAU5.v] \
  [file join $adapter_dir MVAU1_Super_Wrapper.v] \
  [file join $adapter_dir MVAU2_Super_Wrapper.v] \
  [file join $adapter_dir MVAU3_Super_Wrapper.v] \
  [file join $adapter_dir MVAU4_Super_Wrapper.v] \
  [file join $adapter_dir MVAU5_Super_Wrapper.v] \
]
foreach s $adapter_srcs {
  if {![file exists $s]} {
    puts "ERROR: adapter source missing: $s"
    exit 1
  }
}

add_files -fileset sim_1 $patched_top
add_files -fileset sim_1 $adapter_srcs
add_files -fileset sim_1 [file join $script_dir tb_top_adapter.sv]
set_property file_type SystemVerilog [get_files -of [get_filesets sim_1] tb_top_adapter.sv]

set_property top tb_top_adapter [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

# hex inputs in the sim run dir
set sim_run_dir [get_property DIRECTORY [current_project]]/finn_vivado_stitch_proj.sim/sim_1/behav/xsim
file mkdir $sim_run_dir
foreach h {images.hex labels.hex} {
  set src [file join $script_dir $h]
  if {[file exists $src]} {
    file copy -force $src [file join $sim_run_dir $h]
    puts "copied $src -> $sim_run_dir/$h"
  } else {
    puts "WARNING: $src not found (run export_testbench_data.py first)"
  }
}

# allow plus-arg / macro override, e.g. NUM_IMAGES=100
if {[info exists ::env(NUM_IMAGES)]} {
  set n $::env(NUM_IMAGES)
  puts "overriding NUM_IMAGES = $n"
  set_property verilog_define [list NUM_IMAGES=$n] [get_filesets sim_1]
  set_property -name {xsim.compile.xvlog.more_options} \
    -value "--define NUM_IMAGES=$n" -objects [get_filesets sim_1]
}

set_property -name {xsim.simulate.runtime} -value {-all} -objects [get_filesets sim_1]

# debug off, no wdb — same speedup as baseline
set_property -name {xsim.elaborate.debug_level} -value {off} -objects [get_filesets sim_1]
set_property -name {xsim.elaborate.debug} -value {off} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.log_all_signals} -value {false} -objects [get_filesets sim_1]
set_property -name {xsim.elaborate.xelab.more_options} -value {--debug off} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.xsim.more_options} -value {-nolog -wdb ""} -objects [get_filesets sim_1]

launch_simulation -simset sim_1 -mode behavioral
run all

close_sim
close_project
