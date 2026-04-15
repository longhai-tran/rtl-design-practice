/*******************************************************************************
 * Module: counter_4bit.v                                                      *
 * Description:                                                                *
 * File Created: Tuesday, 14th April 2026 1:55:53 pm                           *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Wednesday, 15th April 2026 10:47:46 am                       *
 * Modified By: Long Hai                                                       *
*******************************************************************************/

`timescale 1ps/1ps

module counter_4bit (
    input  wire       clk,
    input  wire       rst_n,
    output reg  [3:0] q
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 4'b0;
        else
            q <= q + 1;
    end
endmodule
