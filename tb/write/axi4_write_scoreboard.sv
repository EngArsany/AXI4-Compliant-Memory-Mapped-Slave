//=============================================================
// axi4_write_scoreboard.sv
//=============================================================

class axi4_write_scoreboard;

    axi4_golden_model gm;

    int unsigned num_checked;
    int unsigned num_bresp_errors;
    int unsigned num_data_errors;

    function new(axi4_golden_model gm);
        this.gm = gm;
        num_checked      = 0;
        num_bresp_errors = 0;
        num_data_errors  = 0;
    endfunction

    function void check_bresp(axi4_write_txn txn);
        num_checked++;

        if (txn.act_bresp !== txn.exp_bresp) begin
            num_bresp_errors++;
            $error("[SCOREBOARD] BRESP MISMATCH %s exp=%0b act=%0b",
                   txn.convert2string(), txn.exp_bresp, txn.act_bresp);
        end
        else begin
            $display("[SCOREBOARD] BRESP OK %s bresp=%0b",
                     txn.convert2string(), txn.act_bresp);
        end
    endfunction

    function void check_data(
        axi4_write_txn txn,
        int beat_idx,
        bit [31:0] backdoor_val
    );
        bit [31:0] expected;

        if (!txn.beat_valid[beat_idx])
            return;

        expected = gm.get_expected(txn.beat_word_addr[beat_idx]);

        if (backdoor_val !== expected) begin
            num_data_errors++;
            $error(
                "[SCOREBOARD] DATA MISMATCH addr=0x%0h exp=0x%0h act=0x%0h beat=%0d %s",
                txn.beat_word_addr[beat_idx], expected, backdoor_val,
                beat_idx, txn.convert2string()
            );
        end
    endfunction

    function void report();
        $display("=================================================");
        $display("  SCOREBOARD SUMMARY");
        $display("  Transactions checked : %0d", num_checked);
        $display("  BRESP errors         : %0d", num_bresp_errors);
        $display("  Data errors          : %0d", num_data_errors);
        $display("=================================================");

        if ((num_bresp_errors != 0) || (num_data_errors != 0))
            $error("[SCOREBOARD] Verification failures detected.");
    endfunction

endclass
