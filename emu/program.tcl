# program device
set bit_file {project/project.runs/impl_1/fpga_top.bit}
set probe_file {project/project.runs/impl_1/fpga_top.ltx}

open_hw
connect_hw_server
open_hw_target

set hw_device [get_hw_devices *xc7z020*]
current_hw_device $hw_device
refresh_hw_device $hw_device

set_property PROGRAM.FILE $bit_file $hw_device
set_property PROBES.FILE $probe_file $hw_device
set_property FULL_PROBES.FILE $probe_file $hw_device

program_hw_devices $hw_device
refresh_hw_device $hw_device

# configure VIO for low latency
# since there is no refresh, writing the VIO requires commit_hw_vio 
# and reading the VIO requires refresh_hw_vio
set vio_0_i [get_hw_vios -of_objects $hw_device -filter {CELL_NAME=~"vio_i/vio_0_i"}]
set_property CORE_REFRESH_RATE_MS 0 $vio_0_i

# set aliases to VIO probes
set emu_rst [get_hw_probes "vio_i/emu_rst" -of_objects $vio_0_i]
set rst_user [get_hw_probes "vio_i/rst_user" -of_objects $vio_0_i]
set number [get_hw_probes "vio_i/number" -of_objects $vio_0_i]

# configure VIO radix
set_property INPUT_VALUE_RADIX UNSIGNED $number