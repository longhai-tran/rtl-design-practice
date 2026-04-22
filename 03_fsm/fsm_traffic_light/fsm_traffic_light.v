/*******************************************************************************
 * Module      : fsm_traffic_light
 * Description : Parameterizable two-road traffic light controller (Moore FSM).
 *               Cycles through four phases:
 *                 NS_G → NS_Y → EW_G → EW_Y → (repeat)
 *               Safety invariant: NS and EW roads are NEVER simultaneously GREEN.
 *
 * Parameters  :
 *   GREEN_CYCLES  – number of clock cycles each GREEN  phase lasts (default: 4)
 *   YELLOW_CYCLES – number of clock cycles each YELLOW phase lasts (default: 2)
 *
 * Light encoding (2-bit output per road):
 *   2'b00 = RED  |  2'b01 = YELLOW  |  2'b10 = GREEN
 *
 * Reset       : Active-low synchronous (rst_n).
 *               On reset → state = NS_G, count = 0.
 *
 * File Created: Thursday, 16th April 2026 11:54:11 am
 * Author      : Long Hai
 * Last Modified: Friday, 17th April 2026
 *******************************************************************************/

`timescale 1ns/1ps

module fsm_traffic_light #(
    parameter integer GREEN_CYCLES  = 4,
    parameter integer YELLOW_CYCLES = 2
)(
    input  wire       clk,
    input  wire       rst_n,
    output reg  [1:0] ns_light,
    output reg  [1:0] ew_light
);

    // -------------------------------------------------------------------------
    // Local parameters
    // -------------------------------------------------------------------------

    // Light colour encoding
    localparam [1:0]
        RED    = 2'b00,
        YELLOW = 2'b01,
        GREEN  = 2'b10;

    // FSM state encoding (one-cold / binary; 4 states → 2 bits)
    localparam [1:0]
        NS_G = 2'd0,  // NS = GREEN,  EW = RED
        NS_Y = 2'd1,  // NS = YELLOW, EW = RED
        EW_G = 2'd2,  // NS = RED,    EW = GREEN
        EW_Y = 2'd3;  // NS = RED,    EW = YELLOW

    // Counter bit width: deep enough for the larger of the two durations.
    // $clog2(N) gives the minimum bits needed to hold value N-1.
    localparam CNT_W = $clog2(GREEN_CYCLES > YELLOW_CYCLES
                              ? GREEN_CYCLES : YELLOW_CYCLES);

    // -------------------------------------------------------------------------
    // State & counter registers
    // -------------------------------------------------------------------------
    reg [1:0]         state, next_state;
    reg [CNT_W-1:0]   count;

    // -------------------------------------------------------------------------
    // Sequential block – state and counter update
    // -------------------------------------------------------------------------
    //  Counter semantics:
    //    count tracks how many cycles the FSM has spent in the CURRENT state.
    //    It resets to 0 on the cycle the FSM LEAVES that state (i.e. the first
    //    cycle in the new state count=0), giving correct "spent N cycles" timing.
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            state <= NS_G;
            count <= {CNT_W{1'b0}};
        end else begin
            state <= next_state;
            if (state != next_state)
                count <= {CNT_W{1'b0}};
            else
                count <= count + 1'b1;
        end
    end

    // -------------------------------------------------------------------------
    // Combinational block – next-state & Moore output logic
    // -------------------------------------------------------------------------
    always @(*) begin
        // Safe defaults: stay in current state, both lights RED
        next_state = state;
        ns_light   = RED;
        ew_light   = RED;

        case (state)
            NS_G: begin
                ns_light = GREEN;
                ew_light = RED;
                if (count == GREEN_CYCLES[CNT_W-1:0] - 1'b1)
                    next_state = NS_Y;
            end

            NS_Y: begin
                ns_light = YELLOW;
                ew_light = RED;
                if (count == YELLOW_CYCLES[CNT_W-1:0] - 1'b1)
                    next_state = EW_G;
            end

            EW_G: begin
                ns_light = RED;
                ew_light = GREEN;
                if (count == GREEN_CYCLES[CNT_W-1:0] - 1'b1)
                    next_state = EW_Y;
            end

            EW_Y: begin
                ns_light = RED;
                ew_light = YELLOW;
                if (count == YELLOW_CYCLES[CNT_W-1:0] - 1'b1)
                    next_state = NS_G;
            end

            default: begin
                // Illegal state recovery: force safe outputs and return to NS_G
                ns_light   = RED;
                ew_light   = RED;
                next_state = NS_G;
            end
        endcase
    end

endmodule
