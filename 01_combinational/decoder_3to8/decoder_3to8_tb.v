/*******************************************************************************
 * Module: decoder_3to8_tb.v                                                   *
 * Description: Self-checking testbench for decoder_3to8                      *
 * File Created: Thursday, 9th April 2026                                      *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Thursday, 9th April 2026                                     *
 * Modified By: Long Hai                                                       *
*******************************************************************************/

`timescale 1ns/1ps

module decoder_3to8_tb;
    reg  [2:0] in;
    reg        en;
    wire [7:0] y;

    reg  [7:0] expected_y;
    integer i;
    integer error_count;

    decoder_3to8 dut (
        .in(in),
        .en(en),
        .y(y)
    );

    initial begin
        error_count = 0;
        $display("=== DECODER 3to8 Testbench ===");

        for (i = 0; i < 16; i = i + 1) begin
            {en, in} = i[3:0];
            #10;

            expected_y = en ? (8'b00000001 << in) : 8'b00000000;
            if (y !== expected_y) begin
                error_count = error_count + 1;
                $display("%4t | en=%b in=%b | y=%b | exp=%b | FAIL", $time, en, in, y, expected_y);
            end else begin
                $display("%4t | en=%b in=%b | y=%b | exp=%b | PASS", $time, en, in, y, expected_y);
            end
        end

        if (error_count == 0)
            $display("=== PASS: all 16 test vectors matched ===");
        else
            $display("=== FAIL: %0d mismatches detected ===", error_count);

        $finish;
    end
endmodule
