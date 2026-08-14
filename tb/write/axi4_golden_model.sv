//=============================================================
// axi4_golden_model.sv
//
// Reference model for the write channel.
//
// Behavior follows the supplied project specification and the DUT's
// documented design decision for this implementation:
//   - 4 KB burst crossing -> SLVERR and no writes.
//   - start address outside the 4 KB memory -> SLVERR and no writes.
//   - AWSIZE != 3'b010 is invalid for this 32-bit, no-WSTRB design
//     and is answered with SLVERR.
//   - Unaligned address is exercised as a corner case, but is not
//     independently rejected because the supplied design does not
//     define it as a separate error condition.
//=============================================================

class axi4_golden_model;

    localparam int MEMORY_DEPTH = 1024;
    localparam bit [2:0] WORD_SIZE = 3'b010;
    localparam bit [1:0] OKAY   = 2'b00;
    localparam bit [1:0] SLVERR = 2'b10;

    bit [31:0] shadow_mem[MEMORY_DEPTH];

    function new();
        foreach (shadow_mem[i])
            shadow_mem[i] = 32'h0000_0000;
    endfunction

    function void predict(axi4_write_txn txn);
        int unsigned num_beats;
        int unsigned stride;
        bit          size_valid;
        bit          burst_crosses_4kb;
        bit          start_in_range;
        bit          any_invalid;
        bit [15:0]   beat_addr;
        int unsigned last_byte_offset;

        num_beats = int'(txn.awlen) + 1;
        stride    = 1 << txn.awsize;
        size_valid = (txn.awsize == WORD_SIZE);

        start_in_range = ((txn.awaddr >> 2) < MEMORY_DEPTH);

        last_byte_offset = int'({1'b0, txn.awaddr[11:0]})
                         + (num_beats * stride) - 1;
        burst_crosses_4kb = (last_byte_offset > 12'hFFF);

        txn.beat_word_addr = new[num_beats];
        txn.beat_valid     = new[num_beats];

        any_invalid = 1'b0;
        beat_addr   = txn.awaddr;

        for (int i = 0; i < num_beats; i++) begin
            bit in_range;

            in_range = ((beat_addr >> 2) < MEMORY_DEPTH);

            // All beats of this simplified design's burst are invalid
            // when the burst-level legality check fails.
            txn.beat_valid[i] = size_valid
                             && start_in_range
                             && in_range
                             && !burst_crosses_4kb;

            txn.beat_word_addr[i] = beat_addr >> 2;

            if (txn.beat_valid[i]) begin
                shadow_mem[beat_addr >> 2] = txn.wdata[i];
            end
            else begin
                any_invalid = 1'b1;
            end

            beat_addr = beat_addr + stride;
        end

        txn.exp_bresp = any_invalid ? SLVERR : OKAY;
    endfunction

    function bit [31:0] get_expected(bit [15:0] word_addr);
        return shadow_mem[word_addr];
    endfunction

endclass
