package AXI_read_monitor_pkg;

  import AXI_read_transaction_pkg::*;

  class AXI_read_monitor;

    virtual axi4_if.MONITOR         vif;
    mailbox #(AXI_read_transaction) monitor2scb_mbx;
    mailbox #(int)                  scb2monitor_mbx;

    task automatic run_monitor();
      AXI_read_transaction sampled;
      int token;

      forever begin
        sampled = new();

        // READ ADDRESS CHANNEL
        do begin
          @(posedge vif.ACLK);
        end while (!(vif.ARVALID && vif.ARREADY));

        sampled.araddr = vif.ARADDR;
        sampled.arlen  = vif.ARLEN;
        sampled.arsize = vif.ARSIZE;

        // READ DATA CHANNEL
        forever begin
          @(posedge vif.ACLK);
          if (vif.RVALID && vif.RREADY) begin
            sampled.rdata.push_back(vif.RDATA);
            sampled.rresp.push_back(vif.RRESP);
            sampled.rlast.push_back(vif.RLAST);   
            if (vif.RLAST) break;
          end
        end

        // Send completed transaction to scoreboard
        if (monitor2scb_mbx == null) $fatal(1, "[READ_MON] monitor2scb_mbx is null");
        monitor2scb_mbx.put(sampled);
        if (scb2monitor_mbx == null) $fatal(1, "[READ_MON] scb2monitor_mbx is null");
        scb2monitor_mbx.get(token);
      end
    endtask

  endclass

endpackage