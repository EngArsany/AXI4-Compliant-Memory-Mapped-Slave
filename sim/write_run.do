.main clear

vdel -all
vlib work

vlog rtl/axi_memory.v
vlog rtl/axi4.v

vlog tb/write/axi4_write_if.sv
vlog tb/write/axi4_write_pkg.sv

vlog tb/tb_top.sv

vsim -voptargs=+acc work.tb_top -l Main.log

add wave *;
run -all