/*******************************************************************************
 * Module: uart_tx_tb.v                                                        *
 * Description: Directed self-checking testbench for the UART transmitter.     *
 * File Created: Friday, 17th July 2026 3:17:37 pm                             *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Tuesday, 21st July 2026 3:37:15 pm                           *
 * Modified By: Long Hai                                                       *
*******************************************************************************/

`timescale 1ns/1ps

module uart_tx_tb;

    localparam integer CLK_FREQ_HZ = 8_000_000;
    localparam integer BAUD_RATE   = 1_000_000;
    localparam integer CLKS_PER_BIT = CLK_FREQ_HZ / BAUD_RATE;

    reg        clk;
    reg        rst_n;
    reg        tx_start;
    reg  [7:0] data_in;
    wire       tx;
    wire       tx_busy;
    wire       tx_done;

    integer pass_count;
    integer fail_count;
    integer i;
    reg [8*120-1:0] bit_msg;

    uart_tx #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .tx_start(tx_start),
        .data_in(data_in),
        .tx(tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task check;
        input cond;
        input [8*120-1:0] msg;
        begin
            if (cond) begin
                pass_count = pass_count + 1;
                $display("[%0t] PASS: %0s", $time, msg);
            end else begin
                fail_count = fail_count + 1;
                $display("[%0t] FAIL: %0s", $time, msg);
            end
        end
    endtask

    task apply_reset;
        begin
            @(negedge clk);
            rst_n    = 1'b0;
            tx_start = 1'b0;
            data_in  = 8'h00;
            repeat (2) @(posedge clk);
            #1;
            check((tx === 1'b1) && (tx_busy === 1'b0) && (tx_done === 1'b0),
                  "Reset restores idle outputs");
            @(negedge clk);
            rst_n = 1'b1;
            @(posedge clk); #1;
        end
    endtask

    task launch_byte;
        input [7:0] payload;
        begin
            @(negedge clk);
            data_in  = payload;
            tx_start = 1'b1;
            @(posedge clk); #1;
            check((tx === 1'b0) && (tx_busy === 1'b1),
                  "Accepted request drives start bit and busy");
            @(negedge clk);
            tx_start = 1'b0;
        end
    endtask

    task check_frame;
        input [7:0] payload;
        input [8*120-1:0] msg;
        begin
            check(tx === 1'b0, "Start bit is low");
            repeat (CLKS_PER_BIT) @(posedge clk);
            #1;

            for (i = 0; i < 8; i = i + 1) begin
                $sformat(bit_msg, "Data bit[%0d] matches LSB-first payload", i);
                check(tx === payload[i], bit_msg);
                repeat (CLKS_PER_BIT) @(posedge clk);
                #1;
            end

            check((tx === 1'b1) && (tx_busy === 1'b1), "Stop bit is high");
            repeat (CLKS_PER_BIT) @(posedge clk);
            #1;
            check((tx === 1'b1) && (tx_busy === 1'b0) && (tx_done === 1'b1), msg);

            @(posedge clk); #1;
            check(tx_done === 1'b0, "Done is a one-clock pulse");
        end
    endtask

    task transmit_and_check;
        input [7:0] payload;
        input [8*120-1:0] msg;
        begin
            launch_byte(payload);
            check_frame(payload, msg);
        end
    endtask

    initial begin
        #20_000;
        $display("[FAIL] Timeout waiting for UART testbench completion");
        $finish;
    end

    initial begin
        pass_count = 0;
        fail_count = 0;
        rst_n      = 1'b1;
        tx_start   = 1'b0;
        data_in    = 8'h00;

        $display("=== uart_tx Testbench (directed self-check) ===");

        $display("\n--- TC1: Reset and idle behavior ---");
        apply_reset();
        repeat (3) @(posedge clk); #1;
        check((tx === 1'b1) && (tx_busy === 1'b0) && (tx_done === 1'b0),
              "Transmitter holds idle line high");

        $display("\n--- TC2: Alternating-bit patterns ---");
        transmit_and_check(8'h43, "Frame 0x43 completed correctly");
        transmit_and_check(8'hA3, "Frame 0xA3 completed correctly");

        $display("\n--- TC3: Boundary data patterns ---");
        transmit_and_check(8'h00, "Frame 0x00 completed correctly");
        transmit_and_check(8'hFF, "Frame 0xFF completed correctly");

        $display("\n--- TC4: Input changes and busy request are ignored ---");
        launch_byte(8'h3C);
        fork
            begin
                check_frame(8'h3C, "Active frame remains the originally latched byte");
            end
            begin
                repeat (3 * CLKS_PER_BIT) @(posedge clk);
                @(negedge clk);
                data_in  = 8'hF0;
                tx_start = 1'b1;
                @(posedge clk); #1;
                check(tx_busy === 1'b1, "Request while busy does not terminate active frame");
                @(negedge clk);
                tx_start = 1'b0;
            end
        join

        // TC5: FSM recovery — transmit the same byte (0xF0) that was rejected
        // while busy in TC4. Proves the FSM returned cleanly to IDLE after
        // ignoring the spurious request and is ready to accept new work.
        $display("\n--- TC5: FSM recovery after TC4 busy-ignore ---");
        transmit_and_check(8'hF0, "FSM recovered cleanly: byte rejected in TC4 now transmits correctly");

        $display("-----------------------------------------------");
        if (fail_count == 0)
            $display("=== PASS: 5 TCs, all %0d checks passed ===", pass_count);
        else
            $display("=== FAIL: 5 TCs, %0d passed, %0d failed ===", pass_count, fail_count);

        $finish;
    end

endmodule
