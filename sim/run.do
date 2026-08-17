.main clear

vdel -all
vlib work

vlog rtl/axi_memory.v
vlog rtl/axi4.v

vlog tb/shared/axi4_if.sv

vlog tb/read/axi4_read_transaction.sv

vlog tb/write/axi4_write_transaction.sv

vlog tb/shared/axi4_reference_model.sv

vlog tb/read/axi4_read_generator.sv
vlog tb/read/axi4_read_driver.sv
vlog tb/read/axi4_read_monitor.sv
vlog tb/read/axi4_read_scoreboard.sv

vlog tb/write/axi4_backdoor_base.sv
vlog tb/write/axi4_write_generator.sv
vlog tb/write/axi4_write_driver.sv
vlog tb/write/axi4_write_monitor.sv
vlog tb/write/axi4_write_golden_model.sv
vlog tb/write/axi4_write_scoreboard.sv
vlog tb/write/axi4_write_coverage.sv

vlog tb/env/axi4_env.sv
vlog tb/top/axi4_tb_top.sv

vsim -voptargs=+acc work.tb_top -l Main.log

run -all