.main clear

vdel -all
vlib work

vlog rtl/axi_memory.v +cover -covercells
vlog rtl/axi4.v +cover -covercells

vlog tb/shared/axi4_if.sv +cover -covercells

vlog tb/read/axi4_read_transaction.sv +cover -covercells

vlog tb/write/axi4_write_transaction.sv +cover -covercells

vlog tb/shared/axi4_reference_model.sv +cover -covercells

vlog tb/read/axi4_read_generator.sv +cover -covercells
vlog tb/read/axi4_read_driver.sv +cover -covercells
vlog tb/read/axi4_read_monitor.sv +cover -covercells
vlog tb/read/axi4_read_scoreboard.sv +cover -covercells

vlog tb/write/axi4_backdoor_base.sv +cover -covercells
vlog tb/write/axi4_write_generator.sv +cover -covercells
vlog tb/write/axi4_write_driver.sv +cover -covercells
vlog tb/write/axi4_write_monitor.sv +cover -covercells
vlog tb/write/axi4_write_golden_model.sv +cover -covercells
vlog tb/write/axi4_write_scoreboard.sv +cover -covercells
vlog tb/write/axi4_write_coverage.sv +cover -covercells

vlog tb/env/axi4_env.sv +cover -covercells
vlog tb/top/axi4_tb_top.sv +cover -covercells

vsim -voptargs=+acc work.tb_top -l reports/Main.log -cover
coverage save -onexit cov.ucdb

add wave *
run -all

coverage report -details -output reports/cov_report.txt