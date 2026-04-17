/*******************************************************************************
 * Module: fsm_sequence_detector.v                                             *
 * Description: Mealy FSM detects sequence 1011 with overlap enabled.          *
 * File Created: Thursday, 16th April 2026                                     *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Thursday, 16th April 2026                                    *
 * Modified By: Long Hai                                                       *
*******************************************************************************/

`timescale 1ns/1ps

module fsm_sequence_detector (
    input  wire clk,
    input  wire rst_n,
    input  wire din,
    output reg  detected
);
    localparam [1:0]
        S0 = 2'b00,
        S1 = 2'b01,
        S2 = 2'b10,
        S3 = 2'b11;

    reg [1:0] state, next_state;

    always @(posedge clk) begin
        if (!rst_n)
            state <= S0;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;
        detected   = 1'b0;

        case (state)
            S0: next_state = din ? S1 : S0;
            S1: next_state = din ? S1 : S2;
            S2: next_state = din ? S3 : S0;
            S3: begin
                if (din) begin
                    detected   = 1'b1;
                    next_state = S1;
                end else begin
                    next_state = S2;
                end
            end
            default: next_state = S0;
        endcase
    end
endmodule
