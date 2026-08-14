//=============================================================
// axi4.v — CORRECTED
//
// Fixes applied (see AXI4_Memory_Design_Notes.md section 12 for the
// original bug writeup). Each fix is tagged inline with its bug
// number from that document.
//
//   12.4 Boundary-cross formula was AWLEN*(1<<AWSIZE), missing the
//        "+1 beat" / "-1 last byte" terms (under-counts by
//        bytes_per_beat-1). Corrected to (AWLEN+1)*(1<<AWSIZE)-1,
//        and moved to be evaluated ONCE at the address phase
//        (against the burst's actual start address/length/size)
//        instead of being recomputed every beat off the moving
//        write_addr/read_addr register combined with the original,
//        never-decremented burst length - that recomputation was an
//        additional latent bug beyond the formula itself.
//
//   12.5 BRESP reflected only the last beat's validity instead of
//        the whole burst. Fixed with a sticky `write_err` flag,
//        latched once at the address phase and used unchanged for
//        the whole burst's response.
//
//   12.6 Read error path ran the full requested burst length instead
//        of terminating on the first invalid beat. Fixed: RLAST is
//        now forced high (and the burst ends) on the very first
//        error beat.
//
//   12.7 No WSTRB exists (see design-notes.md sections 6/8), so a
//        sub- or over-word AWSIZE/ARSIZE cannot be handled correctly
//        (the datapath can only move a full 32-bit word per beat).
//        Rather than silently corrupting adjacent bytes, a beat with
//        AWSIZE/ARSIZE != 3'b010 (word) is now treated as invalid
//        and answered with SLVERR. This is a design decision, not a
//        protocol requirement - if byte-lane support is actually
//        needed, add a WSTRB port and per-lane write masking instead
//        of rejecting the transfer.
//
//   12.3 Read-data pipeline latency mismatch: the read FSM issued
//        the next mem_addr and consumed the current mem_rdata in the
//        same state, one cycle before axi4_memory's registered
//        output was actually valid. Fixed by adding explicit
//        R_ISSUE -> R_WAIT -> R_DATA pipeline stages, so mem_rdata is
//        only sampled a full cycle after axi4_memory's own update.
//        TRADE-OFF: this costs one extra idle cycle between read
//        beats (throughput drops from 1 beat/cycle to roughly 1 beat
//        per 3 cycles for back-to-back valid beats). A production
//        design wanting full throughput would instead pipeline
//        address-issue-for-beat-N+1 with data-return-for-beat-N;
//        that optimization is out of scope here in favor of a simple,
//        obviously-correct fix.
//
//   12.8 write_boundary_cross/read_boundary_cross/write_addr_valid/
//        read_addr_valid relied on implicit net declaration. All
//        internal signals below are explicitly declared.
//=============================================================

module axi4 #(
    parameter DATA_WIDTH   = 32,
    parameter ADDR_WIDTH   = 16,
    parameter MEMORY_DEPTH = 1024
)(
    input  wire                     ACLK,
    input  wire                     ARESETn,

    // ---- Write Address Channel ----
    input  wire [ADDR_WIDTH-1:0]    AWADDR,
    input  wire [7:0]               AWLEN,
    input  wire [2:0]               AWSIZE,
    input  wire                     AWVALID,
    output reg                      AWREADY,

    // ---- Write Data Channel ----
    input  wire [DATA_WIDTH-1:0]    WDATA,
    input  wire                     WVALID,
    input  wire                     WLAST,
    output reg                      WREADY,

    // ---- Write Response Channel ----
    output reg  [1:0]               BRESP,
    output reg                      BVALID,
    input  wire                     BREADY,

    // ---- Read Address Channel ----
    input  wire [ADDR_WIDTH-1:0]    ARADDR,
    input  wire [7:0]               ARLEN,
    input  wire [2:0]               ARSIZE,
    input  wire                     ARVALID,
    output reg                      ARREADY,

    // ---- Read Data Channel ----
    output reg  [DATA_WIDTH-1:0]    RDATA,
    output reg  [1:0]               RRESP,
    output reg                      RVALID,
    output reg                      RLAST,
    input  wire                     RREADY
);

    localparam [1:0] RESP_OKAY   = 2'b00;
    localparam [1:0] RESP_SLVERR = 2'b10;
    localparam [2:0] WORD_SIZE   = 3'b010;   // only fully-supported AxSIZE - see FIX 12.7

    localparam [2:0] W_IDLE = 3'd0,
                      W_DATA = 3'd1,
                      W_RESP = 3'd2;

    localparam [2:0] R_IDLE  = 3'd0,
                      R_ISSUE = 3'd1,
                      R_WAIT  = 3'd2,
                      R_DATA  = 3'd3;

    reg [2:0] write_state;
    reg [2:0] read_state;

    // Internal memory-port signals
    reg                              mem_en, mem_we;
    reg  [$clog2(MEMORY_DEPTH)-1:0]  mem_addr;
    reg  [DATA_WIDTH-1:0]            mem_wdata;
    wire [DATA_WIDTH-1:0]            mem_rdata;

    // Burst bookkeeping
    reg [ADDR_WIDTH-1:0] write_addr, read_addr;
    reg [7:0]             write_burst_cnt, read_burst_cnt;
    reg [2:0]             write_size, read_size;
    reg                   write_err, read_err;   // sticky per-burst error flags (FIX 12.5/12.6)

    // FIX 12.8: explicit wire declarations (previously implicit nets)
    wire [ADDR_WIDTH-1:0] write_addr_incr, read_addr_incr;
    assign write_addr_incr = {{(ADDR_WIDTH-3){1'b0}}, 3'b001} << write_size;
    assign read_addr_incr  = {{(ADDR_WIDTH-3){1'b0}}, 3'b001} << read_size;

    // Per-beat range check - cheap defense-in-depth, re-evaluated
    // every beat against the CURRENT (incrementing) address. This is
    // independent of write_err/read_err, which capture the
    // burst-level boundary/size decision made once at the address
    // phase.
    wire write_addr_valid;
    wire read_addr_valid;
    assign write_addr_valid = (write_addr >> 2) < MEMORY_DEPTH;
    assign read_addr_valid  = (read_addr  >> 2) < MEMORY_DEPTH;

    // ---- Memory instance ----
    axi4_memory #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH($clog2(MEMORY_DEPTH)),
        .DEPTH(MEMORY_DEPTH)
    ) mem_inst (
        .clk      (ACLK),
        .rst_n    (ARESETn),
        .mem_en   (mem_en),
        .mem_we   (mem_we),
        .mem_addr (mem_addr),
        .mem_wdata(mem_wdata),
        .mem_rdata(mem_rdata)
    );

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            AWREADY <= 1'b1;
            WREADY  <= 1'b0;
            BVALID  <= 1'b0;
            BRESP   <= RESP_OKAY;

            ARREADY <= 1'b1;
            RVALID  <= 1'b0;
            RRESP   <= RESP_OKAY;
            RDATA   <= {DATA_WIDTH{1'b0}};
            RLAST   <= 1'b0;

            write_state <= W_IDLE;
            read_state  <= R_IDLE;

            mem_en    <= 1'b0;
            mem_we    <= 1'b0;
            mem_addr  <= {$clog2(MEMORY_DEPTH){1'b0}};
            mem_wdata <= {DATA_WIDTH{1'b0}};

            write_addr      <= {ADDR_WIDTH{1'b0}};
            read_addr       <= {ADDR_WIDTH{1'b0}};
            write_burst_cnt <= 8'd0;
            read_burst_cnt  <= 8'd0;
            write_size      <= 3'd0;
            read_size       <= 3'd0;
            write_err       <= 1'b0;
            read_err        <= 1'b0;

        end else begin
            // Default every cycle; explicitly re-asserted where needed.
            mem_en <= 1'b0;
            mem_we <= 1'b0;

            //=====================================================
            // Write Channel FSM
            //=====================================================
            case (write_state)

                W_IDLE: begin
                    AWREADY <= 1'b1;
                    WREADY  <= 1'b0;
                    BVALID  <= 1'b0;

                    if (AWVALID && AWREADY) begin
                        write_addr      <= AWADDR;
                        write_burst_cnt <= AWLEN;
                        write_size      <= AWSIZE;
                        AWREADY         <= 1'b0;

                        // FIX 12.4: correct boundary formula,
                        // evaluated once here against the burst's
                        // actual start address/length/size.
                        // last_byte_offset = (AWLEN+1)*(1<<AWSIZE) - 1
                        // FIX 12.7: reject any non-word AWSIZE (no
                        // WSTRB available to do it correctly).
                        write_err <= ( (AWADDR[11:0] +
                                        (({12'd0, AWLEN} + 20'd1) << AWSIZE) - 20'd1)
                                       > 20'hFFF )
                                     || ((AWADDR >> 2) >= MEMORY_DEPTH)
                                     || (AWSIZE != WORD_SIZE);

                        write_state <= W_DATA;
                        WREADY      <= 1'b1;
                    end
                end

                W_DATA: begin
                    if (WVALID && WREADY) begin
                        if (write_addr_valid && !write_err) begin
                            mem_en    <= 1'b1;
                            mem_we    <= 1'b1;
                            mem_addr  <= write_addr >> 2;
                            mem_wdata <= WDATA;
                        end

                        if (WLAST || write_burst_cnt == 8'd0) begin
                            WREADY      <= 1'b0;
                            write_state <= W_RESP;
                            // FIX 12.5: BRESP now reflects the
                            // accumulated per-burst error, not just
                            // this final beat.
                            BRESP  <= (write_err || !write_addr_valid) ? RESP_SLVERR : RESP_OKAY;
                            BVALID <= 1'b1;
                        end else begin
                            write_addr      <= write_addr + write_addr_incr;
                            write_burst_cnt <= write_burst_cnt - 8'd1;
                        end
                    end
                end

                W_RESP: begin
                    if (BVALID && BREADY) begin
                        BVALID      <= 1'b0;
                        BRESP       <= RESP_OKAY;
                        write_state <= W_IDLE;
                    end
                end

                default: write_state <= W_IDLE;
            endcase

            //=====================================================
            // Read Channel FSM
            // FIX 12.3: R_ISSUE -> R_WAIT -> R_DATA pipeline so
            // mem_rdata is sampled a full cycle after axi4_memory's
            // own registered update.
            // FIX 12.6: an invalid beat now ends the burst
            // immediately (RLAST forced high on the first error
            // beat) instead of running the full requested length.
            //=====================================================
            case (read_state)

                R_IDLE: begin
                    ARREADY <= 1'b1;
                    RVALID  <= 1'b0;
                    RLAST   <= 1'b0;

                    if (ARVALID && ARREADY) begin
                        read_addr      <= ARADDR;
                        read_burst_cnt <= ARLEN;
                        read_size      <= ARSIZE;
                        ARREADY        <= 1'b0;

                        // FIX 12.4 (read side) / 12.7, same as write.
                        read_err <= ( (ARADDR[11:0] +
                                       (({12'd0, ARLEN} + 20'd1) << ARSIZE) - 20'd1)
                                      > 20'hFFF )
                                    || ((ARADDR >> 2) >= MEMORY_DEPTH)
                                    || (ARSIZE != WORD_SIZE);

                        read_state <= R_ISSUE;
                    end
                end

                R_ISSUE: begin
                    if (read_addr_valid && !read_err) begin
                        mem_en     <= 1'b1;
                        mem_addr   <= read_addr >> 2;
                        read_state <= R_WAIT;
                    end else begin
                        // Invalid beat: no memory access, go straight
                        // to presenting the error response.
                        read_state <= R_DATA;
                    end
                end

                R_WAIT: begin
                    // One idle cycle: axi4_memory's registered
                    // mem_rdata becomes valid at the end of this
                    // cycle - safe to sample starting next state.
                    read_state <= R_DATA;
                end

                R_DATA: begin
                    if (read_addr_valid && !read_err) begin
                        RDATA <= mem_rdata;
                        RRESP <= RESP_OKAY;
                        RLAST <= (read_burst_cnt == 8'd0);
                    end else begin
                        RDATA <= {DATA_WIDTH{1'b0}};
                        RRESP <= RESP_SLVERR;
                        // FIX 12.6: force immediate termination.
                        RLAST <= 1'b1;
                    end
                    RVALID <= 1'b1;

                    if (RVALID && RREADY) begin
                        RVALID <= 1'b0;

                        if (!read_addr_valid || read_err) begin
                            read_state <= R_IDLE;       // error beat already ended the burst
                        end else if (read_burst_cnt == 8'd0) begin
                            read_state <= R_IDLE;       // last good beat
                        end else begin
                            read_addr      <= read_addr + read_addr_incr;
                            read_burst_cnt <= read_burst_cnt - 8'd1;
                            read_state     <= R_ISSUE;
                        end
                    end
                end

                default: read_state <= R_IDLE;
            endcase
        end
    end

endmodule
