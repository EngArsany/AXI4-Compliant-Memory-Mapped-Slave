# AXI4 Verification Environment

## Project Overview

This project implements a comprehensive verification environment for an AXI4 memory controller using SystemVerilog and UVM-style methodology. The environment includes both read and write channel verification components, functional coverage, assertions, and a reference model.

## Architecture

### Directory Structure

```txt
AXI4_Project/
├── rtl/                          # RTL design files
│   ├── axi4.v                    # Top-level AXI4 module
│   └── axi_memory.v              # Memory implementation
├── tb/                           # Testbench files
│   ├── shared/                   # Shared verification components
│   │   ├── axi4_if.sv           # AXI4 interface definition
│   │   └── axi4_reference_model.sv # Reference model
│   ├── read/                     # Read channel components
│   │   ├── axi4_read_transaction.sv
│   │   ├── axi4_read_generator.sv
│   │   ├── axi4_read_driver.sv
│   │   ├── axi4_read_monitor.sv
│   │   ├── axi4_read_scoreboard.sv
│   │   └── axi4_read_coverage.sv
│   ├── write/                    # Write channel components
│   │   ├── axi4_write_transaction.sv
│   │   ├── axi4_write_generator.sv
│   │   ├── axi4_write_driver.sv
│   │   ├── axi4_write_monitor.sv
│   │   ├── axi4_write_scoreboard.sv
│   │   ├── axi4_write_coverage.sv
│   │   ├── axi4_write_golden_model.sv
│   │   └── axi4_backdoor_base.sv
│   ├── env/                      # Environment
│   │   └── axi4_env.sv          # Top-level environment
│   └── top/                      # Testbench top
│       └── axi4_tb_top.sv        # Testbench top module
└── sim_out/                      # Simulation output
    ├── Main.log                  # Simulation log
    ├── functional_coverage_report.txt
    ├── assertion_coverage_report.txt
    ├── branch_coverage_report.txt
    ├── condition_expression_coverage_report.txt
    ├── fsm_coverage_report.txt
    ├── statement_coverage_report.txt
    ├── toggle_coverage_report.txt
    └── overall_coverage_report.txt
```

## Verification Components

### AXI4 Interface (`axi4_if.sv`)

- Defines all AXI4 signals for:
  - Write Address Channel (AW)
  - Write Data Channel (W)
  - Write Response Channel (B)
  - Read Address Channel (AR)
  - Read Data Channel (R)
- Provides DRIVER and MONITOR modports
- Includes protocol assertions

### Transaction Classes

#### Read Transaction (`axi4_read_transaction.sv`)

- Random fields: `araddr`, `arlen`, `arsize`
- Queues: `rdata`, `rresp`, `rlast`
- Methods:
  - `is_valid_burst()`: Checks burst legality
  - `expected_r_beats()`: Returns expected transfer count

#### Write Transaction (`axi4_write_transaction.sv`)

- Random fields: `awaddr`, `awlen`, `awsize`, `addr_mode`
- Data storage: `wdata[]`, `beat_word_addr[]`, `beat_valid[]`
- Expected/actual response: `exp_bresp`, `act_bresp`

### Generator

#### Read Generator (`axi4_read_generator.sv`)

- 27 directed test cases covering:
  - Normal bursts (single to 256 beats)
  - 4KB boundary crossing
  - Memory range violations
  - Alignment violations
  - Unsupported transfer sizes
- Additional 200 random transactions

#### Write Generator (`axi4_write_generator.sv`)

- 34 directed test cases covering:
  - Valid word-sized writes (various lengths)
  - Near 4KB boundary addresses
  - Out-of-range addresses
  - Unaligned accesses
- Additional 200 random transactions

### Driver

#### Read Driver (`axi4_read_driver.sv`)

- Drives AR channel: ARADDR, ARLEN, ARSIZE, ARVALID
- Drives R channel: RREADY (with stall insertion)
- Validates R-beat count matches expected

#### Write Driver (`axi4_write_driver.sv`)

- Drives AW, W, and B channels
- Implements full AXI4 write handshake sequence

### Monitor

#### Read Monitor (`axi4_read_monitor.sv`)

- Observes AR and R channels
- Captures all R beats including RLAST
- Packages transaction for scoreboard

#### Write Monitor (`axi4_write_monitor.sv`)

- Observes AW, W, and B channels
- Validates W beat count matches AWLEN+1

### Scoreboard

#### Read Scoreboard (`axi4_read_scoreboard.sv`)

- Compares expected vs actual:
  - Address/control signals
  - RDATA per beat
  - RRESP per beat
  - RLAST sequence
- Collects error statistics

#### Write Scoreboard (`axi4_write_scoreboard.sv`)

- Compares expected vs actual BRESP

### Reference Model (`axi4_reference_model.sv`)

- Maintains expected memory state
- Predicts read responses
- Applies write transactions
- Validates burst legality

### Coverage

#### Read Coverage (`axi4_read_coverage.sv`)

- Coverpoints:
  - Address region and alignment
  - Burst length and size
  - Burst validity
  - Read response
  - RLAST behavior
  - Beat count
- Cross coverage:
  - Validity × Length/Address/Size/Response/Alignment
  - Size × Response
  - Length × Response

#### Write Coverage (`axi4_write_coverage.sv`)

- Coverpoints:
  - AWLEN, AWSIZE
  - Address mode and alignment
  - Start region
  - BRESP
- Beat-level coverage:
  - Valid/invalid beats
  - Beat position (first/last/middle/only)
  - Beat address region

## Test Plan

### Key Test Scenarios

#### Read Channel

| Test ID | Description | Status |
| --------- | ------------- | -------- |
| RTM-R01 | Single beat at base address | ✅ |
| RTM-R02 | Two-beat burst | ✅ |
| RTM-R03 | Short burst (8 beats) | ✅ |
| RTM-R04 | Medium burst (32 beats) | ❌ Data errors |
| RTM-R05 | Long burst (64 beats) | ❌ Data errors |
| RTM-R06 | Maximum 256-beat burst | ❌ Data errors |
| RTM-R07 | Last aligned word (0xFFC) | ✅ |
| RTM-R08 | Burst exactly at 4KB boundary | ❌ |
| RTM-R09 | 4KB boundary crossing by 1 beat | ❌ |
| RTM-R10 | 4KB crossing longer burst | ❌ |
| RTM-R11 | First address outside memory | ✅ |
| RTM-R12 | Highest address (0xFFFC) | ✅ |
| RTM-R13 | Burst exceeds memory | ❌ |
| RTM-R14 | Byte unaligned | ❌ |
| RTM-R15 | Halfword unaligned | ❌ |
| RTM-R16 | Word unaligned | ❌ |
| RTM-R17 | Byte transfer size (ARSIZE=0) | ❌ |
| RTM-R18 | Halfword transfer size (ARSIZE=1) | ❌ |
| RTM-R19 | Doubleword transfer size (ARSIZE=3) | ❌ |
| RTM-R20 | Unsupported large transfer size (ARSIZE=7) | ❌ |
| RTM-R21 | Valid extended burst | ❌ |
| RTM-R22 | Valid max-minus-one burst | ❌ |
| RTM-R23-R27 | Various invalid cases | ❌ |

#### Write Channel

| Test ID | Description | Status |
| --------- | ------------- | -------- |
| RTM-W01 | Single beat | ✅ |
| RTM-W02 | Two-beat burst | ❌ BRESP mismatch |
| RTM-W03 | Short burst (8 beats) | ✅ |
| RTM-W04 | Medium burst (32 beats) | ✅ |
| RTM-W05 | Maximum 256-beat burst | ❌ |
| RTM-W06-W08 | Near 4KB boundary | ✅ |
| RTM-W09-W11 | Out-of-range addresses | ✅ |
| RTM-W15-W17 | Unaligned accesses | ✅ |
| RTM-W30-W33 | Unsupported transfer sizes | ❌ |

### Coverage Results

| Coverage Metric | Result |
| ----------------- | -------- |
| Functional Coverage | 98.80% |
| Assertion Coverage | 75.00% |
| Branch Coverage | 77.43% |
| Statement Coverage | 91.78% |
| FSM Coverage | 85.00% |
| Toggle Coverage | 63.70% |
| Condition Coverage | 47.31% |

## Issues Found

### Read Channel Issues

1. **RDATA Mismatches (975 errors)**
   - Valid burst reads return zeros instead of expected data
   - Reference model has data but DUT doesn't read from memory
   - Affects: RTM-R04, R05, R06, R08, R21, R22, R151, R189

2. **RRESP Mismatches (209 errors)**
   - Invalid bursts return OKAY instead of SLVERR
   - Affects: RTM-R08, R14-R20, R23-R27

3. **RLAST Mismatches (199 errors)**
   - RLAST not set correctly on invalid bursts
   - Beat count mismatches causing RLAST sequence issues

4. **R-Beat Count Mismatches**
   - Invalid bursts sometimes produce multiple beats
   - Beat count mismatch in driver (expected=1, actual>1)

5. **Assertion Failures**
   - `a_invalid_read_returns_slverr`: 9 failures
   - Invalid reads not returning SLVERR + RLAST

### Write Channel Issues

1. **BRESP Mismatches (29 errors)**
   - Expected SLVERR but got OKAY for:
     - Sub-word transfers (AWSIZE=0,1)
     - Oversize transfers (AWSIZE=3,4,7)
     - Some valid bursts incorrectly returning SLVERR
   - Example: AWADDR=0xc24 AWSIZE=3 expected SLVERR got OKAY

## SystemVerilog Assertions

### Protocol Assertions

| Assertion | Status | Description |
| ----------- | -------- | ------------- |
| a_aw_payload_known | ✅ | AW payload known when accepted |
| a_aw_payload_stable | ⏳ | AW payload stable when stalled |
| a_w_payload_known | ✅ | W payload known when accepted |
| a_w_payload_stable | ⏳ | W payload stable when stalled |
| a_wlast_requires_wvalid | ✅ | WLAST requires WVALID |
| a_bresp_legal | ✅ | BRESP must be OKAY or SLVERR |
| a_bresp_stable | ✅ | BRESP stable when stalled |
| a_ar_payload_known | ✅ | AR payload known when accepted |
| a_ar_payload_stable | ⏳ | AR payload stable when stalled |
| a_r_payload_known | ✅ | R payload known when accepted |
| a_r_payload_stable | ✅ | R payload stable when stalled |
| a_rlast_requires_rvalid | ✅ | RLAST requires RVALID |
| a_rresp_legal | ✅ | RRESP must be OKAY or SLVERR |

### Design-Specific Assertions

| Assertion | Status | Description |
| ----------- | -------- | ------------- |
| a_read_address_stable | ⏳ | AR control stable while ARVALID/!ARREADY |
| a_read_response_legal | ✅ | RRESP legal (OKAY/SLVERR) |
| a_rlast_requires_rvalid | ✅ | RLAST requires RVALID |
| a_read_data_stable_when_stalled | ✅ | R payload stable while stalled |
| a_invalid_read_returns_slverr | ❌ | Invalid read returns SLVERR + RLAST |
| a_rlast_is_terminal | ✅ | RLAST deasserts next cycle |

## Functional Coverage

Read Coverage - 100.00% Achieved

All 76 coverage bins were successfully hit:

- All coverpoints: 100% covered

- All cross coverage: 100% covered

- 8 illegal values (wrong ARSIZE) were correctly sampled as illegal bins

Key Insight: Functional coverage is complete, but verification is still failing - indicating the coverage model is comprehensive but the DUT has fundamental issues.
Write Coverage - 100.00% Achieved

All 50 coverage bins were successfully hit:

- All coverpoints: 100% covered

- All cross coverage: 100% covered

- Illegal bins correctly identified (unaligned, wrong_write_size, unreachable)

Key Insight: Similar to read coverage, 100% functional coverage achieved while verification failures persist

## Getting Started

### Prerequisites

- QuestaSim 2021.1 or compatible
- SystemVerilog support

### Running Tests

1. **Complete Regression**

   ```tcl
   source run_all.do
   ```

2. **Individual Test Components**

   ```tcl
   # Run only write tests
   vsim -c -do "run_write_only.do" tb_top
  
   # Run only read tests  
   vsim -c -do "run_read_only.do" tb_top
   ```

3. **Coverage Collection**

   ```tcl
   # Enable coverage
   vlog -sv "+cover=sbceft" <files>
   
   # View coverage
   coverage report -details
   ```

### Simulation Results

After running the testbench, the following outputs are generated:

```text
Simulation Time: 656,570 ns
Write Transactions: 200 (29 failures)
Read Transactions: 227 (multiple failures)
Functional Coverage: 98.80%
```

## Known Issues

### Critical Issues

1. **Read Data Path**: DUT not returning correct data from memory
2. **Invalid Burst Handling**: Missing SLVERR responses
3. **Beat Counting**: Invalid bursts generating multiple beats

### Recommended Fixes

1. Debug memory read path in `axi4.v` and `axi_memory.v`
2. Fix burst validity logic in DUT
3. Add proper error response generation
4. Validate beat count logic for invalid bursts

## Future Work

1. **Bug Fixes**
   - Fix read data path
   - Implement proper SLVERR responses
   - Fix beat counting for invalid bursts

2. **Coverage Improvements**
   - Increase toggle coverage (currently 63.70%)
   - Improve condition coverage (currently 47.31%)
   - Hit uncovered functional coverage bins

3. **Enhancements**
   - Add backdoor memory access
   - Implement more directed test cases
   - Add formal verification
   - Support more AXI4 features (exclusive accesses, atomic ops)

4. **Performance**
   - Optimize simulation time
   - Add parallel test execution

## Team and Contact

- **Developer**: Arsany Hany & Ziad Orabi
- **Project**: AXI4 Memory Controller Verification
- **Date**: August 18, 2026

## License

This project is for educational purposes. All rights reserved.
