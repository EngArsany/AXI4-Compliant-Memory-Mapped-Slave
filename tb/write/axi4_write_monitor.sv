package AXI_write_monitor_pkg;

  import AXI_write_transaction_pkg::*;

  class axi4_write_monitor;

    virtual axi4_if.MONITOR   vif;

    mailbox #(axi4_write_txn) monitor2scb_mbx;
    mailbox #(int)            scb2monitor_mbx;


    task automatic run_monitor();

      axi4_write_txn sampled;
      int token;
      int wbeat_count;


      forever begin

        sampled = new();
        wbeat_count = 0;


        // =====================================================
        // WRITE ADDRESS CHANNEL
        // =====================================================

        do begin
          @(posedge vif.ACLK);
        end while (!(vif.AWVALID && vif.AWREADY));

        sampled.awaddr = vif.AWADDR;
        sampled.awlen  = vif.AWLEN;
        sampled.awsize = vif.AWSIZE;


        // =====================================================
        // WRITE DATA CHANNEL
        // =====================================================

        // Observe actual W handshakes.
        // Do not assume that AWLEN + 1 transfers will occur.
        sampled.wdata  = new[sampled.awlen + 1];

        forever begin

          @(posedge vif.ACLK);

          if (vif.WVALID && vif.WREADY) begin

            if (wbeat_count < sampled.wdata.size()) begin
              sampled.wdata[wbeat_count] = vif.WDATA;
            end

            // WLAST must correspond to the final expected beat.
            if (vif.WLAST) begin

              if (wbeat_count != sampled.awlen) begin
                $error("[WRITE_MON] WLAST asserted early: beat=%0d expected=%0d", wbeat_count,
                       sampled.awlen);
              end

              wbeat_count++;
              break;

            end

            wbeat_count++;

          end

        end


        // =====================================================
        // CHECK ACTUAL NUMBER OF WRITE BEATS
        // =====================================================

        if (wbeat_count != (sampled.awlen + 1)) begin
          $error("[WRITE_MON] Incorrect write burst length: observed=%0d expected=%0d",
                 wbeat_count, sampled.awlen + 1);
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
