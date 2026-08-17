`timescale 1ns / 1ps

import AXI_read_transaction_pkg::*;
import AXI_read_generator_pkg::*;
import AXI_read_driver_pkg::*;
import AXI_read_monitor_pkg::*;
import AXI_read_scoreboard_pkg::*;

import AXI_write_transaction_pkg::*;
import AXI_write_generator_pkg::*;
import AXI_write_driver_pkg::*;
import AXI_write_monitor_pkg::*;
import AXI_write_scoreboard_pkg::*;
import AXI_write_golden_model_pkg::*;
import AXI_write_coverage_pkg::*;
import AXI_env_pkg::*;

module tb_top;

  logic ACLK;
  logic ARESETn;

  initial begin
    ACLK = 1'b0;
    forever #5 ACLK = ~ACLK;
  end

  axi4_if vif (
      .ACLK(ACLK),
      .ARESETn(ARESETn)
  );

  axi4 dut (
      .ACLK   (vif.ACLK),
      .ARESETn(vif.ARESETn),

      // Write address channel
      .AWADDR (vif.AWADDR),
      .AWLEN  (vif.AWLEN),
      .AWSIZE (vif.AWSIZE),
      .AWVALID(vif.AWVALID),
      .AWREADY(vif.AWREADY),

      // Write data channel
      .WDATA (vif.WDATA),
      .WLAST (vif.WLAST),
      .WVALID(vif.WVALID),
      .WREADY(vif.WREADY),

      // Write response channel
      .BRESP (vif.BRESP),
      .BVALID(vif.BVALID),
      .BREADY(vif.BREADY),

      // Read address channel
      .ARADDR (vif.ARADDR),
      .ARLEN  (vif.ARLEN),
      .ARSIZE (vif.ARSIZE),
      .ARVALID(vif.ARVALID),
      .ARREADY(vif.ARREADY),

      // Read data channel
      .RDATA (vif.RDATA),
      .RRESP (vif.RRESP),
      .RLAST (vif.RLAST),
      .RVALID(vif.RVALID),
      .RREADY(vif.RREADY)
  );

  AXI_env env;

  initial begin

    env = new();

    ARESETn = 1'b0;

    // Initialize master-driven signals.
    vif.AWADDR = '0;
    vif.AWLEN = '0;
    vif.AWSIZE = '0;
    vif.AWVALID = 1'b0;

    vif.WDATA = '0;
    vif.WLAST = 1'b0;
    vif.WVALID = 1'b0;

    vif.BREADY = 1'b0;

    vif.ARADDR = '0;
    vif.ARLEN = '0;
    vif.ARSIZE = '0;
    vif.ARVALID = 1'b0;

    vif.RREADY = 1'b0;

    repeat (2) @(posedge ACLK);

    ARESETn = 1'b1;

    env.run_env();

    wait (env.test_done);

    $finish;

  end

endmodule
