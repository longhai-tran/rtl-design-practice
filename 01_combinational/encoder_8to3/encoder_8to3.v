/*******************************************************************************
 * Module: encoder_8to3.v                                                      *
 * Description: 8-to-3 one-hot encoder with valid output                       *
 * File Created: Thursday, 9th April 2026                                      *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Thursday, 9th April 2026                                     *
 * Modified By: Long Hai                                                       *
*******************************************************************************/

`timescale 1ns/1ps

module encoder_8to3(
    input  wire [7:0] d,      // One-hot data input
    output reg  [2:0] y,      // Encoded output
    output reg        valid   // Valid output (1 when input is one-hot)
);
    always @(*) begin
        y = 3'b000;
        valid = 1'b1;

        case (d)
            8'b00000001: y = 3'b000;
            8'b00000010: y = 3'b001;
            8'b00000100: y = 3'b010;
            8'b00001000: y = 3'b011;
            8'b00010000: y = 3'b100;
            8'b00100000: y = 3'b101;
            8'b01000000: y = 3'b110;
            8'b10000000: y = 3'b111;
            default: begin
                y = 3'b000;
                valid = 1'b0;
            end
        endcase
    end
endmodule
