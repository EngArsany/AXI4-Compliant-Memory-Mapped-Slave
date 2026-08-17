package AXI_read_driver_pkg;

  import AXI_read_transaction_pkg::*;

  class AXI_read_driver;

    virtual axi4_if.DRIVER          vif;
    mailbox #(AXI_read_transaction) gen2driver_mbx;
    mailbox #(int)                  driver2gen_mbx;

    task automatic reset_signals();
      vif.ARADDR  = '0;
      vif.ARLEN   = '0;
      vif.ARSIZE  = '0;
      vif.ARVALID = 1'b0;
      vif.RREADY  = 1'b0;
    endtask

    task automatic run_driver();
      AXI_read_transaction txn;
      int expected_beats;
      int actual_beats;

      reset_signals();

      forever begin
        gen2driver_mbx.get(txn);

        // =====================================================
        // READ ADDRESS CHANNEL
        // =====================================================
        @(negedge vif.ACLK);
        vif.ARADDR  = txn.araddr;
        vif.ARLEN   = txn.arlen;
        vif.ARSIZE  = txn.arsize;
        vif.ARVALID = 1'b1;

        do begin
          @(posedge vif.ACLK);
        end while (!(vif.ARVALID && vif.ARREADY));

        @(negedge vif.ACLK);
        vif.ARVALID = 1'b0;

        // =====================================================
        // READ DATA CHANNEL – with stall cycles to exercise
        // stable-RVALID assertions.
        // =====================================================
        expected_beats = txn.expected_r_beats();
        actual_beats = 0;

        // Insert RREADY low for at least 3 cycles before first beat.
        // This forces RVALID to be stable while !RREADY,
        // closing a_r_payload_stable and a_read_data_stable_when_stalled.
        @(negedge vif.ACLK);
        vif.RREADY = 1'b0;
        @(negedge vif.ACLK);
        vif.RREADY = 1'b0;
        @(negedge vif.ACLK);
        vif.RREADY = 1'b1;   // now accept data

        forever begin
          @(posedge vif.ACLK);
          if (vif.RVALID && vif.RREADY) begin
            actual_beats++;
            if (vif.RLAST) break;
          end
        end

        // =====================================================
        // Validate number of received beats
        // =====================================================
        if (actual_beats != expected_beats) begin
          $error("[READ_DRV] R-beat count mismatch: expected=%0d actual=%0d", expected_beats,
                 actual_beats);
        end

        @(negedge vif.ACLK);
        vif.RREADY = 1'b0;

        // =====================================================
        // Transaction complete
        // =====================================================
        if (driver2gen_mbx == null) begin
          $fatal(1, "[READ_DRV] driver2gen_mbx is null");
        end
        driver2gen_mbx.put(1);
      end
    endtask

  endclass

endpackage