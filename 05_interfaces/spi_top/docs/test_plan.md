# SPI Top Verification Test Plan

## Objective

Verify the integrated SPI master/slave pair through `spi_top` only. Confirm
full-duplex data integrity, mode behavior, bus timing, endpoint status, busy
request rejection, and shared-reset recovery.

## Configuration

| Item | Value |
|---|---:|
| Data width | 8 bits |
| Clock divider | 3 system clocks per half-period |
| Bit order | MSB-first |
| Top instances | Four, one for each SPI mode |
| Testbench DUT type | `spi_top` only |

## Directed Checks

| ID | Priority | Stimulus | Expected result |
|---|---|---|---|
| TOP-001 | P0 | Assert shared reset | Both endpoints and bus return idle |
| TOP-002 | P0 | Start Mode 0 exchange | Both directions receive exact words |
| TOP-003 | P0 | Start Mode 1 exchange | Both directions receive exact words |
| TOP-004 | P0 | Start Mode 2 exchange | Both directions receive exact words |
| TOP-005 | P0 | Start Mode 3 exchange | Both directions receive exact words |
| TOP-006 | P0 | Count bus transitions | Exactly two SCLK edges per data bit |
| TOP-007 | P0 | Complete transaction | One done event from each endpoint |
| TOP-008 | P0 | Observe pulse width | Both done outputs are one clock wide |
| TOP-009 | P0 | Assert start while busy | Active words remain latched; no extra exchange |
| TOP-010 | P1 | Exchange `0x00` and `0xFF` | Boundary words are preserved both ways |
| TOP-011 | P1 | Assert reset during exchange | Both FSMs abort without completion |
| TOP-012 | P1 | Start after reset abort | Integrated pair completes cleanly |
| TOP-013 | P1 | Observe idle after completion | CS inactive and SCLK returns to CPOL |

## Pass Criteria

The test passes when all 76 checks pass on ModelSim/Questa and Vivado xsim,
all four source modules compile without warnings, and the watchdog does not fire.

## Future Coverage

- Sweep `DATA_WIDTH` and `CLK_DIV` across supported values.
- Randomize independent master and slave payloads.
- Randomize busy-boundary start pulses.
- Add cycle-accurate half-period assertions.
- Add external asynchronous slave verification with synchronizers.
- Add burst, FIFO, multi-slave, and LSB-first configurations when implemented.
