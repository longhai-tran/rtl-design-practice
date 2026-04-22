/*******************************************************************************
 * Module: fsm_vending_machine.v                                               *
 * Description : Mealy FSM for a vending machine that accepts 5-unit and       *
 *               10-unit coins and dispenses an item costing 15 units.         *
 *               Change (5 units) is returned when the inserted total exceeds  *
 *               15 units.                                                     *
 * File Created: Thursday, 16th April 2026 11:54:11 am                         *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Monday, 20th April 2026 2:58:25 pm                           *
 * Modified By: Long Hai                                                       *
*******************************************************************************/

/*******************************************************************************
 *
 * State Diagram (accumulated units): in README.md
 *
 * State Encoding:
 *   S0  = 2'b00  : Idle, 0 units accumulated
 *   S5  = 2'b01  : 5 units accumulated
 *   S10 = 2'b10  : 10 units accumulated
 *
 * Output Logic (registered, updates on next clock edge):
 *   vend     : 1 when item is dispensed (accumulated >= 15u)
 *   change_5 : 1 when 5-unit change is returned (inserted > 15u)
 *
 * Coin Priority:
 *   If both coin_5 and coin_10 are asserted simultaneously, coin_10 takes
 *   priority. This is an invalid input condition; the caller must ensure
 *   mutual exclusion.
 *
 * Reset:
 *   Active-low synchronous reset (rst_n). Clears state and all outputs.
 *
 ******************************************************************************/

`timescale 1ns/1ps

module fsm_vending_machine (
    input  wire clk,       // System clock (rising-edge triggered)
    input  wire rst_n,     // Active-low synchronous reset
    input  wire coin_5,    // Insert 5-unit coin (mutually exclusive with coin_10)
    input  wire coin_10,   // Insert 10-unit coin (mutually exclusive with coin_5)
    output reg  vend,      // High for 1 cycle when item is dispensed
    output reg  change_5   // High for 1 cycle when 5-unit change is returned
);

    // -------------------------------------------------------------------------
    // State encoding
    // -------------------------------------------------------------------------
    localparam [1:0]
        S0  = 2'd0,   // Idle         : 0 units accumulated
        S5  = 2'd1,   // Intermediate : 5 units accumulated
        S10 = 2'd2;   // Intermediate : 10 units accumulated

    // -------------------------------------------------------------------------
    // State and output next-state registers
    // -------------------------------------------------------------------------
    reg [1:0] state, next_state;
    reg       vend_next, change_5_next;

    // -------------------------------------------------------------------------
    // Sequential block: state and output registers
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            state    <= S0;
            vend     <= 1'b0;
            change_5 <= 1'b0;
        end else begin
            state    <= next_state;
            vend     <= vend_next;
            change_5 <= change_5_next;
        end
    end

    // -------------------------------------------------------------------------
    // Combinational block: next-state and output logic
    // -------------------------------------------------------------------------
    always @(*) begin
        // Default: hold state, deassert outputs
        next_state    = state;
        vend_next     = 1'b0;
        change_5_next = 1'b0;

        case (state)
            // -----------------------------------------------------------------
            // S0: Idle – waiting for first coin
            // -----------------------------------------------------------------
            S0: begin
                if (coin_10)
                    next_state = S10;       // +10u -> 10u total
                else if (coin_5)
                    next_state = S5;        // +5u  -> 5u total
            end

            // -----------------------------------------------------------------
            // S5: 5 units accumulated
            // -----------------------------------------------------------------
            S5: begin
                if (coin_10) begin
                    vend_next  = 1'b1;      // 5+10=15u -> dispense, no change
                    next_state = S0;
                end else if (coin_5)
                    next_state = S10;       // 5+5=10u  -> accumulate
            end

            // -----------------------------------------------------------------
            // S10: 10 units accumulated
            // -----------------------------------------------------------------
            S10: begin
                if (coin_10) begin
                    vend_next     = 1'b1;   // 10+10=20u -> dispense + change
                    change_5_next = 1'b1;
                    next_state    = S0;
                end else if (coin_5) begin
                    vend_next  = 1'b1;      // 10+5=15u  -> dispense, no change
                    next_state = S0;
                end
            end

            // -----------------------------------------------------------------
            // Default: recover from illegal state
            // -----------------------------------------------------------------
            default: next_state = S0;
        endcase
    end

endmodule
