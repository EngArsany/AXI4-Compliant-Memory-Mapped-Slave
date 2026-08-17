import AXI_env_pkg::*;

`timescale 1ns / 1ps

module tb_top;

  // ==========================================================
  // Clock
  // ==========================================================
  logic ACLK;
  logic ARESETn;

  // ==========================================================
  // AXI interface
  // ==========================================================
  axi4_if vif (
      .ACLK   (ACLK),
      .ARESETn(ARESETn)
  );

  // ==========================================================
  // DUT
  // ==========================================================
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

  // ==========================================================
  // READ-CHANNEL ASSERTIONS
  // ==========================================================

  function automatic bit read_burst_valid(
      bit [15:0] addr, bit [7:0] len, bit [2:0] size);
    longint unsigned beats;
    longint unsigned bytes_per_beat;
    longint unsigned final_byte;

    beats         = longint'(len) + 1;
    bytes_per_beat = 64'(1) << size;
    final_byte    = longint'(addr) + (beats * bytes_per_beat) - 1;

    if (size != 3'b010) return 0;
    if (addr[1:0] != 2'b00) return 0;
    if (addr >= 16'h1000) return 0;
    if ((longint'(addr) >> 12) != (final_byte >> 12)) return 0;
    if ((final_byte >> 2) >= 1024) return 0;

    return 1;
  endfunction

  // AR control must remain stable until the DUT accepts the address.
  property p_read_address_stable;
    @(posedge ACLK) disable iff (!ARESETn)
      (vif.ARVALID && !vif.ARREADY) |=> $stable({vif.ARADDR, vif.ARLEN, vif.ARSIZE});
  endproperty
  a_read_address_stable: assert property (p_read_address_stable)
    else $error("[READ_SVA] ARADDR/ARLEN/ARSIZE changed while ARVALID && !ARREADY");


  // A read response is legal only as OKAY or SLVERR for this DUT.
  property p_read_response_legal;
    @(posedge ACLK) disable iff (!ARESETn)
      vif.RVALID |-> ((vif.RRESP == 2'b00) || (vif.RRESP == 2'b10));
  endproperty
  a_read_response_legal: assert property (p_read_response_legal)
    else $error("[READ_SVA] Illegal RRESP observed: %b", vif.RRESP);


  // RLAST is meaningful only with a valid R-channel response.
  property p_rlast_requires_rvalid;
    @(posedge ACLK) disable iff (!ARESETn)
      vif.RLAST |-> vif.RVALID;
  endproperty
  a_rlast_requires_rvalid: assert property (p_rlast_requires_rvalid)
    else $error("[READ_SVA] RLAST asserted without RVALID");


  // R channel must hold its payload/control stable while stalled.
  property p_read_data_stable_when_stalled;
    @(posedge ACLK) disable iff (!ARESETn)
      (vif.RVALID && !vif.RREADY) |=>
        $stable({vif.RDATA, vif.RRESP, vif.RLAST});
  endproperty
  a_read_data_stable_when_stalled: assert property (p_read_data_stable_when_stalled)
    else $error("[READ_SVA] RDATA/RRESP/RLAST changed while RVALID && !RREADY");

  property p_invalid_read_returns_slverr;
    @(posedge ACLK) disable iff (!ARESETn)
      (vif.ARVALID && vif.ARREADY &&
       !read_burst_valid(vif.ARADDR, vif.ARLEN, vif.ARSIZE))
      |-> ##[1:600] (vif.RVALID && vif.RREADY && vif.RLAST && vif.RRESP == 2'b10);


  endproperty
  a_invalid_read_returns_slverr: assert property (p_invalid_read_returns_slverr)
    else $error("[READ_SVA] Invalid read did not return SLVERR + RLAST");


  // Every accepted RLAST must terminate an accepted R-channel transfer.
  property p_rlast_is_terminal;
    @(posedge ACLK) disable iff (!ARESETn)
      (vif.RVALID && vif.RREADY && vif.RLAST) |=> !vif.RLAST;
  endproperty

  a_rlast_is_terminal: assert property (p_rlast_is_terminal)

    else $error("[READ_SVA] RLAST remained asserted after the terminal transfer");

  // ==========================================================
  // Environment
  // ==========================================================
  AXI_env env;

  // ==========================================================
  // Clock generation
  // ==========================================================
  initial begin
    ACLK = 1'b0;
    forever #5 ACLK = ~ACLK;
  end

  // ==========================================================
  // Initialize master-driven signals
  // ==========================================================
  task automatic initialize_signals();
    vif.AWADDR  = '0;
    vif.AWLEN   = '0;
    vif.AWSIZE  = 3'b010;
    vif.AWVALID = 1'b0;

    vif.WDATA   = '0;
    vif.WLAST   = 1'b0;
    vif.WVALID  = 1'b0;

    vif.BREADY  = 1'b0;

    vif.ARADDR  = '0;
    vif.ARLEN   = '0;
    vif.ARSIZE  = 3'b010;
    vif.ARVALID = 1'b0;

    vif.RREADY  = 1'b0;
  endtask

  // ==========================================================
  // Reset
  // ==========================================================
  task automatic reset_dut();
    ARESETn = 1'b0;
    repeat (2) @(posedge ACLK);
    ARESETn = 1'b1;
    @(posedge ACLK);
  endtask

  // ==========================================================
  // Test
  // ==========================================================
  initial begin
    ARESETn = 1'b0;
    initialize_signals();

    env             = new();
    env.vif         = vif;
    env.vif_driver  = vif;
    env.vif_monitor = vif;

    reset_dut();

    env.run_env();

    $finish;
  end

endmodule