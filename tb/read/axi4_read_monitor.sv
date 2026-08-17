package AXI_read_monitor_pkg;

  import AXI_read_transaction_pkg::*;

  class AXI_read_monitor;

    virtual axi4_if.MONITOR vif;

    mailbox #(AXI_read_transaction) monitor2scb_mbx;
    mailbox #(int) scb2monitor_mbx;

    task run_monitor();
      AXI_read_transaction sampled;
      int token;

      forever begin
        sampled = new();

        // Wait for address transfer
        do begin
          @(negedge vif.ACLK);
        end while (!(vif.ARVALID && vif.ARREADY));

        // Sample address info
        sampled.araddr = vif.ARADDR;
        sampled.arlen  = vif.ARLEN;
        sampled.arsize = vif.ARSIZE;

        // Wait for data transfer
        // Handle bursts
        do begin
          @(negedge vif.ACLK);
          if (vif.RREADY && vif.RVALID) begin
            sampled.rdata.push_back(vif.RDATA);
            sampled.rresp.push_back(vif.RRESP);
          end
        end while (!(vif.RREADY && vif.RVALID && vif.RLAST));

        monitor2scb_mbx.put(sampled);
        scb2monitor_mbx.get(token);
      end
    endtask

  endclass

endpackage
