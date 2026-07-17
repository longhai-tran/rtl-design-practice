/*******************************************************************************
 * Module: sync_fifo_tb.v                                                      *
 * Description: Self-checking testbench for sync_fifo.                         *
 *              Uses a reference ring-buffer model to verify reset, fill,      *
 *              drain, overflow/underflow guards, simultaneous read/write,     *
 *              wrap-around, and random stress behavior.                       *
 * File Created: Wednesday, 22nd April 2026 11:38:00 am                        *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Friday, 17th July 2026                                       *
 * Modified By: Long Hai                                                       *
 ******************************************************************************/

`timescale 1ns/1ps

module sync_fifo_tb;

    // -------------------------------------------------------------------------
    // Parameters (must match DUT)
    // -------------------------------------------------------------------------
    localparam DATA_WIDTH = 4;
    localparam ADDR_WIDTH = 2;
    localparam DEPTH      = (1 << ADDR_WIDTH);

    // -------------------------------------------------------------------------
    // DUT signals
    // -------------------------------------------------------------------------
    reg                   clk;
    reg                   rst_n;
    reg                   wr_en;
    reg                   rd_en;
    reg  [DATA_WIDTH-1:0] din;
    wire [DATA_WIDTH-1:0] dout;
    wire                  full;
    wire                  empty;
    wire [ADDR_WIDTH:0]   level;

    // -------------------------------------------------------------------------
    // Tracking / scoreboard variables
    // -------------------------------------------------------------------------
    integer pass_count;
    integer fail_count;

    reg [DATA_WIDTH-1:0] model_mem [0:DEPTH-1];
    integer model_wr_ptr;
    integer model_rd_ptr;
    integer model_count;

    integer i;
    integer rand_data;
    integer seed;           // random seed (override with +SEED=<N>)
    reg     expect_rd_fire;
    reg     expect_wr_fire;
    reg [DATA_WIDTH-1:0] expected_dout;

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    sync_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .din(din),
        .dout(dout),
        .full(full),
        .empty(empty),
        .level(level)
    );

    // -------------------------------------------------------------------------
    // Clock generation: 100 MHz (10 ns period)
    // -------------------------------------------------------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // Timeout watchdog: abort simulation if DUT hangs
    // -------------------------------------------------------------------------
    initial begin
        #500_000;  // 500 µs at 100 MHz = 50,000 cycles — well above test budget
        $display("[%0t] ERROR: Simulation timeout — DUT may be hung!", $time);
        $finish;
    end

    // -------------------------------------------------------------------------
    // Task: model_reset - clear reference ring-buffer state
    // -------------------------------------------------------------------------
    task model_reset;
        begin
            model_wr_ptr = 0;
            model_rd_ptr = 0;
            model_count  = 0;
            for (i = 0; i < DEPTH; i = i + 1) begin
                model_mem[i] = {DATA_WIDTH{1'b0}};
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // Task: model_push - push data into reference ring-buffer
    // -------------------------------------------------------------------------
    task model_push;
        input [DATA_WIDTH-1:0] data_in;
        begin
            model_mem[model_wr_ptr] = data_in;
            model_wr_ptr = (model_wr_ptr + 1) % DEPTH;
            model_count = model_count + 1;
        end
    endtask

    // -------------------------------------------------------------------------
    // Task: model_pop - pop data from reference ring-buffer
    // -------------------------------------------------------------------------
    task model_pop;
        output [DATA_WIDTH-1:0] data_out;
        begin
            data_out = model_mem[model_rd_ptr];
            model_rd_ptr = (model_rd_ptr + 1) % DEPTH;
            model_count = model_count - 1;
        end
    endtask

    // -------------------------------------------------------------------------
    // Task: check - increment pass/fail counter and print result
    // -------------------------------------------------------------------------
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

    // -------------------------------------------------------------------------
    // Task: check_status - compare flags and occupancy against reference model
    // -------------------------------------------------------------------------
    task check_status;
        input [8*120-1:0] msg;
        begin
            if ((level !== model_count[ADDR_WIDTH:0]) ||
                (full  !== (model_count == DEPTH)) ||
                (empty !== (model_count == 0))) begin
                fail_count = fail_count + 1;
                $display("[%0t] FAIL: %0s -- count=%0d level=%0d full=%b empty=%b",
                         $time, msg, model_count, level, full, empty);
            end else begin
                pass_count = pass_count + 1;
                $display("[%0t] PASS: %0s -- count=%0d full=%b empty=%b",
                         $time, msg, model_count, full, empty);
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // Task: apply_reset - reset DUT and reference model
    // -------------------------------------------------------------------------
    task apply_reset;
        begin
            @(negedge clk);
            rst_n = 1'b0;
            wr_en = 1'b0;
            rd_en = 1'b0;
            din   = {DATA_WIDTH{1'b0}};
            model_reset();

            repeat (2) @(posedge clk);
            #1;

            check(dout === {DATA_WIDTH{1'b0}}, "dout clears after reset");
            check_status("FIFO status after reset");

            @(negedge clk);
            rst_n = 1'b1;
        end
    endtask

    // -------------------------------------------------------------------------
    // Task: drive_cycle - drive one FIFO cycle and update/check reference model
    // -------------------------------------------------------------------------
    task drive_cycle;
        input                  wr_req;
        input                  rd_req;
        input [DATA_WIDTH-1:0] data_in;
        input [8*120-1:0]      msg;
        begin
            expect_rd_fire = rd_req && (model_count > 0);
            expect_wr_fire = wr_req && ((model_count < DEPTH) || expect_rd_fire);

            if (expect_rd_fire) begin
                expected_dout = model_mem[model_rd_ptr];
            end else begin
                expected_dout = dout;
            end

            @(negedge clk);
            wr_en = wr_req;
            rd_en = rd_req;
            din   = data_in;
            @(posedge clk); #1;

            if (expect_rd_fire) begin
                if (dout !== expected_dout) begin
                    fail_count = fail_count + 1;
                    $display("[%0t] FAIL: %0s -- expected dout=0x%02h got=0x%02h",
                             $time, msg, expected_dout, dout);
                end else begin
                    pass_count = pass_count + 1;
                    $display("[%0t] PASS: %0s -- dout=0x%02h",
                             $time, msg, dout);
                end
            end else begin
                check(dout === expected_dout, msg);
            end

            if (expect_rd_fire) begin
                model_pop(expected_dout);
            end

            if (expect_wr_fire) begin
                model_push(data_in);
            end

            check_status("Status matches reference model after cycle");

            @(negedge clk);
            wr_en = 1'b0;
            rd_en = 1'b0;
        end
    endtask

    // -------------------------------------------------------------------------
    // Stimulus
    // -------------------------------------------------------------------------
    initial begin
        pass_count = 0;
        fail_count = 0;

        // Resolve random seed from plusarg (+SEED=<N>), default to 12345
        if (!$value$plusargs("SEED=%d", seed)) seed = 32'd12345;
        $display("=== Random seed: %0d ===", seed);

        rst_n = 1'b1;
        wr_en = 1'b0;
        rd_en = 1'b0;
        din   = {DATA_WIDTH{1'b0}};
        model_reset();

        $display("=== sync_fifo Testbench (directed + random self-check) ===");

        // ---- TC1: Reset behavior ----
        $display("\n--- TC1: Reset behavior ---");
        apply_reset();

        // ---- TC2: Underflow guard ----
        $display("\n--- TC2: Underflow guard ---");
        drive_cycle(1'b0, 1'b1, 8'h00, "Read request while empty is ignored");

        // ---- TC3: Fill to full ----
        $display("\n--- TC3: Fill to full ---");
        for (i = 1; i < DEPTH+1; i = i + 1) begin
            drive_cycle(1'b1, 1'b0, (8'h40 + i[DATA_WIDTH-1:0]), "Write accepted while FIFO is not full");
        end

        check(full === 1'b1, "Full flag asserts after filling FIFO");

        // ---- TC4: Overflow guard ----
        $display("\n--- TC4: Overflow guard ---");
        drive_cycle(1'b1, 1'b0, 8'hEE, "Write request while full is ignored");
        check(model_count == DEPTH, "Reference model remains full after overflow attempt");

        // ---- TC5: Simultaneous read/write while full ----
        $display("\n--- TC5: Simultaneous read/write while full ---");
        drive_cycle(1'b1, 1'b1, 8'hF0, "Simultaneous read/write while full preserves throughput");
        check(full === 1'b1, "FIFO remains full after full-state pop+push");

        // ---- TC6: Drain to empty ----
        $display("\n--- TC6: Drain to empty ---");
        while (model_count > 0) begin
            drive_cycle(1'b0, 1'b1, 8'h00, "Read returns FIFO data in order");
        end

        check(empty === 1'b1, "Empty flag asserts after draining FIFO");

        // ---- TC7: Wrap-around and simultaneous mid-level traffic ----
        $display("\n--- TC7: Wrap-around and simultaneous mid-level traffic ---");
        for (i = 0; i < 6; i = i + 1) begin
            drive_cycle(1'b1, 1'b0, (8'h80 + i[DATA_WIDTH-1:0]), "Preload for wrap-around test");
        end

        for (i = 0; i < 20; i = i + 1) begin
            drive_cycle(1'b1, 1'b1, (8'hA0 + i[DATA_WIDTH-1:0]), "Simultaneous read/write preserves order");
        end

        while (model_count > 0) begin
            drive_cycle(1'b0, 1'b1, 8'h00, "Drain after wrap-around traffic");
        end

        // ---- TC8: Random stress ----
        $display("\n--- TC8: Random stress ---");
        for (i = 0; i < 40; i = i + 1) begin
            rand_data = ($random(seed) & ((1 << DATA_WIDTH) - 1));
            drive_cycle(($random(seed) % 2) != 0, ($random(seed) % 2) != 0,
                        rand_data[DATA_WIDTH-1:0], "Random traffic matches reference model");
        end

        while (model_count > 0) begin
            drive_cycle(1'b0, 1'b1, 8'h00, "Final drain preserves order");
        end

        check(model_count == 0, "Reference FIFO is empty at end of test");

        // ---- Final verdict ----
        $display("-----------------------------------------------");
        if (fail_count == 0)
            $display("=== PASS: all %0d checks passed ===", pass_count);
        else
            $display("=== FAIL: %0d passed, %0d failed ===", pass_count, fail_count);

        $finish;
    end

endmodule
