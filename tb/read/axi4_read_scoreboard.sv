package AXI_read_scoreboard_pkg;

  import AXI_read_transaction_pkg::*;

  class AXI_read_scoreboard;
    AXI_read_transaction expected_txn;
    AXI_read_transaction actual_txn;

    mailbox #(AXI_read_transaction) gen2scb;
    mailbox #(int) scb2gen;

    mailbox #(AXI_read_transaction) monitor2scb;
    mailbox #(int) scb2monitor;

    static int unsigned num_checked = 0;
    static int unsigned num_address_errors = 0;
    static int unsigned num_data_errors = 0;
    static int unsigned num_rresp_errors = 0;

    // Golden Model
    function void find_expected_values();
      expected_txn = new();

      expected_txn.araddr = actual_txn.araddr;
      expected_txn.arlen = actual_txn.arlen;
      expected_txn.arsize = actual_txn.arsize;

      for (int i = 0; i <= actual_txn.arlen; i++) begin

        int address = actual_txn.araddr + (i * (1 << actual_txn.arsize));

        // Invalid address / boundary violation
        if ((address >> 2) >= 1024) begin
          expected_txn.rdata.push_back(32'b0);
          expected_txn.rresp.push_back(2'b10);  // SLVERR
        end else begin
          expected_txn.rdata.push_back(memory[address>>2]);
          expected_txn.rresp.push_back(2'b00);  // OKAY
        end

      end

    endfunction

    function void display_values();
      $display("=== Actual Transaction ===");
      actual_txn.display_info();

      $display("\n=== Expected Transaction ===");
      expected_txn.display_info();

    endfunction


    function void check_addresses();
      bit addresses_equal = (expected_txn.araddr == actual_txn.araddr) && (expected_txn.arlen == actual_txn.arlen);

      if (addresses_equal)
        $display(
            "[Scoreboard][Success] Address info are equal for transaction no. %0d", num_checked
        );
      else begin
        num_address_errors++;
        $display("[Scoreboard][Fail] Address info are NOT equal for transaction no. %0d",
                 num_checked);
      end

    endfunction

    function void check_data();
      bit data_equal = 1;

      if (expected_txn.rdata.size() != actual_txn.rdata.size()) begin
        $display("[Scoreboard][Fail] Data is not of the same size for transaction no. %0d",
                 num_checked);
        return;
      end

      foreach (expected_txn.rdata[i]) begin
        if (expected_txn.rdata[i] == actual_txn.rdata[i]) continue;

        data_equal = 0;
        break;
      end

      if (data_equal)
        $display("[Scoreboard][Success] Data is equal for transaction no. %0d", num_checked);
      else begin
        num_data_errors++;
        $display("[Scoreboard][Fail] Data is not equal for transaction no. %0d", num_checked);
      end

    endfunction

    function void check_rresp();
      bit rresp_equal = 1;

      foreach (expected_txn.rresp[i]) begin
        if (expected_txn.rresp[i] == actual_txn.rresp[i]) continue;

        rresp_equal = 0;
        break;
      end

      if (rresp_equal)
        $display(
            "[Scoreboard][Success] RRESP values are equal for transaction no. %0d", num_checked
        );
      else begin
        num_rresp_errors++;
        $display("[Scoreboard][Fail] RRESP values are not equal for transaction no. %0d",
                 num_checked);
      end

    endfunction

    function void check_transactions();
      check_addresses();
      check_data();
      check_rresp();
    endfunction


    task run_scoreboard;
      forever begin
        gen2scb.get(expected_txn);
        scb2gen.put(1);
        num_checked++;

        monitor2scb.get(actual_txn);

        find_expected_values();

        display_values();
        check_transactions();

        scb2monitor.put(1);
      end
    endtask


    function void report();
      $display("=================================================");
      $display("  SCOREBOARD SUMMARY");
      $display("  Transaction No. : %0d", num_checked);
      $display("  Address errors          : %0d", num_address_errors);
      $display("  Data errors          : %0d", num_data_errors);
      $display("  RRESP errors         : %0d", num_rresp_errors);
      $display("=================================================");

      if ((num_rresp_errors != 0) || (num_data_errors != 0) || (num_address_errors != 0))
        $error("[SCOREBOARD][Fail] Verification failures detected.");
    endfunction


  endclass

endpackage
