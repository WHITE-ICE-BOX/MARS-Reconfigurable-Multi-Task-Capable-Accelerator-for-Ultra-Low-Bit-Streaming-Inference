# -----------------------------------------------------------------------------
# run_sim_top_baseline.tcl
#
# Open the FINN stitched project, add tb_top_baseline.sv as a simulation
# source, and launch behavioral simulation.  Report is printed to the Vivado
# log; images.hex / labels.hex must live in the simulation run dir.
#
# Usage (from mvau_adapter/golden/):
#   vivado -mode batch -source run_sim_top_baseline.tcl
# -----------------------------------------------------------------------------

set script_dir  [file normalize [file dirname [info script]]]
# default = original baseline tree; override with env STITCH_PROJ to point at
# the adapter-IP build (same top-level port signature, internals swapped)
if {[info exists ::env(STITCH_PROJ)]} {
  set stitch_proj $::env(STITCH_PROJ)
} else {
  set stitch_proj "/home/barkie1/mvau_pipeline/finn/finn_pipeline/vivado_stitch_proj_hv26s5y4/finn_vivado_stitch_proj.xpr"
}
puts "stitch_proj = $stitch_proj"

if {![file exists $stitch_proj]} {
  puts "ERROR: stitch project not found: $stitch_proj"
  exit 1
}

open_project $stitch_proj

# ensure sim_1 exists
if {[lsearch -exact [get_filesets -quiet] sim_1] < 0} {
  create_fileset -simset sim_1
}

# Remove any previous tb_top_* to avoid conflicts
foreach f [get_files -of [get_filesets sim_1] -quiet "tb_top_*.sv"] {
  remove_files -fileset sim_1 $f
}

add_files -fileset sim_1 [file join $script_dir tb_top_baseline.sv]
set_property file_type SystemVerilog [get_files -of [get_filesets sim_1] tb_top_baseline.sv]
set_property top tb_top_baseline [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

# allow plus-arg / macro override, e.g. pass NUM_IMAGES=100
if {[info exists ::env(NUM_IMAGES)]} {
  set n $::env(NUM_IMAGES)
  puts "overriding NUM_IMAGES = $n"
  set_property verilog_define [list NUM_IMAGES=$n] [get_filesets sim_1]
  set_property -name {xsim.compile.xvlog.more_options} \
    -value "--define NUM_IMAGES=$n" -objects [get_filesets sim_1]
}

# copy/reference hex files so $readmemh finds them in sim run dir
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

# unlimited run — the TB calls $finish itself
set_property -name {xsim.simulate.runtime} -value {-all} -objects [get_filesets sim_1]

# Disable waveform dumping + debug — cut xsim runtime by >10x on big designs.
set_property -name {xsim.elaborate.debug_level} -value {off} -objects [get_filesets sim_1]
set_property -name {xsim.elaborate.debug} -value {off} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.log_all_signals} -value {false} -objects [get_filesets sim_1]
set_property -name {xsim.elaborate.xelab.more_options} -value {--debug off} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.xsim.more_options} -value {-nolog -wdb ""} -objects [get_filesets sim_1]

launch_simulation -simset sim_1 -mode behavioral
run all

close_sim
close_project
