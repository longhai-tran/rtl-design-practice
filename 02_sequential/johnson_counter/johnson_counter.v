/*******************************************************************************
 * Module: johnson_counter.v                                                   *
 * Description:                                                                *
 * File Created: Wednesday, 15th April 2026 4:30:15 pm                         *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Wednesday, 15th April 2026 9:42:44 pm                        *
 * Modified By: Long Hai                                                       *
*******************************************************************************/

`timescale 1ns/1ps

module johnson_counter (
    input  wire       clk,
    input  wire       rst_n,
    output reg  [3:0] q
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 4'b0;
        else
            q <= {q[2:0], ~q[3]};
    end
endmodule
