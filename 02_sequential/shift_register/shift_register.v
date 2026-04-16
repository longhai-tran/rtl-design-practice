/*******************************************************************************
 * Module: shift_register.v                                                    *
 * Description:                                                                *
 * File Created: Tuesday, 14th April 2026 1:55:54 pm                           *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Tuesday, 14th April 2026 4:42:19 pm                          *
 * Modified By: Long Hai                                                       *
*******************************************************************************/

`timescale 1ns/1ps

module shift_register (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       din,
    output reg  [3:0] q
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 4'b0;
        else
            q <= {q[2:0], din};
    end
endmodule
