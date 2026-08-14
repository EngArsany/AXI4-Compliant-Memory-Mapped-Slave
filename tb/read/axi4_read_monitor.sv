package AXI_read_monitor_pkg;

  import AXI_read_transaction_pkg::*;

  class AXI_read_monitor;

    virtual axi4_if.MONITOR vif;

    mailbox #(AXI_read_transaction) monitor2scb;
    mailbox #(int) scb2monitor;


    task run_monitor();
      AXI_read_transaction sampled;
      int token;


      forever begin

        @(posedge vif.ACLK);
        sampled.araddr   = vif.ARADDR;
        sampled.areset_n = vif.ARESETn;
        sampled.arlen    = vif.ARLEN;
        sampled.arsize   = vif.ARSIZE;
        sampled.arvalid  = vif.ARVALID;
        sampled.arready  = vif.ARREADY;
        sampled.rdata    = vif.RDATA;
        sampled.rresp    = vif.RRESP;
        sampled.rlast    = vif.RLAST;
        sampled.rvalid   = vif.RVALID;
        sampled.rready   = vif.RREADY;

        monitor2scb.put(sampled);
        scb2monitor.get(token);
      end
    endtask

  endclass

endpackage
