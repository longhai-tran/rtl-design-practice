# UART RX Verification Test Plan

## Objective

Verify that `uart_rx` receives 8N1 frames at the configured baud rate, updates
data only for valid frames, rejects false starts, reports invalid stop bits,
and returns to a usable idle state after errors or reset.

## Configuration

| Item | Value |
|---|---:|
| System clock | 8 MHz simulation model |
| Baud rate | 1 MHz simulation model |
| Clocks per bit | 8 |
| Frame format | 8N1, LSB-first |
| Reset | Active-low synchronous |

## Checks

| ID | Priority | Stimulus | Expected result |
|---|---|---|---|
| RX-001 | P0 | Assert reset while RX is idle | Outputs return to reset values |
| RX-002 | P0 | Hold RX HIGH | No receive event or error |
| RX-003 | P0 | Send representative valid bytes | Exact byte appears on `data_out` |
| RX-004 | P0 | Complete a valid frame | One `rx_done_valid` pulse, no error |
| RX-005 | P0 | Drive stop bit LOW | One framing-error pulse, data held |
| RX-006 | P0 | Send a valid frame after an error | Receiver recovers and accepts it |
| RX-007 | P1 | Send two contiguous frames | Both bytes are reported in order |
| RX-008 | P1 | Drive a short LOW pulse | False start is rejected silently |
| RX-009 | P1 | Toggle data late in a bit period | Center sample retains intended bit |
| RX-010 | P1 | Assert reset during a frame | Frame aborts and receiver returns idle |
| RX-011 | P1 | Observe pulse widths | `rx_done_valid` and error are one clock wide |

## Pass Criteria

The test passes when every directed check reports PASS, `fail_count` remains
zero, and both supported simulators compile and execute the same testbench
without RTL warnings.

## Future Coverage

- Sweep legal clock and baud parameter pairs.
- Inject positive and negative baud mismatch near the supported limit.
- Add randomized phase offsets between RX transitions and `clk`.
- Add break-condition and overrun tests when those features exist.
- Add loopback verification with the repository's `uart_tx` module.
