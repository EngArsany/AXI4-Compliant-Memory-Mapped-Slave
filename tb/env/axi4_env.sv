package AXI_env_pkg;

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

  import AXI_reference_model_pkg::*;


  class AXI_env;

    // =========================================================
    // Virtual interfaces
    // =========================================================

    virtual axi4_if                 vif;
    virtual axi4_if.DRIVER          vif_driver;
    virtual axi4_if.MONITOR         vif_monitor;


    // =========================================================
    // Read components
    // =========================================================

    AXI_read_generator              read_gen;
    AXI_read_driver                 read_drv;
    AXI_read_monitor                read_mon;
    AXI_read_scoreboard             read_scb;


    // =========================================================
    // Read mailboxes
    // =========================================================

    mailbox #(AXI_read_transaction) read_gen2driver_mbx;
    mailbox #(int)                  read_driver2gen_mbx;

    mailbox #(AXI_read_transaction) read_gen2scb_mbx;
    mailbox #(int)                  read_scb2gen_mbx;

    mailbox #(AXI_read_transaction) read_monitor2scb_mbx;
    mailbox #(int)                  read_scb2monitor_mbx;


    // =========================================================
    // Write components
    // =========================================================

    axi4_write_generator            write_gen;
    axi4_write_driver               write_drv;
    axi4_write_monitor              write_mon;
    axi4_write_scoreboard           write_scb;
    axi4_golden_model               write_gm;
    axi4_write_coverage             write_cov;


    // =========================================================
    // Write mailboxes
    // =========================================================

    mailbox #(axi4_write_txn)       write_gen2driver_mbx;
    mailbox #(int)                  write_driver2gen_mbx;

    mailbox #(axi4_write_txn)       write_gen2scb_mbx;
    mailbox #(int)                  write_scb2gen_mbx;

    mailbox #(axi4_write_txn)       write_monitor2scb_mbx;
    mailbox #(int)                  write_scb2monitor_mbx;

    mailbox #(axi4_write_txn)       gm2scb_mbx;


    // =========================================================
    // Shared reference model
    // =========================================================

    axi4_reference_model            ref_model;


    // =========================================================
    // Environment status
    // =========================================================

    bit                             write_done;
    bit                             read_done;
    bit                             test_done;


    // =========================================================
    // Constructor
    // =========================================================

    function new();

      // -------------------------------------------------------
      // Shared reference model
      // -------------------------------------------------------

      ref_model             = new();


      // -------------------------------------------------------
      // Read mailboxes
      // -------------------------------------------------------

      read_gen2driver_mbx   = new(1);
      read_driver2gen_mbx   = new(1);

      read_gen2scb_mbx      = new(1);
      read_scb2gen_mbx      = new(1);

      read_monitor2scb_mbx  = new(1);
      read_scb2monitor_mbx  = new(1);


      // -------------------------------------------------------
      // Write mailboxes
      // -------------------------------------------------------

      write_gen2driver_mbx  = new(1);
      write_driver2gen_mbx  = new(1);

      write_gen2scb_mbx     = new(1);
      write_scb2gen_mbx     = new(1);

      write_monitor2scb_mbx = new(1);
      write_scb2monitor_mbx = new(1);

      gm2scb_mbx            = new(1);


      write_done            = 0;
      read_done             = 0;
      test_done             = 0;

    endfunction


    // =========================================================
    // Build read environment
    // =========================================================

    task automatic build_read_env();

      // -------------------------------------------------------
      // Components
      // -------------------------------------------------------

      read_gen                 = new();
      read_drv                 = new();
      read_mon                 = new();
      read_scb                 = new();


      // -------------------------------------------------------
      // Generator connections
      // -------------------------------------------------------

      read_gen.gen2driver_mbx  = read_gen2driver_mbx;
      read_gen.driver2gen_mbx  = read_driver2gen_mbx;

      read_gen.gen2scb_mbx     = read_gen2scb_mbx;
      read_gen.scb2gen_mbx     = read_scb2gen_mbx;


      // -------------------------------------------------------
      // Driver connections
      // -------------------------------------------------------

      read_drv.gen2driver_mbx  = read_gen2driver_mbx;
      read_drv.driver2gen_mbx  = read_driver2gen_mbx;


      // -------------------------------------------------------
      // Monitor connections
      // -------------------------------------------------------

      read_mon.monitor2scb_mbx = read_monitor2scb_mbx;
      read_mon.scb2monitor_mbx = read_scb2monitor_mbx;


      // -------------------------------------------------------
      // Scoreboard connections
      // -------------------------------------------------------

      read_scb.gen2scb_mbx     = read_gen2scb_mbx;
      read_scb.scb2gen_mbx     = read_scb2gen_mbx;

      read_scb.monitor2scb_mbx = read_monitor2scb_mbx;
      read_scb.scb2monitor_mbx = read_scb2monitor_mbx;

      read_scb.ref_model       = ref_model;


      // -------------------------------------------------------
      // Virtual interfaces
      // -------------------------------------------------------

      read_drv.vif             = vif_driver;
      read_mon.vif             = vif_monitor;

    endtask


    // =========================================================
    // Build write environment
    // =========================================================

    task automatic build_write_env();

      // -------------------------------------------------------
      // Components
      // -------------------------------------------------------

      write_gen                 = new();
      write_drv                 = new();
      write_mon                 = new();
      write_scb                 = new();
      write_gm                  = new();
      write_cov                 = new();


      // -------------------------------------------------------
      // Generator connections
      // -------------------------------------------------------

      write_gen.gen2driver_mbx  = write_gen2driver_mbx;
      write_gen.driver2gen_mbx  = write_driver2gen_mbx;

      write_gen.gen2scb_mbx     = write_gen2scb_mbx;
      write_gen.scb2gen_mbx     = write_scb2gen_mbx;


      // -------------------------------------------------------
      // Driver connections
      // -------------------------------------------------------

      write_drv.gen2driver_mbx  = write_gen2driver_mbx;
      write_drv.driver2gen_mbx  = write_driver2gen_mbx;


      // -------------------------------------------------------
      // Monitor connections
      // -------------------------------------------------------

      write_mon.monitor2scb_mbx = write_monitor2scb_mbx;
      write_mon.scb2monitor_mbx = write_scb2monitor_mbx;


      // -------------------------------------------------------
      // Scoreboard connections
      // -------------------------------------------------------


      write_scb.monitor2scb_mbx = write_monitor2scb_mbx;
      write_scb.scb2monitor_mbx = write_scb2monitor_mbx;
      write_scb.scb2gen_mbx     = write_scb2gen_mbx;

      write_scb.gm2scb_mbx      = gm2scb_mbx;
      write_scb.write_cov       = write_cov;


      // -------------------------------------------------------
      // Golden model
      // -------------------------------------------------------

      write_gm.set_reference_model(ref_model);


      // -------------------------------------------------------
      // Virtual interfaces
      // -------------------------------------------------------

      write_drv.vif = vif_driver;
      write_mon.vif = vif_monitor;

    endtask


    // =========================================================
    // Run golden model
    // =========================================================

    task automatic run_golden_model();

      axi4_write_txn txn;


      forever begin

        write_gen2scb_mbx.get(txn);

        write_gm.predict(txn);

        gm2scb_mbx.put(txn);

      end

    endtask


    // =========================================================
    // Run write environment
    // =========================================================

    task automatic run_write_env();

      build_write_env();


      fork : write_processes

        write_gen.run_generator();

        write_drv.run_driver();

        write_mon.run_monitor();

        run_golden_model();

        write_scb.run_scoreboard();

      join_none

      wait (write_gen.done);


      write_done = 1;


      // -------------------------------------------------------
      // Stop background components.
      // -------------------------------------------------------

      disable write_processes;


      // -------------------------------------------------------
      // Final report.
      // -------------------------------------------------------

      write_scb.report();

    endtask


    // =========================================================
    // Run read environment
    // =========================================================

    task automatic run_read_env();

      build_read_env();


      fork : read_processes

        read_gen.run_generator();

        read_drv.run_driver();

        read_mon.run_monitor();

        read_scb.run_scoreboard();

      join_none


      // -------------------------------------------------------
      // The generator is the completion owner.
      // -------------------------------------------------------

      wait (read_gen.done);


      read_done = 1;


      // -------------------------------------------------------
      // Stop background components.
      // -------------------------------------------------------

      disable read_processes;


      // -------------------------------------------------------
      // Final report.
      // -------------------------------------------------------

      read_scb.report();

    endtask


    // =========================================================
    // Main environment
    // =========================================================

    task automatic run_env();

      run_write_env();


      // -------------------------------------------------------
      // After all writes are complete, run reads.
      // -------------------------------------------------------

      run_read_env();

      // -------------------------------------------------------
      // All verification activity is complete.
      // -------------------------------------------------------

      test_done = 1;


      $display("=================================================");
      $display("                 TEST COMPLETE");
      $display("=================================================");
      $display("Write environment : COMPLETE");
      $display("Read environment  : COMPLETE");
      $display("=================================================");

    endtask

  endclass

endpackage
