//=============================================================
// axi4_memory.v — CORRECTED
//
// Fixes applied (see AXI4_Memory_Design_Notes.md section 12 for the
// original bug writeup):
//
//   12.1 (CRITICAL): reset check was `if (rst_n)` instead of
//        `if (!rst_n)`. rst_n is active-LOW, so the original code
//        forced mem_rdata=0 every cycle OUT of reset and made the
//        mem_en-gated read/write branch unreachable in normal
//        operation - no write ever reached the array, no read ever
//        returned real data. Fixed by inverting the condition.
//
//   12.2: read used `memory[mem_addr-1]` (off-by-one; wraps to
//        depth-1 at mem_addr==0). Fixed to `memory[mem_addr]`.
//
// Timing is unchanged: still a synchronous, single-port, registered-
// output RAM (mem_addr issued in cycle N -> mem_rdata valid in cycle
// N+1). The axi4.v read FSM has been updated to respect this
// latency correctly (see FIX 12.3 there).
//=============================================================

module axi4_memory #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 10,    // For 1024 locations
    parameter DEPTH = 1024
)(
    input  wire                     clk,
    input  wire                     rst_n,

    input  wire                     mem_en,
    input  wire                     mem_we,
    input  wire [ADDR_WIDTH-1:0]    mem_addr,
    input  wire [DATA_WIDTH-1:0]    mem_wdata,
    output reg  [DATA_WIDTH-1:0]    mem_rdata
);

    // Memory array
    reg [DATA_WIDTH-1:0] memory [0:DEPTH-1];

    integer j;

    // Memory read/write
    always @(posedge clk) begin
        if (!rst_n) begin
            // FIX 12.1: was `if (rst_n)` - inverted polarity.
            mem_rdata <= {DATA_WIDTH{1'b0}};
        end else if (mem_en) begin
            if (mem_we)
                memory[mem_addr] <= mem_wdata;
            else
                // FIX 12.2: was `memory[mem_addr - 1]`.
                mem_rdata <= memory[mem_addr];
        end
    end

    // Initialize memory (simulation only - not synthesizable as-is;
    // add a synthesizable reset/init path if this needs to be a real
    // ASIC/FPGA memory rather than a simulation model).
    initial begin
        for (j = 0; j < DEPTH; j = j + 1)
            memory[j] = {DATA_WIDTH{1'b0}};
    end

endmodule
