/*******************************************************************************
 * Module: single_port_sram_tb.v                                               *
 * Description: Self-checking testbench for single_port_sram.                  *
 *              Uses a reference memory model to verify reset, write/read,     *
 *              read-first behavior, chip-select hold, and random access.      *
 * File Created: Wednesday, 22nd April 2026 11:38:00 am                        *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Thursday, 16th July 2026                                     *
 * Modified By: Long Hai                                                       *
 ******************************************************************************/

`timescale 1ns/1ps

module single_port_sram_tb;

    // -------------------------------------------------------------------------
    // Parameters (must match DUT)
    // -------------------------------------------------------------------------
    localparam DATA_WIDTH = 8;
    localparam ADDR_WIDTH = 4;
    localparam DEPTH      = (1 << ADDR_WIDTH);

    // -------------------------------------------------------------------------
    // DUT signals
    // -------------------------------------------------------------------------
    reg                   clk;
    reg                   rst_n;
    reg                   cs;
    reg                   we;
    reg  [ADDR_WIDTH-1:0] addr;
    reg  [DATA_WIDTH-1:0] wdata;
    wire [DATA_WIDTH-1:0] rdata;

    // -------------------------------------------------------------------------
    // Tracking / scoreboard variables
    // -------------------------------------------------------------------------
    integer pass_count;
    integer fail_count;

    reg [DATA_WIDTH-1:0] model_mem [0:DEPTH-1];
    reg [DATA_WIDTH-1:0] hold_data;
    reg [DATA_WIDTH-1:0] old_data;

    integer i;
    integer rand_addr;
    integer rand_data;

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    single_port_sram #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .cs(cs),
        .we(we),
        .addr(addr),
        .wdata(wdata),
        .rdata(rdata)
    );

    // -------------------------------------------------------------------------
    // Clock generation: 100 MHz (10 ns period)
    // -------------------------------------------------------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // Task: model_init - initialize reference model to a known pattern
    // -------------------------------------------------------------------------
    task model_init;
        begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                model_mem[i] = {DATA_WIDTH{1'b0}};
            end
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
    // Task: apply_reset - reset only the registered read output
    // -------------------------------------------------------------------------
    task apply_reset;
        begin
            @(negedge clk);
            rst_n = 1'b0;
            cs    = 1'b0;
            we    = 1'b0;
            addr  = {ADDR_WIDTH{1'b0}};
            wdata = {DATA_WIDTH{1'b0}};
            repeat (2) @(posedge clk);
            #1;
            check(rdata === {DATA_WIDTH{1'b0}}, "Read data register clears during reset");
            @(negedge clk);
            rst_n = 1'b1;
        end
    endtask

    // -------------------------------------------------------------------------
    // Task: init_word - write one location during memory initialization
    // -------------------------------------------------------------------------
    task init_word;
        input [ADDR_WIDTH-1:0] word_addr;
        input [DATA_WIDTH-1:0] data_in;
        begin
            @(negedge clk);
            cs    = 1'b1;
            we    = 1'b1;
            addr  = word_addr;
            wdata = data_in;
            @(posedge clk); #1;

            model_mem[word_addr] = data_in;

            @(negedge clk);
            cs = 1'b0;
            we = 1'b0;
        end
    endtask

    // -------------------------------------------------------------------------
    // Task: write_word - synchronous write, read-first output checked
    // -------------------------------------------------------------------------
    task write_word;
        input [ADDR_WIDTH-1:0] word_addr;
        input [DATA_WIDTH-1:0] data_in;
        begin
            old_data = model_mem[word_addr];

            @(negedge clk);
            cs    = 1'b1;
            we    = 1'b1;
            addr  = word_addr;
            wdata = data_in;
            @(posedge clk); #1;

            check(rdata === old_data, "Write cycle returns old data at addressed location");
            // $display("rdata=%x old_data=%x", rdata, old_data);
            model_mem[word_addr] = data_in;

            @(negedge clk);
            cs = 1'b0;
            we = 1'b0;
        end
    endtask

    // -------------------------------------------------------------------------
    // Task: read_word - synchronous registered read
    // -------------------------------------------------------------------------
    task read_word;
        input [ADDR_WIDTH-1:0] word_addr;
        input [8*120-1:0]     msg;
        begin
            @(negedge clk);
            cs    = 1'b1;
            we    = 1'b0;
            addr  = word_addr;
            @(posedge clk); #1;

            if (rdata !== model_mem[word_addr]) begin
                fail_count = fail_count + 1;
                $display("[%0t] FAIL: %0s -- addr=%0d expected=0x%02h got=0x%02h",
                         $time, msg, word_addr, model_mem[word_addr], rdata);
            end else begin
                pass_count = pass_count + 1;
                $display("[%0t] PASS: %0s -- addr=%0d rdata=0x%02h",
                         $time, msg, word_addr, rdata);
            end

            @(negedge clk);
            cs = 1'b0;
        end
    endtask

    // -------------------------------------------------------------------------
    // Task: check_cs_hold - disabled SRAM holds registered output
    // -------------------------------------------------------------------------
    task check_cs_hold;
        begin
            hold_data = rdata;

            @(negedge clk);
            cs    = 1'b0;
            we    = 1'b1;
            addr  = {ADDR_WIDTH{1'b1}};
            wdata = {DATA_WIDTH{1'b1}};
            @(posedge clk); #1;

            check(rdata === hold_data, "Chip-select low holds registered read data");

            @(negedge clk);
            we = 1'b0;
        end
    endtask

    // -------------------------------------------------------------------------
    // Stimulus
    // -------------------------------------------------------------------------
    initial begin
        pass_count = 0;
        fail_count = 0;

        rst_n = 1'b1;
        cs    = 1'b0;
        we    = 1'b0;
        addr  = {ADDR_WIDTH{1'b0}};
        wdata = {DATA_WIDTH{1'b0}};
        model_init();

        $display("=== single_port_sram Testbench (directed + random self-check) ===");

        // ---- TC1: Reset behavior ----
        $display("\n--- TC1: Reset behavior ---");
        apply_reset();

        // ---- TC2: Directed write/read sweep ----
        $display("\n--- TC2: Directed write/read sweep ---");
        for (i = 0; i < DEPTH; i = i + 1) begin
            init_word(i[ADDR_WIDTH-1:0], (8'h30 + i[DATA_WIDTH-1:0]));
        end

        for (i = 0; i < DEPTH; i = i + 1) begin
            read_word(i[ADDR_WIDTH-1:0], "Directed read matches reference model");
        end

        // ---- TC3: Overwrite selected addresses ----
        $display("\n--- TC3: Overwrite selected addresses ---");
        write_word(4'd3, 8'hA5);
        write_word(4'd12, 8'h5A);
        read_word(4'd3, "Overwrite updates address 3");
        read_word(4'd12, "Overwrite updates address 12");
        read_word(4'd4, "Neighbor address remains unchanged");

        // ---- TC4: Chip-select hold behavior ----
        $display("\n--- TC4: Chip-select hold behavior ---");
        check_cs_hold();
        read_word({ADDR_WIDTH{1'b1}}, "Chip-select disabled write did not update memory");

        // ---- TC5: Read-first write/read same address policy ----
        $display("\n--- TC5: Read-first write/read same address policy ---");
        write_word(4'd3, 8'hC3);
        read_word(4'd3, "New data is visible after read-first write commits");

        // ---- TC6: Random write/read stress ----
        $display("\n--- TC6: Random write/read stress ---");
        for (i = 0; i < 20; i = i + 1) begin
            rand_addr = ($random & (DEPTH - 1));
            rand_data = ($random & ((1 << DATA_WIDTH) - 1));
            write_word(rand_addr[ADDR_WIDTH-1:0], rand_data[DATA_WIDTH-1:0]);
            read_word(rand_addr[ADDR_WIDTH-1:0], "Random write/read matches reference model");
        end

        // ---- Final verdict ----
        $display("-----------------------------------------------");
        if (fail_count == 0)
            $display("=== PASS: all %0d checks passed ===", pass_count);
        else
            $display("=== FAIL: %0d passed, %0d failed ===", pass_count, fail_count);

        $finish;
    end

endmodule
