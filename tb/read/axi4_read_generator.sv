package AXI_read_generator_pkg;

  import AXI_read_transaction_pkg::*;

  class AXI_read_generator;

    mailbox #(AXI_read_transaction) gen2driver_mbx;
    mailbox #(int)                  driver2gen_mbx;
    mailbox #(AXI_read_transaction) gen2scb_mbx;
    mailbox #(int)                  scb2gen_mbx;

    int unsigned num_of_txns = 200;
    bit done = 0;

    task send_transaction(AXI_read_transaction txn);
      int token;
      gen2driver_mbx.put(txn);
      driver2gen_mbx.get(token);
      gen2scb_mbx.put(txn);
      scb2gen_mbx.get(token);
    endtask

    task generate_directed(bit [15:0] addr, bit [7:0] len, bit [2:0] size,
                           string name);
      AXI_read_transaction txn = new();
      txn.araddr = addr;
      txn.arlen  = len;
      txn.arsize = size;
      $display("[READ_RTM] %s : ARADDR=0x%04h ARLEN=%0d ARSIZE=%0d VALID=%0b",
               name, addr, len, size, txn.is_valid_burst());
      send_transaction(txn);
    endtask

    task generate_rtm();
      // Normal / boundary cases
      generate_directed(16'h0000, 8'd0,   3'd2, "RTM-R01 single beat base address");
      generate_directed(16'h0004, 8'd1,   3'd2, "RTM-R02 two beat burst");
      generate_directed(16'h0020, 8'd7,   3'd2, "RTM-R03 short burst");
      generate_directed(16'h0100, 8'd31,  3'd2, "RTM-R04 medium burst");
      generate_directed(16'h0200, 8'd63,  3'd2, "RTM-R05 long burst");
      generate_directed(16'h0000, 8'd255, 3'd2, "RTM-R06 maximum 256 beat burst");
      generate_directed(16'h0FFC, 8'd0,   3'd2, "RTM-R07 last aligned word");
      generate_directed(16'h0FF0, 8'd3,   3'd2, "RTM-R08 burst ending exactly at 4KB boundary");

      // 4KB boundary violations
      generate_directed(16'h0FFC, 8'd1,   3'd2, "RTM-R09 4KB crossing by one beat");
      generate_directed(16'h0FF0, 8'd4,   3'd2, "RTM-R10 4KB crossing longer burst");

      // Memory-range violations
      generate_directed(16'h1000, 8'd0,   3'd2, "RTM-R11 first address outside memory");
      generate_directed(16'hFFFC, 8'd0,   3'd2, "RTM-R12 highest address");
      generate_directed(16'h0FF0, 8'd255, 3'd2, "RTM-R13 burst exceeds memory");

      // Alignment violations
      generate_directed(16'h0001, 8'd0,   3'd2, "RTM-R14 byte unaligned");
      generate_directed(16'h0002, 8'd0,   3'd2, "RTM-R15 halfword unaligned");
      generate_directed(16'h0003, 8'd0,   3'd2, "RTM-R16 word unaligned");

      // Unsupported ARSIZE values
      generate_directed(16'h0000, 8'd0,   3'd0, "RTM-R17 byte transfer size");
      generate_directed(16'h0000, 8'd0,   3'd1, "RTM-R18 halfword transfer size");
      generate_directed(16'h0000, 8'd0,   3'd3, "RTM-R19 doubleword transfer size");
      generate_directed(16'h0000, 8'd0,   3'd7, "RTM-R20 unsupported large transfer size");

      // ---------- NEW DIRECTED TESTS (closing coverage gaps) ----------
      // Valid bursts with large ARLEN
      generate_directed(16'h0000, 8'd200, 3'd2, "RTM-R21 valid extended burst");
      generate_directed(16'h0000, 8'd254, 3'd2, "RTM-R22 valid max-minus-one burst");

      // Bad ARSIZE + out-of-memory address -> SLVERR (closes size_x_resp gaps)
      generate_directed(16'h1000, 8'd0, 3'd0, "RTM-R23 byte size, OOB addr");
      generate_directed(16'h1000, 8'd0, 3'd1, "RTM-R24 halfword size, OOB addr");
      generate_directed(16'h1000, 8'd0, 3'd3, "RTM-R25 doubleword size, OOB addr");
      generate_directed(16'h1000, 8'd0, 3'd7, "RTM-R26 larger size, OOB addr");

      // max-minus-one length with invalid address (closes len_x_resp gaps)
      generate_directed(16'h1000, 8'd254, 3'd2, "RTM-R27 max-minus-one OOB burst");
    endtask

    task generate_random_transaction();
      AXI_read_transaction txn = new();
      int token;
      assert (txn.randomize())
        else $fatal(1, "[READ_GEN] Randomization failed.");
      send_transaction(txn);
    endtask

    task run_generator();
      generate_rtm();
      for (int i = 0; i < num_of_txns; i++) begin
        generate_random_transaction();
      end
      done = 1;
      $display("[%0t][READ_GEN] RTM + %0d random transactions completed",
               $time, num_of_txns);
    endtask

  endclass

endpackage