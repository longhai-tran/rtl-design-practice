/*******************************************************************************
 * Module: async_fifo_tb.v                                                     *
 * Description: Self-checking testbench for async_fifo.                        *\
 *              Uses a reference ring-buffer model to verify data integrity.   *
 *              Tests: reset, fill-to-full, drain-to-empty, random stress.     *
 * File Created: Wednesday, 22nd April 2026 11:34:44 am                        *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Tuesday, 22nd April 2026 1:31:00 pm                         *
 * Modified By: Long Hai                                                       *
 ******************************************************************************/

`timescale 1ns/1ps

module async_fifo_tb;

    // -------------------------------------------------------------------------
    // Parameters (must match DUT)
    // -------------------------------------------------------------------------
    localparam DATA_WIDTH = 8;
    localparam ADDR_WIDTH = 4;
    localparam DEPTH      = (1 << ADDR_WIDTH);
    localparam TIMEOUT    = 2000;  // Max cycles to wait in push/pop before abort

    // -------------------------------------------------------------------------
    // DUT signals
    // -------------------------------------------------------------------------
    reg                   wr_clk;
    reg                   rd_clk;
    reg                   rst_n;
    reg                   wr_en;
    reg                   rd_en;
    reg  [DATA_WIDTH-1:0] din;
    wire [DATA_WIDTH-1:0] dout;
    wire                  full;
    wire                  empty;

    // -------------------------------------------------------------------------
    // Tracking / scoreboard variables
    // -------------------------------------------------------------------------
    integer pass_count;
    integer fail_count;

    // -------------------------------------------------------------------------
    // Reference model (ring-buffer)
    // -------------------------------------------------------------------------
    reg [DATA_WIDTH-1:0] model_mem [0:DEPTH-1];
    integer model_wr_ptr;
    integer model_rd_ptr;
    integer model_count;

    // -------------------------------------------------------------------------
    // Misc helper variables
    // -------------------------------------------------------------------------
    integer i;
    integer timeout_cnt;
    reg [DATA_WIDTH-1:0] expected_data;
    reg                  status_ok;

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .wr_clk(wr_clk),
        .rd_clk(rd_clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .din(din),
        .dout(dout),
        .full(full),
        .empty(empty)
    );

    // -------------------------------------------------------------------------
    // Clock generation: wr_clk = 100 MHz (10 ns), rd_clk ~71 MHz (14 ns)
    // -------------------------------------------------------------------------
    initial wr_clk = 1'b0;
    always #5 wr_clk = ~wr_clk;

    initial rd_clk = 1'b0;
    always #7 rd_clk = ~rd_clk;

    // -------------------------------------------------------------------------
    // Task: model_push — push data into reference ring-buffer
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
    // Task: model_pop — pop data from reference ring-buffer
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
    // Task: check — increment pass/fail counter and print result
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
    // Task: push_byte — drive DUT write port; updates reference model
    //        Timeout abort: stops simulation if full never de-asserts
    // -------------------------------------------------------------------------
    task push_byte;
        input [DATA_WIDTH-1:0] data_in;
        begin
            timeout_cnt = 0;
            while (full) begin
                @(posedge wr_clk); #1;
                timeout_cnt = timeout_cnt + 1;
                if (timeout_cnt >= TIMEOUT) begin
                    $display("[%0t] TIMEOUT: full never de-asserted in push_byte", $time);
                    $finish;
                end
            end

            din   <= data_in;
            wr_en <= 1'b1;
            @(posedge wr_clk); #1;
            wr_en <= 1'b0;

            model_push(data_in);
            check(model_count <= DEPTH, "Model count within FIFO depth after write");
        end
    endtask

    // -------------------------------------------------------------------------
    // Task: pop_and_check — drive DUT read port; compare against reference model
    //        Timeout abort: stops simulation if empty never de-asserts
    // -------------------------------------------------------------------------
    task pop_and_check;
        begin
            timeout_cnt = 0;
            while (empty) begin
                @(posedge rd_clk); #1;
                timeout_cnt = timeout_cnt + 1;
                if (timeout_cnt >= TIMEOUT) begin
                    $display("[%0t] TIMEOUT: empty never de-asserted in pop_and_check", $time);
                    $finish;
                end
            end

            model_pop(expected_data);
            rd_en <= 1'b1;
            @(posedge rd_clk); #1;
            rd_en <= 1'b0;

            if (dout !== expected_data) begin
                fail_count = fail_count + 1;
                $display("[%0t] FAIL: Read data mismatch — expected=0x%02h, got=0x%02h",
                         $time, expected_data, dout);
            end else begin
                pass_count = pass_count + 1;
                $display("[%0t] PASS: Read data matches FIFO order (0x%02h)", $time, dout);
            end
            check(model_count >= 0, "Model count non-negative after read");
        end
    endtask

    // -------------------------------------------------------------------------
    // Stimulus
    // -------------------------------------------------------------------------
    initial begin
        pass_count = 0;
        fail_count = 0;

        // ---- Reset phase ----
        rst_n = 1'b0;
        wr_en = 1'b0;
        rd_en = 1'b0;
        din   = {DATA_WIDTH{1'b0}};

        model_wr_ptr = 0;
        model_rd_ptr = 0;
        model_count  = 0;

        repeat (4) @(posedge wr_clk);
        rst_n = 1'b1;

        repeat (4) @(posedge rd_clk);
        #1;

        $display("=== async_fifo Testbench (directed + stress) ===");

        // ---- TC1: Reset state ----
        check(empty === 1'b1, "FIFO is empty after reset");
        check(full  === 1'b0, "FIFO is not full after reset");

        // ---- TC2: Fill to full ----
        for (i = 0; i < DEPTH; i = i + 1) begin
            push_byte(i[DATA_WIDTH-1:0]);
        end

        status_ok = 1'b0;
        for (i = 0; i < 8; i = i + 1) begin // loop 8 times because full flag is generated in write domain and it takes 2 clock cycles to propagate to read domain
            @(posedge wr_clk); #1;
            if (full) status_ok = 1'b1;
        end
        check(status_ok, "Full flag asserts after filling FIFO");

        // ---- TC3: Drain to empty ----
        for (i = 0; i < DEPTH; i = i + 1) begin
            pop_and_check();
        end

        status_ok = 1'b0;
        for (i = 0; i < 8; i = i + 1) begin
            @(posedge rd_clk); #1;
            if (empty) status_ok = 1'b1;
        end
        check(status_ok, "Empty flag asserts after draining FIFO");

        // ---- TC4: Random concurrent read/write stress ----
        for (i = 0; i < 50; i = i + 1) begin
            if (($random % 2) != 0) begin
                push_byte($random % 256);
            end

            if ((model_count > 0) && (($random % 2) != 0)) begin
                pop_and_check();
            end
        end

        // ---- Drain remaining items ----
        while (model_count > 0) begin
            pop_and_check();
        end

        check(model_count == 0, "Model FIFO is empty at end of test");

        // ---- Final verdict ----
        $display("-----------------------------------------------");
        if (fail_count == 0)
            $display("=== PASS: all %0d checks passed ===", pass_count);
        else
            $display("=== FAIL: %0d passed, %0d failed ===", pass_count, fail_count);

        $finish;
    end

endmodule
