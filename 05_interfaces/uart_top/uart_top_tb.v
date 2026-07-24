/*******************************************************************************
 * Module: uart_top_tb.v                                                       *
 * Description: Self-checking loopback and fault-injection testbench for the   *
 *              full-duplex uart_top wrapper.                                  *
 * File Created: Thursday, 23rd July 2026 1:19:21 pm                           *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Friday, 24th July 2026 1:47:54 pm                            *
 * Modified By: Long Hai                                                       *
*******************************************************************************/

`timescale 1ns/1ps

module uart_top_tb;

    localparam integer CLK_FREQ_HZ  = 8_000_000;
    localparam integer BAUD_RATE    = 1_000_000;
    localparam integer CLKS_PER_BIT = CLK_FREQ_HZ / BAUD_RATE;

    reg        clk;
    reg        rst_n;
    reg        tx_start;
    reg  [7:0] tx_data;
    wire       tx;
    wire       tx_busy;
    wire       tx_done;
    reg        loopback_enable;
    reg        rx_drive;
    wire       rx;
    wire [7:0] rx_data;
    wire       rx_busy;
    wire       rx_done_valid;
    wire       framing_error;

    integer pass_count;
    integer fail_count;
    integer tx_done_count;
    integer rx_valid_count;
    integer error_count;
    integer i;
    integer count_before;
    reg [7:0] observed_data;

    assign rx = loopback_enable ? tx : rx_drive;

    uart_top #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done),
        .rx(rx),
        .rx_data(rx_data),
        .rx_busy(rx_busy),
        .rx_done_valid(rx_done_valid),
        .framing_error(framing_error)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (!rst_n) begin
            tx_done_count  <= 0;
            rx_valid_count <= 0;
            error_count    <= 0;
        end else begin
            if (tx_done) begin
                tx_done_count <= tx_done_count + 1;
            end
            if (rx_done_valid) begin
                rx_valid_count <= rx_valid_count + 1;
                observed_data  <= rx_data;
            end
            if (framing_error) begin
                error_count <= error_count + 1;
            end
        end
    end

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
            rst_n           = 1'b0;
            tx_start        = 1'b0;
            tx_data         = 8'h00;
            loopback_enable = 1'b1;
            rx_drive        = 1'b1;
            repeat (3) @(posedge clk);
            #1;
            check((tx === 1'b1) && (tx_busy === 1'b0) &&
                  (rx_data === 8'h00) && (rx_busy === 1'b0) &&
                  (rx_done_valid === 1'b0) && (framing_error === 1'b0),
                  "Reset restores both UART directions to idle");
            @(negedge clk);
            rst_n = 1'b1;
            repeat (2) @(posedge clk);
        end
    endtask

    task launch_tx;
        input [7:0] payload;
        begin
            @(negedge clk);
            tx_data  = payload;
            tx_start = 1'b1;
            @(posedge clk); #1;
            check((tx_busy === 1'b1) && (tx === 1'b0),
                  "TX request starts a UART frame");
            @(negedge clk);
            tx_start = 1'b0;
        end
    endtask

    task wait_for_loopback;
        input [7:0] payload;
        input [8*120-1:0] msg;
        integer valid_before;
        integer done_before;
        begin
            valid_before = rx_valid_count;
            done_before  = tx_done_count;
            launch_tx(payload);
            wait (rx_done_valid === 1'b1);
            @(posedge clk);
            #1;
            check(observed_data === payload, msg);
            check(rx_valid_count == (valid_before + 1),
                  "Loopback produces one RX valid event");
            wait (tx_done === 1'b1);
            @(posedge clk);
            #1;
            check(tx_done_count == (done_before + 1),
                  "TX produces one completion event");
            check((tx_busy === 1'b0) && (rx_busy === 1'b0),
                  "Both directions return to idle after loopback");
        end
    endtask

    task hold_rx_bit;
        input level;
        begin
            rx_drive = level;
            repeat (CLKS_PER_BIT) @(posedge clk);
        end
    endtask

    task drive_rx_frame;
        input [7:0] payload;
        input       stop_level;
        begin
            @(negedge clk);
            loopback_enable = 1'b0;
            hold_rx_bit(1'b0);
            for (i = 0; i < 8; i = i + 1) begin
                hold_rx_bit(payload[i]);
            end
            hold_rx_bit(stop_level);
            rx_drive = 1'b1;
            repeat (4) @(posedge clk);
            #1;
        end
    endtask

    initial begin
        #40_000;
        $display("[FAIL] Timeout waiting for UART top testbench completion");
        $finish;
    end

    initial begin
        pass_count      = 0;
        fail_count      = 0;
        tx_done_count   = 0;
        rx_valid_count  = 0;
        error_count     = 0;
        observed_data   = 8'h00;
        rst_n           = 1'b1;
        tx_start        = 1'b0;
        tx_data         = 8'h00;
        loopback_enable = 1'b1;
        rx_drive        = 1'b1;

        $display("=== uart_top Testbench (full-duplex self-check) ===");

        $display("\n--- TC1: Reset and idle behavior ---");
        apply_reset();
        repeat (3 * CLKS_PER_BIT) @(posedge clk); #1;
        check((tx === 1'b1) && (tx_busy === 1'b0) &&
              (rx_busy === 1'b0) && (rx_done_valid === 1'b0),
              "Idle UART lines remain inactive");

        $display("\n--- TC2: TX-to-RX loopback payloads ---");
        wait_for_loopback(8'h55, "Loopback transfers 0x55 correctly");
        wait_for_loopback(8'hA3, "Loopback transfers 0xA3 correctly");
        wait_for_loopback(8'h00, "Loopback transfers 0x00 correctly");
        wait_for_loopback(8'hFF, "Loopback transfers 0xFF correctly");

        $display("\n--- TC3: TX busy request rejection ---");
        count_before = rx_valid_count;
        launch_tx(8'h3C);
        repeat (3 * CLKS_PER_BIT) @(posedge clk);
        @(negedge clk);
        tx_data  = 8'hF0;
        tx_start = 1'b1;
        @(posedge clk); #1;
        check(tx_busy === 1'b1, "Second TX request is ignored while busy");
        @(negedge clk);
        tx_start = 1'b0;
        wait (rx_done_valid === 1'b1);
        @(posedge clk);
        #1;
        check(observed_data === 8'h3C, "Busy rejection preserves active TX payload");
        check(rx_valid_count == (count_before + 1), "Busy rejection creates no extra RX frame");
        wait (tx_done === 1'b1);
        @(posedge clk); #1;

        wait_for_loopback(8'hF0, "New TX request is accepted after completion");

        $display("\n--- TC4: RX framing error through top wrapper ---");
        count_before = error_count;
        drive_rx_frame(8'h5A, 1'b0);
        check(error_count == (count_before + 1), "RX framing error reaches top-level output");
        check(rx_data !== 8'h5A, "Invalid RX frame does not commit payload");
        loopback_enable = 1'b1;
        wait_for_loopback(8'h96, "RX recovers after top-level framing error");

        $display("\n--- TC5: Reset aborts active full-duplex transaction ---");
        launch_tx(8'h69);
        repeat (2 * CLKS_PER_BIT) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b0;
        repeat (2) @(posedge clk); #1;
        check((tx_busy === 1'b0) && (rx_busy === 1'b0) &&
              (tx_done === 1'b0) && (rx_done_valid === 1'b0),
              "Reset aborts TX and RX state machines together");
        @(negedge clk);
        rst_n = 1'b1;
        repeat (3) @(posedge clk);
        wait_for_loopback(8'hC3, "Full-duplex wrapper restarts cleanly after reset");

        $display("-----------------------------------------------");
        if (fail_count == 0)
            $display("=== PASS: 5 TCs, all %0d checks passed ===", pass_count);
        else
            $display("=== FAIL: 5 TCs, %0d passed, %0d failed ===", pass_count, fail_count);

        $finish;
    end

endmodule
