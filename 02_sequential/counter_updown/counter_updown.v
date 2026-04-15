/*******************************************************************************
 * Module: counter_updown.v                                                    *
 * Description:                                                                *
 * File Created: Tuesday, 14th April 2026 1:55:54 pm                           *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Wednesday, 15th April 2026 3:05:04 pm                        *
 * Modified By: Long Hai                                                       *
*******************************************************************************/

`timescale 1ps/1ps

module counter_updown (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       up_down,
    output reg  [3:0] q
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 4'b0;
        else if (up_down)
            q <= q + 1;
        else
            q <= q - 1;
    end
endmodule
