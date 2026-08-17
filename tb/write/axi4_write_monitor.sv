package AXI_write_monitor_pkg;

  import AXI_write_transaction_pkg::*;

  class axi4_write_monitor;

    virtual axi4_if.MONITOR vif;

    mailbox #(axi4_write_txn) monitor2scb_mbx;
    mailbox #(int) scb2monitor_mbx;


    task automatic run_monitor();

      axi4_write_txn sampled;
      int token;

      forever begin

        sampled = new();

        // =================================================
        // WRITE ADDRESS CHANNEL
        // =================================================

        // Wait for an actual AW handshake.
        do begin
          @(posedge vif.ACLK);
        end while (!(vif.AWVALID && vif.AWREADY));

        // Sample the accepted address/control information.
        sampled.awaddr = vif.AWADDR;
        sampled.awlen  = vif.AWLEN;
        sampled.awsize = vif.AWSIZE;

        // Allocate storage for the observed data.
        sampled.wdata  = new[sampled.awlen + 1];

        // =================================================
        // WRITE DATA CHANNEL
        // =================================================

        for (int i = 0; i <= sampled.awlen; i++) begin

          // Wait for an actual W handshake.
          do begin
            @(posedge vif.ACLK);
          end while (!(vif.WVALID && vif.WREADY));

          sampled.wdata[i] = vif.WDATA;

        end

        // =================================================
        // WRITE RESPONSE CHANNEL
        // =================================================

        do begin
          @(posedge vif.ACLK);
        end while (!(vif.BVALID && vif.BREADY));

        sampled.act_bresp = vif.BRESP;

        // Send the observed transaction to the scoreboard.
        if (monitor2scb_mbx != null) monitor2scb_mbx.put(sampled);
        scb2monitor_mbx.get(token);

      end

    endtask

  endclass
endpackage
