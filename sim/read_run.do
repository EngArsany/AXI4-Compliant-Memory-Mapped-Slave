.main clear

vdel -all
vlib work

vlog rtl/axi_memory.v
vlog rtl/axi4.v

vlog tb/shared/axi4_if.sv
vlog tb/read/axi4_read_transaction.sv
vlog tb/read/axi4_read_generator.sv
vlog tb/read/axi4_read_monitor.sv
vlog tb/read/axi4_read_scoreboard.sv

run -all