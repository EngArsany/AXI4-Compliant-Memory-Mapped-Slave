package AXI_read_scoreboard_pkg;

  import AXI_read_transaction_pkg::*;
  import AXI_reference_model_pkg::*;

  class AXI_read_scoreboard;

    AXI_read_transaction            expected_txn;
    AXI_read_transaction            actual_txn;

    mailbox #(AXI_read_transaction) gen2scb_mbx;
    mailbox #(int)                  scb2gen_mbx;

    mailbox #(AXI_read_transaction) monitor2scb_mbx;
    mailbox #(int)                  scb2monitor_mbx;

    axi4_reference_model            ref_model;

    static int unsigned             num_checked        = 0;
    static int unsigned             num_address_errors = 0;
    static int unsigned             num_data_errors    = 0;
    static int unsigned             num_rresp_errors   = 0;


    function void find_expected_values();

      if (ref_model == null) $fatal("[READ_SCB] Reference model handle is null.");

      ref_model.predict_read(expected_txn);

    endfunction


    function void display_values();

      $display("=== Actual Transaction ===");
      actual_txn.display_info();

      $display("\n=== Expected Transaction ===");
      expected_txn.display_info();

    endfunction


    function void check_addresses();

      bit addresses_equal;

      addresses_equal =
          (expected_txn.araddr == actual_txn.araddr) &&
          (expected_txn.arlen  == actual_txn.arlen)  &&
          (expected_txn.arsize == actual_txn.arsize);

      if (addresses_equal) begin

        $display("[READ_SCB][Success] Address/control information is equal for transaction no. %0d",
                 num_checked);

      end else begin

        num_address_errors++;

        $display(
            "[READ_SCB][Fail] Address/control information is NOT equal for transaction no. %0d",
            num_checked);

      end

    endfunction


    // ---------------------------------------------------------
    // Check returned read data.
    // ---------------------------------------------------------

    function void check_data();

      bit data_equal;

      data_equal = 1'b1;

      if (expected_txn.rdata.size() != actual_txn.rdata.size()) begin

        num_data_errors++;

        $display(
            "[READ_SCB][Fail] RDATA size mismatch for transaction no. %0d: expected=%0d actual=%0d",
            num_checked, expected_txn.rdata.size(), actual_txn.rdata.size());

        return;

      end


      foreach (expected_txn.rdata[i]) begin

        if (expected_txn.rdata[i] !== actual_txn.rdata[i]) begin

          data_equal = 1'b0;

          $display(
              "[READ_SCB][Fail] RDATA mismatch for transaction " + "no. %0d beat=%0d expected=0x%08h actual=0x%08h",
              num_checked, i, expected_txn.rdata[i], actual_txn.rdata[i]);

          break;

        end

      end


      if (data_equal) begin

        $display("[READ_SCB][Success] RDATA is equal for transaction no. %0d", num_checked);

      end else begin

        num_data_errors++;

      end

    endfunction


    // ---------------------------------------------------------
    // Check read response values.
    // ---------------------------------------------------------

    function void check_rresp();

      bit rresp_equal;

      rresp_equal = 1'b1;


      if (expected_txn.rresp.size() != actual_txn.rresp.size()) begin

        num_rresp_errors++;

        $display(
            "[READ_SCB][Fail] RRESP size mismatch for transaction no. %0d: expected=%0d actual=%0d",
            num_checked, expected_txn.rresp.size(), actual_txn.rresp.size());

        return;

      end


      foreach (expected_txn.rresp[i]) begin

        if (expected_txn.rresp[i] !== actual_txn.rresp[i]) begin

          rresp_equal = 1'b0;

          $display(
              "[READ_SCB][Fail] RRESP mismatch for transaction " + "no. %0d beat=%0d expected=%0b actual=%0b",
              num_checked, i, expected_txn.rresp[i], actual_txn.rresp[i]);

          break;

        end

      end


      if (rresp_equal) begin

        $display("[READ_SCB][Success] RRESP values are equal for transaction no. %0d", num_checked);

      end else begin

        num_rresp_errors++;

      end

    endfunction


    // ---------------------------------------------------------
    // Check complete transaction.
    // ---------------------------------------------------------

    function void check_transactions();

      check_addresses();
      check_data();
      check_rresp();

    endfunction


    // ---------------------------------------------------------
    // Main scoreboard process.
    // ---------------------------------------------------------

    task run_scoreboard;

      int token;

      forever begin

        // The generator transaction is used as the expected
        // transaction because it contains the requested
        // read address/control information.
        gen2scb_mbx.get(expected_txn);

        scb2gen_mbx.put(1);

        num_checked++;


        // Wait for the transaction observed on the DUT side.
        monitor2scb_mbx.get(actual_txn);


        // Calculate expected RDATA/RRESP.
        find_expected_values();


        display_values();

        check_transactions();


        scb2monitor_mbx.put(1);

      end

    endtask


    // ---------------------------------------------------------
    // Final report.
    // ---------------------------------------------------------

    function void report();

      $display("=================================================");
      $display("             READ SCOREBOARD SUMMARY");
      $display("=================================================");
      $display("Transactions checked : %0d", num_checked);
      $display("Address errors       : %0d", num_address_errors);
      $display("Data errors          : %0d", num_data_errors);
      $display("RRESP errors         : %0d", num_rresp_errors);
      $display("=================================================");


      if ((num_rresp_errors != 0) || (num_data_errors != 0) || (num_address_errors != 0)) begin

        $error("[READ_SCB] Verification failures detected.");

      end else begin

        $display("[READ_SCB] All checks passed.");

      end

    endfunction

  endclass

endpackage
