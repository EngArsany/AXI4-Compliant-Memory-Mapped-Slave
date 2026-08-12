//=============================================================
// axi4_write_env.sv
//
// AXI4 write verification environment.
//
// The first 30 transactions form a coverage-directed constrained-
// random plan. Each transaction is still generated using
// randomize(), with inline constraints selecting the desired
// functional-coverage scenario.
//
// The remaining transactions use the normal transaction constraints.
//=============================================================

class axi4_write_env;

    virtual axi4_write_if.DRIVER  drv_vif;
    virtual axi4_write_if.MONITOR mon_vif;

    axi4_golden_model     gm;
    axi4_write_scoreboard sb;
    axi4_write_coverage   cov;
    axi4_write_driver     drv;
    axi4_write_monitor    mon;
    axi4_backdoor_base    bd;

    localparam int COVERAGE_PLAN_COUNT = 30;

    //=========================================================
    // Constructor
    //=========================================================

    function new(
        virtual axi4_write_if.DRIVER  drv_vif,
        virtual axi4_write_if.MONITOR mon_vif
    );

        this.drv_vif = drv_vif;
        this.mon_vif = mon_vif;

        gm  = new();
        sb  = new(gm);
        cov = new();

        drv = new(drv_vif);
        mon = new(mon_vif);

    endfunction


    //=========================================================
    // Coverage-directed constrained-random transaction
    //
    // IMPORTANT:
    // The constraints are applied INSIDE randomize().
    // This prevents randomization from overwriting the planned
    // values.
    //=========================================================

    function bit randomize_for_coverage_plan(
        axi4_write_txn txn,
        int case_id
    );

        case (case_id)

            //=================================================
            // Valid word-sized writes
            //=================================================

            0: return txn.randomize() with {
                addr_mode == ADDR_NORMAL;
                awlen     == 8'd0;
                awsize    == 3'b010;
            };

            1: return txn.randomize() with {
                addr_mode == ADDR_NORMAL;
                awlen     == 8'd1;
                awsize    == 3'b010;
            };

            2: return txn.randomize() with {
                addr_mode == ADDR_NORMAL;
                awlen     == 8'd7;
                awsize    == 3'b010;
            };

            3: return txn.randomize() with {
                addr_mode == ADDR_NORMAL;
                awlen     == 8'd31;
                awsize    == 3'b010;
            };

            4: return txn.randomize() with {
                addr_mode == ADDR_NORMAL;
                awlen     == 8'd255;
                awsize    == 3'b010;
            };


            //=================================================
            // Near 4-KB boundary
            //=================================================

            5: return txn.randomize() with {
                addr_mode == ADDR_NEAR_BOUNDARY;
                awlen     == 8'd0;
                awsize    == 3'b010;
            };

            6: return txn.randomize() with {
                addr_mode == ADDR_NEAR_BOUNDARY;
                awlen     == 8'd1;
                awsize    == 3'b010;
            };

            7: return txn.randomize() with {
                addr_mode == ADDR_NEAR_BOUNDARY;
                awlen     == 8'd7;
                awsize    == 3'b010;
            };


            //=================================================
            // Out-of-range addresses
            //=================================================

            8: return txn.randomize() with {
                addr_mode == ADDR_OUT_OF_RANGE;
                awlen     == 8'd0;
                awsize    == 3'b010;
            };

            9: return txn.randomize() with {
                addr_mode == ADDR_OUT_OF_RANGE;
                awlen     == 8'd1;
                awsize    == 3'b010;
            };

            10: return txn.randomize() with {
                addr_mode == ADDR_OUT_OF_RANGE;
                awlen     == 8'd7;
                awsize    == 3'b010;
            };


            //=================================================
            // Invalid AWSIZE
            //=================================================

            11: return txn.randomize() with {
                addr_mode == ADDR_NORMAL;
                awlen     == 8'd0;
                awsize    == 3'b000;
            };

            12: return txn.randomize() with {
                addr_mode == ADDR_NORMAL;
                awlen     == 8'd1;
                awsize    == 3'b001;
            };

            13: return txn.randomize() with {
                addr_mode == ADDR_NORMAL;
                awlen     == 8'd7;
                awsize    == 3'b011;
            };

            14: return txn.randomize() with {
                addr_mode == ADDR_NORMAL;
                awlen     == 8'd31;
                awsize    == 3'b111;
            };


            //=================================================
            // Unaligned word accesses
            //=================================================

            15: return txn.randomize() with {
                addr_mode == ADDR_UNALIGNED;
                awlen     == 8'd0;
                awsize    == 3'b010;
            };

            16: return txn.randomize() with {
                addr_mode == ADDR_UNALIGNED;
                awlen     == 8'd1;
                awsize    == 3'b010;
            };

            17: return txn.randomize() with {
                addr_mode == ADDR_UNALIGNED;
                awlen     == 8'd7;
                awsize    == 3'b010;
            };


            //=================================================
            // Additional valid word bursts
            //=================================================

            18: return txn.randomize() with {
                addr_mode == ADDR_NORMAL;
                awlen     == 8'd2;
                awsize    == 3'b010;
            };

            19: return txn.randomize() with {
                addr_mode == ADDR_NORMAL;
                awlen     == 8'd15;
                awsize    == 3'b010;
            };


            //=================================================
            // Additional near-boundary cases
            //=================================================

            20: return txn.randomize() with {
                addr_mode == ADDR_NEAR_BOUNDARY;
                awlen     == 8'd2;
                awsize    == 3'b010;
            };

            21: return txn.randomize() with {
                addr_mode == ADDR_NEAR_BOUNDARY;
                awlen     == 8'd15;
                awsize    == 3'b010;
            };


            //=================================================
            // Additional out-of-range case
            //=================================================

            22: return txn.randomize() with {
                addr_mode == ADDR_OUT_OF_RANGE;
                awlen     == 8'd31;
                awsize    == 3'b010;
            };


            //=================================================
            // Additional invalid AWSIZE cases
            //=================================================

            23: return txn.randomize() with {
                addr_mode == ADDR_NORMAL;
                awlen     == 8'd0;
                awsize    == 3'b000;
            };

            24: return txn.randomize() with {
                addr_mode == ADDR_NORMAL;
                awlen     == 8'd0;
                awsize    == 3'b001;
            };

            25: return txn.randomize() with {
                addr_mode == ADDR_NORMAL;
                awlen     == 8'd0;
                awsize    == 3'b011;
            };

            26: return txn.randomize() with {
                addr_mode == ADDR_NORMAL;
                awlen     == 8'd0;
                awsize    == 3'b100;
            };


            //=================================================
            // More valid word burst lengths
            //=================================================

            27: return txn.randomize() with {
                addr_mode == ADDR_NORMAL;
                awlen     == 8'd3;
                awsize    == 3'b010;
            };

            28: return txn.randomize() with {
                addr_mode == ADDR_NORMAL;
                awlen     == 8'd63;
                awsize    == 3'b010;
            };

            29: return txn.randomize() with {
                addr_mode == ADDR_NORMAL;
                awlen     == 8'd127;
                awsize    == 3'b010;
            };


            default:
                return txn.randomize();

        endcase

    endfunction


    //=========================================================
    // Main test
    //=========================================================

    task run(int num_txns);

        axi4_write_txn txn;

        // Backdoor must be supplied by tb_top.
        if (bd == null) begin
            $fatal(
                1,
                "[ENV] Backdoor implementation was not assigned"
            );
        end

        // Initialize driver outputs.
        drv.reset_signals();

        // Wait for reset release.
        wait (drv_vif.ARESETn === 1'b1);

        repeat (2)
            @(posedge drv_vif.ACLK);

        $display("");
        $display("====================================================");
        $display("[ENV] Starting %0d write transactions", num_txns);
        $display("====================================================");


        //=====================================================
        // Transaction loop
        //=====================================================

        for (int n = 0; n < num_txns; n++) begin

            txn = new();


            //=================================================
            // Generate transaction
            //=================================================

            if (n < COVERAGE_PLAN_COUNT) begin

                if (!randomize_for_coverage_plan(txn, n)) begin

                    $fatal(
                        1,
                        "[ENV] Coverage-plan randomization failed on txn %0d",
                        n
                    );

                end

            end
            else begin

                if (!txn.randomize()) begin

                    $fatal(
                        1,
                        "[ENV] Randomization failed on txn %0d",
                        n
                    );

                end

            end


            //=================================================
            // Golden-model prediction
            //=================================================

            gm.predict(txn);


            //=================================================
            // Transaction information
            //=================================================

            $display(
                "[ENV] txn %0d: AWADDR=0x%04h AWLEN=%0d AWSIZE=%0d mode=%s",
                n,
                txn.awaddr,
                txn.awlen,
                txn.awsize,
                txn.addr_mode.name()
            );


            //=================================================
            // Drive and monitor concurrently
            //=================================================

            fork

                drv.drive_one(txn);

                mon.observe_one(txn);

            join


            //=================================================
            // Check BRESP
            //=================================================

            sb.check_bresp(txn);


            //=================================================
            // Check memory contents
            //
            // Only beats predicted as valid are read through
            // the backdoor.
            //=================================================

            foreach (txn.beat_word_addr[i]) begin

                if (txn.beat_valid[i]) begin

                    sb.check_data(
                        txn,
                        i,
                        bd.read(txn.beat_word_addr[i][9:0])
                    );

                end

            end


            //=================================================
            // Functional coverage
            //=================================================

            cov.sample(txn);

        end


        //=====================================================
        // Final report
        //=====================================================

        $display("");
        $display("====================================================");
        $display("[ENV] All %0d transactions completed", num_txns);
        $display("====================================================");

        sb.report();

        $display(
            "[ENV] Burst functional coverage = %0.2f%%",
            cov.get_burst_coverage()
        );

        $display(
            "[ENV] Beat functional coverage = %0.2f%%",
            cov.get_beat_coverage()
        );

        $display(
            "[ENV] Combined functional coverage = %0.2f%%",
            cov.get_coverage()
        );


        //=====================================================
        // Stop the test if scoreboard detected an error.
        //=====================================================

        if ((sb.num_bresp_errors != 0) ||
            (sb.num_data_errors  != 0)) begin

            $fatal(
                1,
                "[ENV] Scoreboard failures detected."
            );

        end

    endtask

endclass