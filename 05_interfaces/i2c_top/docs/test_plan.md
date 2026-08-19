# I2C Top Verification Test Plan

## Objective

Verify `i2c_top` as an integrated controller/target pair. Confirm one-byte read
and write data integrity, I2C framing, acknowledge behavior, endpoint status,
request latching, and recovery from reset during an active transaction.

## Configuration

| Item | Value |
|---|---:|
| Target address | `7'h42` |
| Data width | 8 bits |
| Clock divider | 4 system clocks per SCL half-period |
| Bit order | MSB first |
| Testbench DUT | `i2c_top` only |

## Directed Checks

| ID | Priority | Stimulus | Expected result |
|---|---|---|---|
| I2C-001 | P0 | Assert reset | SCL/SDA released HIGH; status and pulses clear |
| I2C-002 | P0 | Write `A5`, `00`, `FF` | Target receives each byte exactly |
| I2C-003 | P0 | Read `3C`, `00`, `FF` | Controller receives each byte exactly |
| I2C-004 | P0 | Observe valid address | Target drives address ACK |
| I2C-005 | P0 | Complete write byte | Target drives data ACK and `rx_valid` pulses once |
| I2C-006 | P0 | Complete read byte | Controller drives final NACK |
| I2C-007 | P0 | Count write/read clocks | Exactly 18 clock pulses per valid transaction |
| I2C-008 | P0 | Observe framing | Exactly one START and one STOP per transaction |
| I2C-009 | P0 | Address `7'h43` | Address NACK, `ack_error=1`, STOP after 9 clocks |
| I2C-010 | P0 | Assert `start` while busy | Active address/direction/payload remain unchanged |
| I2C-011 | P1 | Check completion events | Master/slave done pulses occur once and are one clock wide |
| I2C-012 | P1 | Assert reset mid-frame | Transfer aborts and both bus lines return HIGH |
| I2C-013 | P1 | Start after reset abort | New read completes with correct data |
| I2C-014 | P1 | Complete any transaction | Both endpoints and bus return idle |

## Pass Criteria

- All 96 self-checks pass.
- Questa/ModelSim and Vivado xsim produce matching results.
- RTL and testbench compile without warnings in Questa.
- No watchdog timeout occurs.

## Future Coverage

- Sweep `CLK_DIV` across supported values.
- Sweep all valid 7-bit target addresses.
- Randomize read/write payloads and busy-boundary requests.
- Add assertions for SDA stability while SCL is HIGH.
- Add repeated START, multi-byte transfer, clock stretching, and arbitration tests
  when those features are implemented.
