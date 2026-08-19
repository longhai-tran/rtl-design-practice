/*******************************************************************************
 * Module: i2c_master.v                                                        *
 * Description: One-byte, 7-bit-address I2C controller with ACK/NACK handling. *
 * File Created: Friday, 31st July 2026 10:28:03 am                            *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Tuesday, 4th August 2026 11:36:31 am                         *
 * Modified By: Long Hai                                                       *
 *******************************************************************************/

/*
 * I2C Master Controller — Design Notes
 * ======================================
 * Protocol overview (single-byte transfer):
 *
 *  SDA ──┐  ┌──── A6 A5 A4 A3 A2 A1 A0 R/W ── ACK ── D7..D0 ── ACK ──┐  ┌──
 *        └──┘ START                                                  └──┘ STOP
 *  SCL  ─────────┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ...........  ┌────────
 *                └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘
 *
 * Open-drain model:
 *   - Master drives SCL and SDA LOW by asserting scl_drive_low / sda_drive_low.
 *   - When drive signals are de-asserted, external pull-ups return lines HIGH.
 *   - The instantiating top-level resolves the wired-AND bus.
 *
 * Clock generation:
 *   - System clock is divided by (2 × HALF_PERIOD) to produce SCL.
 *   - half_tick pulses once per SCL half-period; each state step takes exactly
 *     one or two half-ticks depending on whether SCL needs to change.
 *
 * Supported states:
 *   IDLE → START → ADDRESS(8 bits) → ADDR_ACK → WRITE/READ(8 bits) →
 *   WRITE_ACK / READ_NACK → STOP_LOW → STOP_HIGH → STOP_FREE → IDLE
 */

`timescale 1ns/1ps

module i2c_master #(
    // CLK_DIV: number of system-clock cycles per SCL half-period.
    // SCL frequency = f_clk / (2 * CLK_DIV).  Minimum effective value is 2.
    parameter integer CLK_DIV = 4
) (
    input  wire       clk,          // System clock (active on rising edge)
    input  wire       rst_n,        // Synchronous active-low reset
    input  wire       start,        // Pulse HIGH for one cycle to begin a transfer
    input  wire       rw,           // Transfer direction: 0 = write, 1 = read
    input  wire [6:0] target_addr,  // 7-bit I2C device address to access
    input  wire [7:0] tx_data,      // Byte to transmit (write transactions only)
    input  wire       sda,          // Resolved SDA bus value (from top-level)

    output reg        scl_drive_low, // Assert HIGH to pull SCL LOW (open-drain)
    output reg        sda_drive_low, // Assert HIGH to pull SDA LOW (open-drain)
    output reg  [7:0] rx_data,       // Byte captured from the bus (read transactions)
    output reg        busy,          // HIGH while a transaction is in progress
    output reg        done,          // One-cycle pulse when transfer completes
    output reg        ack_error      // Latched HIGH if slave did not acknowledge
);

    // -------------------------------------------------------------------------
    // Clock divider constants
    // -------------------------------------------------------------------------
    // Enforce minimum HALF_PERIOD of 2 to guarantee at least one div_count tick
    // between state transitions.
    localparam integer HALF_PERIOD = (CLK_DIV < 2) ? 2 : CLK_DIV;
    // Bit-width needed to count up to HALF_PERIOD-1
    localparam integer DIV_BITS = (HALF_PERIOD < 2) ? 1 : $clog2(HALF_PERIOD);
    // Truncation is safe: HALF_PERIOD-1 always fits in DIV_BITS bits by clog2 construction
    // verilator lint_off WIDTHTRUNC
    localparam [DIV_BITS-1:0] DIV_MAX = HALF_PERIOD - 1;
    // verilator lint_on WIDTHTRUNC

    // -------------------------------------------------------------------------
    // FSM state encoding
    // -------------------------------------------------------------------------
    // State names map directly to the I2C protocol phase they implement.
    localparam [3:0] ST_IDLE       = 4'd0;  // Bus free; waiting for start request
    localparam [3:0] ST_START      = 4'd1;  // SDA pulled LOW while SCL HIGH (START)
    localparam [3:0] ST_ADDRESS    = 4'd2;  // Clocking out 8-bit address frame (addr[6:0] + R/W)
    localparam [3:0] ST_ADDR_ACK   = 4'd3;  // Releasing SDA; sampling slave ACK bit
    localparam [3:0] ST_WRITE      = 4'd4;  // Clocking out 8-bit data byte (write)
    localparam [3:0] ST_WRITE_ACK  = 4'd5;  // Releasing SDA; sampling slave ACK bit for data
    localparam [3:0] ST_READ       = 4'd6;  // Sampling 8 bits driven by the slave (read)
    localparam [3:0] ST_READ_NACK  = 4'd7;  // Master drives NACK (SDA HIGH) to stop read
    localparam [3:0] ST_STOP_LOW   = 4'd8;  // SCL released HIGH, SDA still LOW
    localparam [3:0] ST_STOP_HIGH  = 4'd9;  // SDA released HIGH while SCL HIGH (STOP)
    localparam [3:0] ST_STOP_FREE  = 4'd10; // Bus quiescent; assert done and return to IDLE

    // -------------------------------------------------------------------------
    // Internal registers
    // -------------------------------------------------------------------------
    reg [3:0]          state;         // Current FSM state
    reg [DIV_BITS-1:0] div_count;     // Counts up to HALF_PERIOD-1, then resets
    reg                high_phase;    // Toggle flag: 0 = SCL low half, 1 = SCL high half
    reg                rw_latched;    // Latched R/W bit captured at START edge
    reg [7:0]          address_frame; // {target_addr, rw} — 8-bit address+direction frame
    reg [7:0]          tx_latched;    // Latched TX byte captured at START edge
    // rx_shift[0] is written but intentionally never read: last bit merged via {rx_shift[7:1], sda}
    // verilator lint_off UNUSEDSIGNAL
    reg [7:0]          rx_shift;      // Shift register accumulating received bits
    // verilator lint_on UNUSEDSIGNAL
    reg [2:0]          bit_index;     // Counts down from 7 to 0; selects current bit

    // half_tick: TRUE for exactly one clock cycle every SCL half-period.
    // All state transitions occur only on this tick to maintain precise I2C timing.
    wire half_tick = (div_count == DIV_MAX);

    // -------------------------------------------------------------------------
    // Main FSM — synchronous reset, half-tick gated transitions
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            // De-assert all drive signals so bus lines are pulled HIGH by pull-ups
            state         <= ST_IDLE;
            div_count     <= 0;
            high_phase    <= 1'b0;
            rw_latched    <= 1'b0;
            address_frame <= 8'h00;
            tx_latched    <= 8'h00;
            rx_shift      <= 8'h00;
            bit_index     <= 3'd7;
            scl_drive_low <= 1'b0;
            sda_drive_low <= 1'b0;
            rx_data       <= 8'h00;
            busy          <= 1'b0;
            done          <= 1'b0;
            ack_error     <= 1'b0;
        end else begin
            // done is a single-cycle pulse; de-assert by default every cycle
            done <= 1'b0;

            if (state == ST_IDLE) begin
                // ── IDLE ────────────────────────────────────────────────────
                // Keep both bus lines released and wait for a start request.
                scl_drive_low <= 1'b0;
                sda_drive_low <= 1'b0;
                busy          <= 1'b0;
                div_count     <= 0;
                high_phase    <= 1'b0;

                if (start) begin
                    // Latch all inputs so they cannot change mid-transfer
                    address_frame <= {target_addr, rw}; // Build 8-bit address frame
                    tx_latched    <= tx_data;
                    rw_latched    <= rw;
                    rx_shift      <= 8'h00;
                    bit_index     <= 3'd7;
                    ack_error     <= 1'b0;
                    busy          <= 1'b1;
                    // Pull SDA LOW while SCL is HIGH — this IS the START condition.
                    // SCL will be pulled LOW on the next half_tick (ST_START handler).
                    sda_drive_low <= 1'b1;
                    state         <= ST_START;
                end
            end else if (half_tick) begin
                // All non-idle state transitions happen here to maintain I2C timing
                div_count <= 0; // Reset counter for next half-period

                case (state)
                    // ── ST_START ────────────────────────────────────────────
                    // SDA is already LOW (set in IDLE→START transition).
                    // Now pull SCL LOW to begin the first address bit.
                    ST_START: begin
                        scl_drive_low <= 1'b1;                  // SCL LOW
                        sda_drive_low <= ~address_frame[7];     // Pre-drive MSB of address
                        high_phase    <= 1'b0;
                        state         <= ST_ADDRESS;
                    end

                    // ── ST_ADDRESS ──────────────────────────────────────────
                    // Clock out the 8-bit address frame (bits [7:0], MSB first).
                    // Uses high_phase toggle: low half → release SCL, high half → pull SCL LOW.
                    // SDA is updated on the falling edge (low-half entry) so it is stable
                    // during the subsequent SCL high phase (I2C setup/hold requirement).
                    ST_ADDRESS: begin
                        if (!high_phase) begin
                            // Rising edge of SCL: release line and let pull-up raise it
                            scl_drive_low <= 1'b0;
                            high_phase    <= 1'b1;
                        end else begin
                            // Falling edge of SCL: pull it low again
                            scl_drive_low <= 1'b1;
                            high_phase    <= 1'b0;
                            if (bit_index == 0) begin
                                // Last bit just clocked; release SDA for ACK phase
                                sda_drive_low <= 1'b0;
                                state         <= ST_ADDR_ACK;
                            end else begin
                                // Advance to next bit and pre-drive SDA
                                bit_index     <= bit_index - 1'b1;
                                sda_drive_low <= ~address_frame[bit_index - 1'b1];
                            end
                        end
                    end

                    // ── ST_ADDR_ACK ─────────────────────────────────────────
                    // Release SDA and generate one SCL cycle; sample sda on the
                    // falling edge (high_phase == 1) to read the slave ACK/NACK.
                    // ACK  = slave pulls SDA LOW  → sda == 0
                    // NACK = SDA remains HIGH    → sda == 1  (ack_error)
                    ST_ADDR_ACK: begin
                        if (!high_phase) begin
                            scl_drive_low <= 1'b0; // Release SCL HIGH for sampling
                            high_phase    <= 1'b1;
                        end else begin
                            scl_drive_low <= 1'b1; // Pull SCL LOW after sample
                            high_phase    <= 1'b0;
                            if (sda) begin
                                // NACK received — abort and issue STOP
                                ack_error     <= 1'b1;
                                sda_drive_low <= 1'b1; // Pre-drive SDA LOW for STOP sequence
                                state         <= ST_STOP_LOW;
                            end else if (rw_latched) begin
                                // ACK received, read transfer → release SDA for slave to drive
                                bit_index     <= 3'd7;
                                sda_drive_low <= 1'b0;
                                state         <= ST_READ;
                            end else begin
                                // ACK received, write transfer → pre-drive MSB of data byte
                                bit_index     <= 3'd7;
                                sda_drive_low <= ~tx_latched[7];
                                state         <= ST_WRITE;
                            end
                        end
                    end

                    // ── ST_WRITE ────────────────────────────────────────────
                    // Clock out the 8-bit TX byte MSB-first, same half_phase
                    // toggle rhythm as ST_ADDRESS.
                    ST_WRITE: begin
                        if (!high_phase) begin
                            scl_drive_low <= 1'b0;
                            high_phase    <= 1'b1;
                        end else begin
                            scl_drive_low <= 1'b1;
                            high_phase    <= 1'b0;
                            if (bit_index == 0) begin
                                // Last data bit sent; release SDA for slave ACK
                                sda_drive_low <= 1'b0;
                                state         <= ST_WRITE_ACK;
                            end else begin
                                bit_index     <= bit_index - 1'b1;
                                sda_drive_low <= ~tx_latched[bit_index - 1'b1];
                            end
                        end
                    end

                    // ── ST_WRITE_ACK ────────────────────────────────────────
                    // Sample slave's data-byte ACK and then proceed to STOP.
                    // ack_error is set but the STOP sequence is still issued to
                    // leave the bus in a defined idle state even on failure.
                    ST_WRITE_ACK: begin
                        if (!high_phase) begin
                            scl_drive_low <= 1'b0;
                            high_phase    <= 1'b1;
                        end else begin
                            scl_drive_low <= 1'b1;
                            high_phase    <= 1'b0;
                            if (sda)
                                ack_error <= 1'b1; // NACK on data byte
                            // SDA LOW needed to generate valid STOP (SDA: LOW→HIGH while SCL HIGH)
                            sda_drive_low <= 1'b1;
                            state         <= ST_STOP_LOW;
                        end
                    end

                    // ── ST_READ ─────────────────────────────────────────────
                    // Master releases SDA; slave drives each bit.
                    // Bits are sampled on the falling edge of SCL (high_phase == 1)
                    // and accumulated in rx_shift, MSB first.
                    // Last bit is merged directly to avoid a stale rx_shift[0].
                    ST_READ: begin
                        if (!high_phase) begin
                            scl_drive_low <= 1'b0; // Release SCL for slave to be sampled
                            high_phase    <= 1'b1;
                        end else begin
                            scl_drive_low       <= 1'b1;
                            high_phase          <= 1'b0;
                            rx_shift[bit_index] <= sda; // Capture current SDA bit
                            if (bit_index == 0) begin
                                // Assemble final byte; use live sda for bit[0] to avoid
                                // a one-cycle delay from the rx_shift assignment above.
                                rx_data       <= {rx_shift[7:1], sda};
                                bit_index     <= 3'd7;
                                // Keep SDA released (HIGH) to send NACK to slave,
                                // signalling that the master will not read another byte.
                                sda_drive_low <= 1'b0;
                                state         <= ST_READ_NACK;
                            end else begin
                                bit_index <= bit_index - 1'b1;
                            end
                        end
                    end

                    // ── ST_READ_NACK ────────────────────────────────────────
                    // Generate one SCL cycle with SDA HIGH (NACK) to tell the
                    // slave that this is the final byte of the read.
                    ST_READ_NACK: begin
                        if (!high_phase) begin
                            scl_drive_low <= 1'b0;
                            high_phase    <= 1'b1;
                        end else begin
                            scl_drive_low <= 1'b1;
                            high_phase    <= 1'b0;
                            // SDA LOW here so STOP can be generated (LOW→HIGH with SCL HIGH)
                            sda_drive_low <= 1'b1;
                            state         <= ST_STOP_LOW;
                        end
                    end

                    // ── STOP sequence (3 steps) ─────────────────────────────
                    // I2C STOP = SDA goes LOW→HIGH while SCL is HIGH.
                    // Step 1: raise SCL first (SDA still LOW).
                    // Step 2: raise SDA while SCL is HIGH → this is the STOP event.
                    // Step 3: hold both HIGH for one half-period (bus free), then signal done.
                    ST_STOP_LOW: begin
                        scl_drive_low <= 1'b0; // raise SCL
                        sda_drive_low <= 1'b1; // keep SDA LOW
                        state         <= ST_STOP_HIGH;
                    end

                    ST_STOP_HIGH: begin
                        scl_drive_low <= 1'b0; // SCL stays HIGH
                        sda_drive_low <= 1'b0; // raise SDA → STOP event
                        state         <= ST_STOP_FREE;
                    end

                    ST_STOP_FREE: begin
                        busy  <= 1'b0;
                        done  <= 1'b1; // one-cycle pulse to notify caller
                        state <= ST_IDLE;
                    end

                    // ── Default (unreachable in normal operation) ────────────
                    // Safety net: force bus lines to safe idle state
                    default: begin
                        state         <= ST_IDLE;
                        scl_drive_low <= 1'b0;
                        sda_drive_low <= 1'b0;
                        busy          <= 1'b0;
                    end
                endcase
            end else begin
                // Normal clock cycle — just advance the divider counter
                div_count <= div_count + 1'b1;
            end
        end
    end

endmodule
