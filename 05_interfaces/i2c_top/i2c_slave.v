/*******************************************************************************
 * Module: i2c_slave.v                                                         *
 * Description: System-clocked I2C target for one-byte read/write transfers.   *
 * File Created: Friday, 31st July 2026 10:28:04 am                            *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Tuesday, 4th August 2026 11:36:37 am                         *
 * Modified By: Long Hai                                                       *
 *******************************************************************************/

/*
 * I2C Slave (Target) Controller — Design Notes
 * =============================================
 * This module implements an I2C target that operates by edge-detecting SCL and
 * SDA transitions in the system-clock domain.  It does NOT generate SCL; it
 * only reacts to the master-generated clock.
 *
 * Edge detection:
 *   - scl_d / sda_d: one-cycle delayed copies of the bus signals.
 *   - scl_rising  = (!scl_d && scl)  — sample address/data bits here.
 *   - scl_falling = ( scl_d && !scl) — drive SDA (ACK, read data) here
 *                                       so the signal is stable by the next
 *                                       SCL rising edge (I2C setup time).
 *   - start_event = SDA falling while SCL HIGH  → begin new transfer.
 *   - stop_event  = SDA rising  while SCL HIGH  → end of transfer.
 *
 * Open-drain model:
 *   - sda_drive_low: when HIGH, the slave pulls SDA LOW.
 *   - When LOW, the slave releases SDA; the top-level pull-up holds it HIGH.
 *
 * Supported states:
 *   IDLE → ADDRESS(8 bits) → ADDR_ACK → WRITE/READ(8 bits) →
 *   WRITE_ACK / READ_NACK → WAIT_STOP → IDLE
 *
 * Note: start_event and stop_event are checked unconditionally and take
 * priority over the current state to handle repeated-START and error recovery.
 */

`timescale 1ns/1ps

module i2c_slave #(
    // SLAVE_ADDR: the 7-bit I2C address this device responds to.
    parameter [6:0] SLAVE_ADDR = 7'h42
) (
    input  wire       clk,          // System clock (active on rising edge)
    input  wire       rst_n,        // Synchronous active-low reset
    input  wire       scl,          // I2C clock line (master-driven)
    input  wire       sda,          // Resolved SDA bus (wired-AND from top)
    input  wire [7:0] tx_data,      // Byte to return to master (read transactions)

    output reg        sda_drive_low, // Assert HIGH to pull SDA LOW (open-drain)
    output reg  [7:0] rx_data,       // Byte captured from master (write transactions)
    output reg        rx_valid,      // One-cycle pulse when rx_data is valid
    output reg        busy,          // HIGH while a transaction is in progress
    output reg        done           // One-cycle pulse when transfer completes
);

    // -------------------------------------------------------------------------
    // FSM state encoding
    // -------------------------------------------------------------------------
    localparam [3:0] ST_IDLE       = 4'd0;  // Waiting for a START condition
    localparam [3:0] ST_ADDRESS    = 4'd1;  // Receiving 8-bit address frame
    localparam [3:0] ST_ADDR_ACK   = 4'd2;  // Driving ACK/NACK after address
    localparam [3:0] ST_WRITE      = 4'd3;  // Receiving 8-bit data byte from master
    localparam [3:0] ST_WRITE_ACK  = 4'd4;  // Driving ACK after data byte
    localparam [3:0] ST_READ       = 4'd5;  // Driving 8-bit data byte to master
    localparam [3:0] ST_READ_NACK  = 4'd6;  // Waiting for master NACK after read byte
    localparam [3:0] ST_WAIT_STOP  = 4'd7;  // Waiting for STOP before returning to IDLE

    // -------------------------------------------------------------------------
    // Internal registers
    // -------------------------------------------------------------------------
    reg [3:0] state;          // Current FSM state
    reg       scl_d;          // Previous-cycle SCL value (for edge detection)
    reg       sda_d;          // Previous-cycle SDA value (for START/STOP detection)
    // bit[0] of address_shift and rx_shift is written but intentionally never read:
    // last received bit is merged directly via {reg[7:1], sda}
    // verilator lint_off UNUSEDSIGNAL
    reg [7:0] address_shift;  // Shift register collecting the incoming address frame
    reg [7:0] rx_shift;       // Shift register collecting the incoming data byte
    // verilator lint_on UNUSEDSIGNAL
    reg [7:0] tx_latched;     // TX byte latched at START to avoid mid-transfer change
    reg [2:0] bit_index;      // Counts down 7→0; selects the current bit
    reg       ack_phase;      // Toggle flag used in two-phase ACK generation
    reg       selected;       // TRUE when our address matched the received address
    reg       rw_latched;     // Latched R/W bit from address frame (0=write, 1=read)

    // -------------------------------------------------------------------------
    // Combinational edge / event detection
    // -------------------------------------------------------------------------
    wire scl_rising  = !scl_d && scl;   // SCL: LOW→HIGH (sample point for received bits)
    wire scl_falling = scl_d && !scl;   // SCL: HIGH→LOW (drive point for SDA changes)
    wire start_event = sda_d && !sda && scl; // SDA LOW while SCL HIGH → START / repeated-START
    wire stop_event  = !sda_d && sda && scl; // SDA HIGH while SCL HIGH → STOP condition

    // Combine the partial shift register with the live sda bit for address comparison.
    // This avoids sampling the stale rx_shift[0] that is written simultaneously.
    wire [7:0] address_with_last_bit = {address_shift[7:1], sda};

    // -------------------------------------------------------------------------
    // Main FSM — synchronous reset, event-driven transitions
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            // Release all drive outputs; bus lines float HIGH via pull-ups
            state          <= ST_IDLE;
            scl_d          <= 1'b1;
            sda_d          <= 1'b1;
            address_shift  <= 8'h00;
            rx_shift       <= 8'h00;
            tx_latched     <= 8'h00;
            bit_index      <= 3'd7;
            ack_phase      <= 1'b0;
            selected       <= 1'b0;
            rw_latched     <= 1'b0;
            sda_drive_low  <= 1'b0;
            rx_data        <= 8'h00;
            rx_valid       <= 1'b0;
            busy           <= 1'b0;
            done           <= 1'b0;
        end else begin
            // Delay registers for edge detection (update every cycle)
            scl_d    <= scl;
            sda_d    <= sda;
            // Pulse outputs: de-assert by default each cycle
            rx_valid <= 1'b0;
            done     <= 1'b0;

            if (start_event) begin
                // ── START / Repeated-START detected ─────────────────────────
                // Reset all per-transfer state and begin address reception.
                // tx_data is latched here so a new TX byte cannot disturb
                // an in-progress read transfer.
                state          <= ST_ADDRESS;
                address_shift  <= 8'h00;
                rx_shift       <= 8'h00;
                tx_latched     <= tx_data;
                bit_index      <= 3'd7;
                ack_phase      <= 1'b0;
                selected       <= 1'b0;
                rw_latched     <= 1'b0;
                sda_drive_low  <= 1'b0;
                busy           <= 1'b1;

            end else if (stop_event) begin
                // ── STOP detected ───────────────────────────────────────────
                // End of transfer regardless of current state.
                // Pulse done only if this slave was selected in this transfer.
                if (selected)
                    done <= 1'b1;
                state         <= ST_IDLE;
                selected      <= 1'b0;
                sda_drive_low <= 1'b0;
                busy          <= 1'b0;

            end else begin
                case (state)
                    // ── ST_ADDRESS ──────────────────────────────────────────
                    // Sample one bit per SCL rising edge into address_shift.
                    // After all 8 bits (7-bit addr + R/W), decode the frame and
                    // check if it targets this slave.
                    ST_ADDRESS: begin
                        if (scl_rising) begin
                            address_shift[bit_index] <= sda;
                            if (bit_index == 0) begin
                                // All 8 bits received; decode address frame
                                selected   <= (address_with_last_bit[7:1] == SLAVE_ADDR);
                                rw_latched <= address_with_last_bit[0]; // bit[0] = R/W
                                ack_phase  <= 1'b0;
                                state      <= ST_ADDR_ACK;
                            end else begin
                                bit_index <= bit_index - 1'b1;
                            end
                        end
                    end

                    // ── ST_ADDR_ACK ─────────────────────────────────────────
                    // Two-phase ACK generation using scl_falling and ack_phase toggle:
                    //   Phase 0 (first SCL falling): drive SDA LOW if selected (ACK),
                    //                                or leave HIGH if not (NACK).
                    //   Phase 1 (second SCL falling): release SDA and transition to
                    //                                 READ or WRITE state.
                    // Driving SDA on falling SCL ensures it is stable long before
                    // the master samples it on the next SCL rising edge.
                    ST_ADDR_ACK: begin
                        if (scl_falling) begin
                            if (!ack_phase) begin
                                // Drive ACK (SDA LOW) only if address matched
                                sda_drive_low <= selected;
                                ack_phase     <= 1'b1;
                            end else begin
                                // Release SDA and move to the data phase
                                sda_drive_low <= 1'b0;
                                ack_phase     <= 1'b0;
                                bit_index     <= 3'd7;
                                if (!selected) begin
                                    // Address did not match — wait quietly for STOP
                                    busy  <= 1'b0;
                                    state <= ST_WAIT_STOP;
                                end else if (rw_latched) begin
                                    // Master reads → slave drives the first data bit now
                                    sda_drive_low <= ~tx_latched[7];
                                    state         <= ST_READ;
                                end else begin
                                    // Master writes → prepare to receive data
                                    rx_shift <= 8'h00;
                                    state    <= ST_WRITE;
                                end
                            end
                        end
                    end

                    // ── ST_WRITE ────────────────────────────────────────────
                    // Sample one bit per SCL rising edge into rx_shift, MSB first.
                    // After 8 bits, assemble rx_data and proceed to WRITE_ACK.
                    ST_WRITE: begin
                        if (scl_rising) begin
                            rx_shift[bit_index] <= sda;
                            if (bit_index == 0) begin
                                // Merge live sda into bit[0] to avoid the stale latch
                                rx_data   <= {rx_shift[7:1], sda};
                                ack_phase <= 1'b0;
                                state     <= ST_WRITE_ACK;
                            end else begin
                                bit_index <= bit_index - 1'b1;
                            end
                        end
                    end

                    // ── ST_WRITE_ACK ────────────────────────────────────────
                    // Two-phase ACK: drive SDA LOW on first falling SCL, then release
                    // and assert rx_valid on the second falling SCL.
                    // rx_valid is a single-cycle pulse cleared at the top of the block.
                    ST_WRITE_ACK: begin
                        if (scl_falling) begin
                            if (!ack_phase) begin
                                sda_drive_low <= 1'b1; // ACK: pull SDA LOW
                                ack_phase     <= 1'b1;
                            end else begin
                                sda_drive_low <= 1'b0; // Release SDA
                                rx_valid      <= 1'b1; // Notify system of valid received byte
                                ack_phase     <= 1'b0;
                                state         <= ST_WAIT_STOP;
                            end
                        end
                    end

                    // ── ST_READ ─────────────────────────────────────────────
                    // Drive one bit per SCL falling edge (so it is stable by
                    // the next SCL rising edge when the master samples it).
                    // Bits are sent MSB-first from tx_latched.
                    // After bit[0], release SDA so master can drive NACK/ACK.
                    ST_READ: begin
                        if (scl_falling) begin
                            if (bit_index == 0) begin
                                // All 8 bits sent; release SDA for master ACK/NACK
                                sda_drive_low <= 1'b0;
                                state         <= ST_READ_NACK;
                            end else begin
                                // Advance to next bit and update SDA
                                bit_index     <= bit_index - 1'b1;
                                sda_drive_low <= ~tx_latched[bit_index - 1'b1];
                            end
                        end
                    end

                    // ── ST_READ_NACK ────────────────────────────────────────
                    // Wait for the master to clock the NACK bit (SCL rising edge).
                    // After that, wait for the master-generated STOP condition.
                    ST_READ_NACK: begin
                        if (scl_rising)
                            state <= ST_WAIT_STOP; // NACK sampled; await STOP
                    end

                    // ── ST_WAIT_STOP ─────────────────────────────────────────
                    // Passively release SDA and wait for the STOP event detected
                    // by the priority branch above.  No action needed here.
                    ST_WAIT_STOP: begin
                        sda_drive_low <= 1'b0;
                    end

                    // ── Default (unreachable in normal operation) ─────────────
                    // Safety net: release SDA and return to IDLE
                    default: begin
                        state         <= ST_IDLE;
                        sda_drive_low <= 1'b0;
                        busy          <= 1'b0;
                    end
                endcase
            end
        end
    end

endmodule
