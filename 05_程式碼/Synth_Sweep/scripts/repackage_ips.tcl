# repackage_ips.tcl -- re-package the 5 adapter IPs of one variant dir from
# its (multi-branch) ip/src sources. Adapted 1:1 from the proven
# rebuild_after_lut_fix.tcl STEP 1.
# Usage: vivado -mode batch -source repackage_ips.tcl -tclargs <variant_dir>
set VAR_DIR [lindex $argv 0]
set IP_DIR  ${VAR_DIR}/mvau_adapter_ip
set PART    xc7z020clg400-1

foreach mvau_id {1 2 3 4 5} {
    set top_mod "MVAU${mvau_id}_Super_Wrapper"
    puts "Re-packaging mvau${mvau_id} (top=${top_mod})..."
    set ip_root ${IP_DIR}/mvau${mvau_id}/ip

    set tmp_proj ${VAR_DIR}/_tmp_mvau${mvau_id}_pkg
    file delete -force ${tmp_proj}
    create_project tmp_mvau${mvau_id}_pkg ${tmp_proj} -part ${PART} -force

    add_files [glob ${ip_root}/src/*.v]
    set_property top ${top_mod} [current_fileset]
    update_compile_order -fileset sources_1

    ipx::package_project \
        -root_dir   ${ip_root} \
        -vendor     user.org \
        -library    user \
        -taxonomy   /UserIP \
        -import_files \
        -set_current true \
        -force

    set core [ipx::current_core]
    set_property name         "mvau${mvau_id}_adapter" $core
    set_property display_name "MVAU${mvau_id} Adapter" $core
    set_property version      1.0 $core

    foreach bus [ipx::get_bus_interfaces -of_objects $core] {
        set bus_name [get_property NAME $bus]
        if {$bus_name ne "ap_clk" && $bus_name ne "ap_rst_n"} {
            catch {ipx::associate_bus_interfaces -busif $bus_name -clock ap_clk $core}
        }
    }
    catch {
        set clk_if [ipx::get_bus_interfaces ap_clk -of_objects $core]
        if {[llength $clk_if] > 0} {
            set p [ipx::add_bus_parameter ASSOCIATED_RESET $clk_if]
            set_property value ap_rst_n $p
        }
    }

    ipx::create_xgui_files $core
    ipx::update_checksums  $core
    ipx::save_core         $core

    close_project
    file delete -force ${tmp_proj}
    puts "  -> mvau${mvau_id} IP re-packaged"
}
puts "ALL IPS REPACKAGED for ${VAR_DIR}"
exit 0
