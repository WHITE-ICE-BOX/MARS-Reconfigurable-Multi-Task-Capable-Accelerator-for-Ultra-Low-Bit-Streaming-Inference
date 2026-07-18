# place_attempt.tcl -- open an existing variant zynq project (synth done),
# run opt + best-effort place, dump placed utilization (occupied slices) or the
# placer's overutilization verdict.
# Usage: vivado -mode batch -source place_attempt.tcl -tclargs <variant_dir>
set VAR [lindex $argv 0]

open_project ${VAR}/zynq/finn_zynq_link.xpr
open_run synth_1
file mkdir ${VAR}/reports_top

if {[catch {opt_design -directive Explore} err]} {
    puts "OPT_DESIGN FAILED: $err"
    close_project
    exit 1
}
report_utilization -file ${VAR}/reports_top/utilization_opt.rpt
report_utilization -hierarchical -hierarchical_depth 4 -file ${VAR}/reports_top/utilization_opt_hier.rpt
report_power       -file ${VAR}/reports_top/power_opt.rpt

if {![catch {place_design -directive Explore} perr]} {
    report_utilization -file ${VAR}/reports_top/utilization_placed.rpt
    report_utilization -hierarchical -hierarchical_depth 4 -file ${VAR}/reports_top/utilization_placed_hier.rpt
    report_power       -file ${VAR}/reports_top/power_placed.rpt
    puts "PLACE OK"
} else {
    set fp [open ${VAR}/reports_top/place_failed.txt w]
    puts $fp $perr
    close $fp
    puts "PLACE_DESIGN FAILED: $perr"
}
close_project
exit 0
