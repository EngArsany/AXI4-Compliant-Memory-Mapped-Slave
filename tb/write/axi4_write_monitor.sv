package AXI_write_monitor_pkg;

  import AXI_write_transaction_pkg::*;


  class axi4_write_monitor;

    virtual axi4_if.MONITOR   vif;

    mailbox #(axi4_write_txn) monitor2scb_mbx;
    mailbox #(int)            scb2monitor_mbx;


    task automatic run_monitor();

      axi4_write_txn sampled;
      int token;


      forever begin

        sampled = new();


        // =====================================================
        // WRITE ADDRESS CHANNEL
        // =====================================================

        // Wait for an actual AW handshake.
        do begin

          @(posedge vif.ACLK);

        end while (!(vif.AWVALID && vif.AWREADY));


        // Sample the accepted address/control information.
        sampled.awaddr = vif.AWADDR;
        sampled.awlen  = vif.AWLEN;
        sampled.awsize = vif.AWSIZE;


        // Allocate storage for the observed write data.
        sampled.wdata  = new[sampled.awlen + 1];


        // =====================================================
        // WRITE DATA CHANNEL
        // =====================================================

        for (int i = 0; i <= sampled.awlen; i++) begin

          // Wait for an actual W handshake.
          do begin

            @(posedge vif.ACLK);

          end while (!(vif.WVALID && vif.WREADY));


          // Capture transferred data.
          sampled.wdata[i] = vif.WDATA;


          // WLAST must be asserted only on the final beat.
          if (i == sampled.awlen) begin

            if (!vif.WLAST) begin

              $error("[WRITE_MON] WLAST missing on final write beat");

            end

          end else begin

            if (vif.WLAST) begin

              $error("[WRITE_MON] WLAST asserted before final write beat");

            end

          end

        end


        // =====================================================
        // WRITE RESPONSE CHANNEL
        // =====================================================

        do begin

          @(posedge vif.ACLK);

        end while (!(vif.BVALID && vif.BREADY));


        sampled.act_bresp = vif.BRESP;


        // =====================================================
        // SEND COMPLETED TRANSACTION
        // =====================================================

        if (monitor2scb_mbx == null) begin

          $fatal(1, "[WRITE_MON] monitor2scb_mbx is null");

        end

        monitor2scb_mbx.put(sampled);


        // Wait until scoreboard consumes the transaction.
        if (scb2monitor_mbx == null) begin

          $fatal(1, "[WRITE_MON] scb2monitor_mbx is null");

        end

        scb2monitor_mbx.get(token);

      end

    endtask

  endclass

endpackage
