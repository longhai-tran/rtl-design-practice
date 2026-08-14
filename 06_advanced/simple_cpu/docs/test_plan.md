# Simple CPU Test Plan

| ID | Scenario | Expected result |
|---|---|---|
| TC1 | Synchronous reset | idle state, `pc=0`, `busy=0`, registers cleared |
| TC2 | LOADI and ADD | register result is 8 |
| TC3 | STORE then LOAD | memory and destination register both contain 8 |
| TC4 | BEQZ | zero register branches to HALT and skips instruction |
| TC5 | HALT and restart | one-cycle `done`, clean deterministic restart |
