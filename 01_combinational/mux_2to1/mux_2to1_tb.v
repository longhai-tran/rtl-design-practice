/*******************************************************************************
 * Module: mux_2to1_tb.v                                                       *
 * Description:                                                                *
 * File Created: Friday, 3rd April 2026 2:04:46 pm                             *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Friday, 3rd April 2026 2:05:02 pm                            *
 * Modified By: Long Hai                                                       *
*******************************************************************************/

`timescale 1ns/1ps

module mux_2to1_tb;
    reg  a, b, sel;
    wire y;

    mux_2to1 #(.WIDTH(1)) dut (.a(a), .b(b), .sel(sel), .y(y));

    initial begin
        $display("=== MUX 2to1 Testbench ===");
        $monitor("t=%0t | a=%b b=%b sel=%b | y=%b", $time, a, b, sel, y);

        {a, b, sel} = 3'b000; #10;
        {a, b, sel} = 3'b011; #10;
        {a, b, sel} = 3'b101; #10;
        {a, b, sel} = 3'b110; #10;

        $display("=== PASS ===");
        $finish;
    end
endmodule
