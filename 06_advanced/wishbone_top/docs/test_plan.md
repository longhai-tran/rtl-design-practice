# Wishbone Top Test Plan

## Verification goals

Confirm that the integrated master, interconnect, and both slaves obey the single-transfer Wishbone B4 contract and preserve register state under legal and illegal accesses.

| ID | Scenario | Checks |
|---|---|---|
| TC1 | Reset | Master idle, bus released, both register banks zero |
| TC2 | Slave 0 R/W | Full word stored and returned with `ACK` |
| TC3 | Slave 1 decode | `0x1xxx` reaches only slave 1 |
| TC4 | Byte enables | Only lanes selected by `SEL` are modified |
| TC5 | ID registers | Correct per-instance ID; write returns `ERR` |
| TC6 | Invalid address | Unmapped region returns `ERR` |
| TC7 | Alignment | Non-word-aligned access returns `ERR` |
| TC8 | Busy policy | Second command cannot corrupt outstanding transfer |
| TC9 | Completion pulse | `done` is exactly one clock wide |

## Pass criteria

- No self-check reports `FAIL`.
- Every accepted request terminates with `ACK` or `ERR` before timeout.
- `ACK` and `ERR` are never asserted together.
- Writes affect only the selected slave, register, and byte lanes.
