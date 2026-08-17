package AXI_read_scoreboard_pkg;

  import AXI_read_transaction_pkg::*;
  import AXI_reference_model_pkg::*;
  import AXI_read_coverage_pkg::*;

  class AXI_read_scoreboard;

    mailbox #(AXI_read_transaction) gen2scb_mbx;
    mailbox #(int)                  scb2gen_mbx;
    mailbox #(AXI_read_transaction) monitor2scb_mbx;
    mailbox #(int)                  scb2monitor_mbx;

    axi4_reference_model            ref_model;
    AXI_read_coverage                read_cov;

    int unsigned                    num_checked;
    int unsigned                    num_address_errors;
    int unsigned                    num_data_errors;
    int unsigned                    num_rresp_errors;
    int unsigned                    num_rlast_errors;

    function new();
      num_checked        = 0;
      num_address_errors = 0;
      num_data_errors    = 0;
      num_rresp_errors   = 0;
      num_rlast_errors   = 0;
      read_cov           = new();
    endfunction

    // ========================================================
    // Generate expected read response
    // ========================================================
    function void find_expected_values();
      if (ref_model == null) $fatal(1, "[READ_SCB] Reference model handle is null.");
      ref_model.predict_read(expected_txn);
    endfunction

    AXI_read_transaction expected_txn;
    AXI_read_transaction actual_txn;

    // ========================================================
    // Address/control check
    // ========================================================
    function void check_addresses();
      bit addresses_equal;
      addresses_equal =
          (expected_txn.araddr == actual_txn.araddr) &&
          (expected_txn.arlen  == actual_txn.arlen)  &&
          (expected_txn.arsize == actual_txn.arsize);
      if (addresses_equal) begin
        $display("[READ_SCB][SUCCESS] Address/control matched transaction %0d", num_checked);
      end else begin
        num_address_errors++;
        $error("[READ_SCB][FAIL] Address/control mismatch transaction %0d", num_checked);
      end
    endfunction

    // ========================================================
    // RDATA check
    // ========================================================
    function void check_data();
      if (expected_txn.rdata.size() != actual_txn.rdata.size()) begin
        num_data_errors++;
        $error("[READ_SCB][FAIL] RDATA count mismatch transaction %0d: expected=%0d actual=%0d",
               num_checked, expected_txn.rdata.size(), actual_txn.rdata.size());
        return;
      end
      foreach (expected_txn.rdata[i]) begin
        if (expected_txn.rdata[i] !== actual_txn.rdata[i]) begin
          num_data_errors++;
          $error("[READ_SCB][FAIL] RDATA mismatch transaction %0d beat=%0d expected=0x%08h actual=0x%08h",
                 num_checked, i, expected_txn.rdata[i], actual_txn.rdata[i]);
        end
      end
    endfunction

    // ========================================================
    // RRESP check
    // ========================================================
    function void check_rresp();
      if (expected_txn.rresp.size() != actual_txn.rresp.size()) begin
        num_rresp_errors++;
        $error("[READ_SCB][FAIL] RRESP count mismatch transaction %0d: expected=%0d actual=%0d",
               num_checked, expected_txn.rresp.size(), actual_txn.rresp.size());
        return;
      end
      foreach (expected_txn.rresp[i]) begin
        if (expected_txn.rresp[i] !== actual_txn.rresp[i]) begin
          num_rresp_errors++;
          $error("[READ_SCB][FAIL] RRESP mismatch transaction %0d beat=%0d expected=%0b actual=%0b",
                 num_checked, i, expected_txn.rresp[i], actual_txn.rresp[i]);
        end
      end
    endfunction

    // ========================================================
    // RLAST check – compare entire queues
    // ========================================================
    function void check_rlast();
      // First check queue sizes (optional, but good for completeness)
      if (expected_txn.rlast.size() != actual_txn.rlast.size()) begin
        num_rlast_errors++;
        $error("[READ_SCB][FAIL] RLAST count mismatch transaction %0d: expected=%0d actual=%0d",
               num_checked, expected_txn.rlast.size(), actual_txn.rlast.size());
        return;
      end
      // Compare full queue
      if (expected_txn.rlast != actual_txn.rlast) begin
        num_rlast_errors++;
        $error("[READ_SCB][FAIL] RLAST mismatch transaction %0d: expected=%p actual=%p",
               num_checked, expected_txn.rlast, actual_txn.rlast);
      end
    endfunction

    // ========================================================
    // Complete transaction check
    // ========================================================
    function void check_transaction();
      check_addresses();
      check_data();
      check_rresp();
      check_rlast();
    endfunction

    // ========================================================
    // Main scoreboard process
    // ========================================================
    task run_scoreboard();
      int token;
      forever begin
        // Get expected transaction
        gen2scb_mbx.get(expected_txn);
        scb2gen_mbx.put(1);
        num_checked++;

        // Get actual DUT transaction
        monitor2scb_mbx.get(actual_txn);

        // Calculate expected response (reference model must fill rlast as queue)
        find_expected_values();

        check_transaction();

        // ----------------------------------------------------
        // Sample functional coverage PER BEAT
        // ----------------------------------------------------
        // Use the actual transaction's rlast queue (same length as rdata)
        foreach (actual_txn.rlast[i]) begin
          read_cov.sample_txn(
            actual_txn.araddr,
            actual_txn.arlen,
            actual_txn.arsize,
            actual_txn.is_valid_burst(),
            (actual_txn.rresp.size() > i) ? actual_txn.rresp[i] : 2'b11,
            (actual_txn.rdata.size() > i) ? actual_txn.rdata[i] : 32'hDEAD_BEEF,
            actual_txn.rlast[i],
            actual_txn.rdata.size()   // total beats for this transaction
          );
        end

        // Allow monitor to observe the next transaction
        scb2monitor_mbx.put(1);
      end
    endtask

    // ========================================================
    // Final report
    // ========================================================
    function void report();
      $display("=================================================");
      $display("             READ SCOREBOARD SUMMARY");
      $display("=================================================");
      $display("Transactions checked : %0d", num_checked);
      $display("Address errors       : %0d", num_address_errors);
      $display("Data errors          : %0d", num_data_errors);
      $display("RRESP errors         : %0d", num_rresp_errors);
      $display("RLAST errors         : %0d", num_rlast_errors);
      $display("=================================================");
      if ((num_address_errors != 0) ||
          (num_data_errors    != 0) ||
          (num_rresp_errors   != 0) ||
          (num_rlast_errors   != 0)) begin
        $error("[READ_SCB] Verification failures detected.");
      end else begin
        $display("[READ_SCB] All checks passed.");
      end
      $display("[READ_COV] Functional coverage = %0.2f%%", read_cov.cov.get_coverage());
    endfunction

  endclass

endpackage