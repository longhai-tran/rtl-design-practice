# UART Top Verification Test Plan

## Objective

Verify that `uart_top` integrates the standalone transmitter and receiver with
consistent parameters, preserves both child-module handshakes, supports
simultaneous activity, propagates receive errors, and recovers from reset.

## Configuration

| Item | Value |
|---|---:|
| System clock | 8 MHz simulation model |
| Baud rate | 1 MHz simulation model |
| Clocks per bit | 8 |
| Frame format | 8N1, LSB-first |
| Loopback | Testbench-controlled external TX-to-RX connection |

## Directed Checks

| ID | Priority | Stimulus | Expected result |
|---|---|---|---|
| TOP-001 | P0 | Assert synchronous reset | TX and RX outputs return idle |
| TOP-002 | P0 | Hold both serial lines idle | No completion or error events |
| TOP-003 | P0 | Loop back representative bytes | RX returns exact transmitted data |
| TOP-004 | P0 | Observe loopback handshakes | One TX done and one RX valid per byte |
| TOP-005 | P0 | Request TX while busy | Active byte preserved; no extra frame |
| TOP-006 | P0 | Request TX after completion | New request is accepted normally |
| TOP-007 | P0 | Inject a LOW RX stop bit | Framing error propagates to top output |
| TOP-008 | P0 | Send valid frame after RX error | RX returns to normal operation |
| TOP-009 | P1 | Assert reset during loopback | Both child state machines abort cleanly |
| TOP-010 | P1 | Send after reset abort | TX and RX restart without stale events |

## Pass Criteria

The test passes when all 45 self-checking assertions pass on ModelSim/Questa and
Vivado xsim, all four RTL/TB sources compile without warnings, and no timeout
watchdog fires.

## Future Coverage

- Drive independent TX and RX frames concurrently with different payloads.
- Randomize TX request spacing around busy and done boundaries.
- Sweep legal clock/baud parameter combinations.
- Inject baud mismatch and randomized RX phase offsets.
- Add FIFO, parity, overrun, break, and flow-control tests when implemented.
