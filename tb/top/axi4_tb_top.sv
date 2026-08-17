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

      // ------------------------------------------------------
      // Write address channel
      // ------------------------------------------------------

      .AWADDR (vif.AWADDR),
      .AWLEN  (vif.AWLEN),
      .AWSIZE (vif.AWSIZE),
      .AWVALID(vif.AWVALID),
      .AWREADY(vif.AWREADY),


      // ------------------------------------------------------
      // Write data channel
      // ------------------------------------------------------

      .WDATA (vif.WDATA),
      .WLAST (vif.WLAST),
      .WVALID(vif.WVALID),
      .WREADY(vif.WREADY),


      // ------------------------------------------------------
      // Write response channel
      // ------------------------------------------------------

      .BRESP (vif.BRESP),
      .BVALID(vif.BVALID),
      .BREADY(vif.BREADY),


      // ------------------------------------------------------
      // Read address channel
      // ------------------------------------------------------

      .ARADDR (vif.ARADDR),
      .ARLEN  (vif.ARLEN),
      .ARSIZE (vif.ARSIZE),
      .ARVALID(vif.ARVALID),
      .ARREADY(vif.ARREADY),


      // ------------------------------------------------------
      // Read data channel
      // ------------------------------------------------------

      .RDATA (vif.RDATA),
      .RRESP (vif.RRESP),
      .RLAST (vif.RLAST),
      .RVALID(vif.RVALID),
      .RREADY(vif.RREADY)

  );


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

    // --------------------------------------------------------
    // Initialize interface signals before the environment
    // starts driving transactions.
    // --------------------------------------------------------

    ARESETn = 1'b0;

    initialize_signals();


    // --------------------------------------------------------
    // Construct and connect environment.
    // --------------------------------------------------------

    env             = new();

    env.vif         = vif;
    env.vif_driver  = vif;
    env.vif_monitor = vif;


    // --------------------------------------------------------
    // Reset DUT.
    // --------------------------------------------------------

    reset_dut();


    // --------------------------------------------------------
    // Run complete verification.
    // --------------------------------------------------------

    env.run_env();


    // --------------------------------------------------------
    // Environment returns only after:
    //
    //   write generation completed
    //   write scoreboard completed
    //   read generation completed
    //   read scoreboard completed
    //
    // --------------------------------------------------------

    $finish;

  end

endmodule
