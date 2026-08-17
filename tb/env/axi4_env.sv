package AXI_env_pkg;

  import AXI_read_transaction_pkg::*;
  import AXI_read_generator_pkg::*;
  import AXI_read_driver_pkg::*;
  import AXI_read_monitor_pkg::*;
  import AXI_read_scoreboard_pkg::*;


  class AXI_env;
    // Interfaces
    virtual axi4_if.DRIVER          vif_driver;
    virtual axi4_if.MONITOR         vif_monitor;

    // Read Components
    AXI_read_generator              read_gen;
    AXI_read_driver                 read_drv;
    AXI_read_monitor                read_mon;
    AXI_read_scb                    read_scb;

    // Read Mailboxes
    mailbox #(AXI_read_transaction) read_gen2driver_mbx;
    mailbox #(int)                  read_driver2gen_mbx;

    mailbox #(AXI_read_transaction) read_gen2scb_mbx;
    mailbox #(int)                  read_scb2gen_mbx;

    mailbox #(AXI_read_transaction) read_monitor2scb;
    mailbox #(int)                  read_scb2monitor;

    // Write Components
    axi4_write_generator            write_gen;
    axi4_write_driver               write_drv;
    axi4_write_monitor              write_mon;
    axi4_write_scoreboard           write_scb;
    axi4_golden_model               write_gm;
    axi4_write_coverage             write_cov;

    // Write Mailboxes
    mailbox #(axi4_write_txn)       write_gen2driver_mbx;
    mailbox #(int)                  write_driver2gen_mbx;

    mailbox #(axi4_write_txn)       write_gen2scb_mbx;
    mailbox #(int)                  write_scb2gen_mbx;

    mailbox #(axi4_write_txn)       write_monitor2scb_mbx;
    mailbox #(int)                  write_scb2mon_mbx;

    task run_read_env();
      // Initialize mailboxes
      read_gen2driver_mbx = new(1);
      read_driver2gen_mbx = new(1);
      read_gen2scb_mbx = new(1);
      read_scb2gen_mbx = new(1);
      read_monitor2scb = new(1);
      read_scb2monitor = new(1);

      // Initialize components
      read_gen = new();
      read_drv = new();
      read_mon = new();
      read_scb = new();

      // Wire generator mailboxes
      read_gen.gen2driver_mbx = read_driver2gen_mbx;
      read_gen.driver2gen_mbx = read_driver2gen_mbx;
      read_gen.gen2scb_mbx = read_gen2scb_mbx;
      read_gen.scb2gen_mbx = read_scb2gen_mbx;

      // Wire driver mailboxes
      read_drv.gen2driver_mbx = read_gen2driver_mbx;
      read_drv.driver2gen_mbx = read_driver2gen_mbx;

      // Wire Monitor mailboxes
      read_mon.monitor2scb = read_monitor2scb;
      read_mon.scb2monitor = read_scb2monitor;

      // Wire scoreboard mailboxes
      read_scb.gen2scb_mbx = read_gen2scb_mbx;
      read_scb.scb2gen_mbx = read_scb2gen_mbx;
      read_scb.monitor2scb = read_monitor2scb;
      read_scb.scb2monitor = read_scb2monitor;

      // Virtual Interface
      read_drv.vif = vif_driver;
      read_mon.vif = vif_monitor;

      // Running
      fork
        read_gen.run_generator();
        read_drv.run_driver();
        read_mon.run_monitor();
        read_scb.run_scoreboard();
      join_any

      @(posedge vif.ACLK);
      @(posedge vif.ACLK);

      read_scb.report();
    endtask

    task run_write_env();
      // Initialize mailboxes
      write_gen2driver_mbx = new(1);
      write_driver2gen_mbx = new(1);
      write_gen2scb_mbx = new(1);
      write_scb2gen_mbx = new(1);
      write_monitor2scb = new(1);
      write_scb2monitor = new(1);

      // Initialize components
      write_gen = new();
      write_drv = new();
      write_mon = new();
      write_scb = new();
      write_gm = new();
      write_cov = new();

      // Wire generator mailboxes
      write_gen.gen2driver_mbx = write_driver2gen_mbx;
      write_gen.driver2gen_mbx = write_driver2gen_mbx;
      write_gen.gen2scb_mbx = write_gen2scb_mbx;
      write_gen.scb2gen_mbx = write_scb2gen_mbx;

      // Wire driver mailboxes
      write_drv.gen2driver_mbx = write_gen2driver_mbx;
      write_drv.driver2gen_mbx = write_driver2gen_mbx;

      // Wire Monitor mailboxes
      write_mon.monitor2scb = write_monitor2scb;
      write_mon.scb2monitor = write_scb2monitor;

      // Wire scoreboard mailboxes
      write_scb.gen2scb_mbx = write_gen2scb_mbx;
      write_scb.scb2gen_mbx = write_scb2gen_mbx;
      write_scb.monitor2scb = write_monitor2scb;
      write_scb.scb2monitor = write_scb2monitor;

      // Virtual Interface
      write_drv.vif = vif_driver;
      write_mon.vif = vif_monitor;

      // Running
      fork
        write_gen.run_generator();
        write_drv.run_driver();
        write_mon.run_monitor();
        write_scb.run_scoreboard();
      join_any

      @(posedge vif.ACLK);
      @(posedge vif.ACLK);

      write_scb.report();

    endtask

    // Main task
    task run_env();
      fork
        run_read_env();
        run_write_env();
      join_any

      $stop;

    endtask

  endclass
endpackage
