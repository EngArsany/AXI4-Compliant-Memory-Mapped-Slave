//=============================================================
// tb_top.sv
//=============================================================

`timescale 1ns/1ps

import axi4_write_pkg::*;
import AXI_env_pkg::*;

module tb_top;

    localparam ADDR_WIDTH   = 16;
    localparam DATA_WIDTH   = 32;
    localparam MEMORY_DEPTH = 1024;

    bit ACLK;
    bit ARESETn;

    initial ACLK = 1'b0;
    always #5 ACLK = ~ACLK;

    initial begin
        ARESETn = 1'b0;
        repeat (5) @(posedge ACLK);
        ARESETn = 1'b1;
    end

    axi4_if #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) vif (
        .ACLK(ACLK),
        .ARESETn(ARESETn)
    );

    axi4 #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MEMORY_DEPTH(MEMORY_DEPTH)
    ) dut (
        .ACLK(ACLK),
        .ARESETn(ARESETn),

        .AWADDR(vif.AWADDR), .AWLEN(vif.AWLEN), .AWSIZE(vif.AWSIZE),
        .AWVALID(vif.AWVALID), .AWREADY(vif.AWREADY),

        .WDATA(vif.WDATA), .WVALID(vif.WVALID), .WLAST(vif.WLAST),
        .WREADY(vif.WREADY),

        .BRESP(vif.BRESP), .BVALID(vif.BVALID), .BREADY(vif.BREADY),

        // Write-only verification scope: read channel remains idle.
        .ARADDR({ADDR_WIDTH{1'b0}}),
        .ARLEN(8'h00),
        .ARSIZE(3'b010),
        .ARVALID(1'b0),
        .ARREADY(),
        .RDATA(),
        .RRESP(),
        .RVALID(),
        .RLAST(),
        .RREADY(1'b0)
    );

    // -----------------------------------------------------------
    // Modport handles.
    //
    // IMPORTANT: assign these handles first and pass the handles to
    // the classes. Do NOT call new(vif.DRIVER)/new(vif.MONITOR)
    // directly. Questa warns about using a modport in a hierarchical
    // path; this handle-based form preserves the required modports
    // without that warning.
    // -----------------------------------------------------------
    virtual axi4_if.DRIVER  drv_vif;
    virtual axi4_if.MONITOR mon_vif;

    // -----------------------------------------------------------
    // Backdoor memory access.
    // -----------------------------------------------------------
    class axi4_backdoor_impl extends axi4_backdoor_base;
        function bit [31:0] read(bit [9:0] word_addr);
            return dut.mem_inst.memory[word_addr];
        endfunction
    endclass

    AXI_env    env;
    axi4_backdoor_impl bd;

    localparam int WATCHDOG_CYCLES = 200_000;

initial begin

    env = new();
    env.vif_driver = drv_vif;
    env.vif_monitor = mon_vif;

    bd = new();
    env.bd = bd;

    fork

        begin
            env.run_env(200);
            $display("[TB_TOP] Test complete.");
        end

        begin
            repeat (WATCHDOG_CYCLES)
                @(posedge ACLK);

            $display(
                "[TB_TOP] WATCHDOG TIMEOUT at time %0t",
                $time
            );

            $display(
                "[TB_TOP] write_state=%0d AWVALID=%b AWREADY=%b WVALID=%b WREADY=%b BVALID=%b BREADY=%b",
                dut.write_state,
                vif.AWVALID,
                vif.AWREADY,
                vif.WVALID,
                vif.WREADY,
                vif.BVALID,
                vif.BREADY
            );

            $fatal(
                1,
                "[TB_TOP] Simulation did not complete within %0d cycles",
                WATCHDOG_CYCLES
            );
        end

    join_any

    disable fork;

end

endmodule
