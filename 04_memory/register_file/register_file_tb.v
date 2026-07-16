/*******************************************************************************
 * Module: register_file_tb.v                                                  *
 * Description: Self-checking testbench for register_file.                     *
 *              Uses a reference array model to verify reset, writes, reads,   *
 *              zero-register behavior, overwrite, and write-disable cases.    *
 * File Created: Wednesday, 22nd April 2026 11:38:00 am                        *
 * Author: Long Hai                                                            *
 * -----                                                                       *
 * Last Modified: Tuesday, 14th July 2026                                      *
 * Modified By:                                                           *
 ******************************************************************************/

`timescale 1ns/1ps

module register_file_tb;

    // -------------------------------------------------------------------------
    // Parameters (must match DUT)
    // -------------------------------------------------------------------------
    localparam DATA_WIDTH      = 8;
    localparam ADDR_WIDTH      = 3;
    localparam NUM_REGS        = (1 << ADDR_WIDTH);
    localparam ZERO_REG_ENABLE = 1;

    // -------------------------------------------------------------------------
    // DUT signals
    // -------------------------------------------------------------------------
    reg                       clk;
    reg                       rst_n;
    reg                       we;
    reg  [ADDR_WIDTH-1:0]     waddr;
    reg  [DATA_WIDTH-1:0]     wdata;
    reg  [ADDR_WIDTH-1:0]     raddr1;
    reg  [ADDR_WIDTH-1:0]     raddr2;
    wire [DATA_WIDTH-1:0]     rdata1;
    wire [DATA_WIDTH-1:0]     rdata2;

    // -------------------------------------------------------------------------
    // Tracking / scoreboard variables
    // -------------------------------------------------------------------------
    integer pass_count;
    integer fail_count;

    reg [DATA_WIDTH-1:0] model_regs [0:NUM_REGS-1];

    integer i;
    reg [DATA_WIDTH-1:0] expected1;
    reg [DATA_WIDTH-1:0] expected2;

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    register_file #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .ZERO_REG_ENABLE(ZERO_REG_ENABLE)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .we(we),
        .waddr(waddr),
        .wdata(wdata),
        .raddr1(raddr1),
        .raddr2(raddr2),
        .rdata1(rdata1),
        .rdata2(rdata2)
    );

    // -------------------------------------------------------------------------
    // Clock generation: 100 MHz (10 ns period)
    // -------------------------------------------------------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // Task: model_reset - clear reference model
    // -------------------------------------------------------------------------
    task model_reset;
        begin
            for (i = 0; i < NUM_REGS; i = i + 1) begin
                model_regs[i] = {DATA_WIDTH{1'b0}};
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
    // Task: check_read_ports - compare both read ports against reference model
    // -------------------------------------------------------------------------
    task check_read_ports;
        input [ADDR_WIDTH-1:0] addr1;
        input [ADDR_WIDTH-1:0] addr2;
        input [8*120-1:0]     msg;
        begin
            raddr1 = addr1;
            raddr2 = addr2;
            #1;

            expected1 = ((ZERO_REG_ENABLE != 0) && (addr1 == {ADDR_WIDTH{1'b0}})) ?
                        {DATA_WIDTH{1'b0}} : model_regs[addr1];
            expected2 = ((ZERO_REG_ENABLE != 0) && (addr2 == {ADDR_WIDTH{1'b0}})) ?
                        {DATA_WIDTH{1'b0}} : model_regs[addr2];

            if ((rdata1 !== expected1) || (rdata2 !== expected2)) begin
                fail_count = fail_count + 1;
                $display("[%0t] FAIL: %0s -- raddr1=%0d exp1=0x%02h got1=0x%02h, raddr2=%0d exp2=0x%02h got2=0x%02h",
                         $time, msg, addr1, expected1, rdata1, addr2, expected2, rdata2);
            end else begin
                pass_count = pass_count + 1;
                $display("[%0t] PASS: %0s -- raddr1=%0d rdata1=0x%02h, raddr2=%0d rdata2=0x%02h",
                         $time, msg, addr1, rdata1, addr2, rdata2);
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // Task: apply_reset - drive reset and verify all registers clear
    // -------------------------------------------------------------------------
    task apply_reset;
        begin
            rst_n  = 1'b0;
            we     = 1'b0;
            waddr  = {ADDR_WIDTH{1'b0}};
            wdata  = {DATA_WIDTH{1'b0}};
            raddr1 = {ADDR_WIDTH{1'b0}};
            raddr2 = {ADDR_WIDTH{1'b0}};

            model_reset();

            repeat (2) @(posedge clk);
            #1;
            rst_n = 1'b1;
            @(posedge clk); #1;

            for (i = 0; i < NUM_REGS; i = i + 2) begin
                check_read_ports(i[ADDR_WIDTH-1:0], (i + 1) % NUM_REGS, "Registers read as zero after reset");
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // Task: write_reg - write one register and update reference model
    // -------------------------------------------------------------------------
    task write_reg;
        input [ADDR_WIDTH-1:0] addr;
        input [DATA_WIDTH-1:0] data;
        begin
            @(negedge clk);
            waddr = addr;
            wdata = data;
            we    = 1'b1;
            @(posedge clk); #1;
            we    = 1'b0;

            if (!((ZERO_REG_ENABLE != 0) && (addr == {ADDR_WIDTH{1'b0}}))) begin
                model_regs[addr] = data;
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // Task: blocked_write - assert write controls while we=0; model must not move
    // -------------------------------------------------------------------------
    task blocked_write;
        input [ADDR_WIDTH-1:0] addr;
        input [DATA_WIDTH-1:0] data;
        begin
            @(negedge clk);
            waddr = addr;
            wdata = data;
            we    = 1'b0;
            @(posedge clk); #1;
        end
    endtask

    // -------------------------------------------------------------------------
    // Stimulus
    // -------------------------------------------------------------------------
    initial begin
        pass_count = 0;
        fail_count = 0;

        rst_n  = 1'b1;
        we     = 1'b0;
        waddr  = {ADDR_WIDTH{1'b0}};
        wdata  = {DATA_WIDTH{1'b0}};
        raddr1 = {ADDR_WIDTH{1'b0}};
        raddr2 = {ADDR_WIDTH{1'b0}};
        model_reset();

        $display("=== register_file Testbench (directed self-check) ===");

        // ---- TC1: Reset behavior ----
        $display("\n--- TC1: Registers read as zero after reset ---");
        apply_reset();

        // ---- TC2: Write/read all writable registers ----
        $display("\n--- TC2: Write/read all writable registers ---");
        for (i = 1; i < NUM_REGS; i = i + 1) begin
            write_reg(i[ADDR_WIDTH-1:0], (8'h20 + i[DATA_WIDTH-1:0]));
            check_read_ports(i[ADDR_WIDTH-1:0], {ADDR_WIDTH{1'b0}},
                             "Written register matches model and x0 remains zero");
        end

        // ---- TC3: Dual-read from independent addresses ----
        $display("\n--- TC3: Dual-read from independent addresses ---");
        check_read_ports(3'd2, 3'd5, "Dual read ports return independent registers");
        check_read_ports(3'd6, 3'd1, "Dual read ports support arbitrary address order");

        // ---- TC4: Overwrite existing register ----
        $display("\n--- TC4: Overwrite existing register ---");
        write_reg(3'd3, 8'hA5);
        check_read_ports(3'd3, 3'd4, "Overwrite updates selected register only");

        // ---- TC5: Write-disabled cycle must not update storage ----
        $display("\n--- TC5: Write-disabled cycle must not update storage ---");
        blocked_write(3'd4, 8'hF0);
        check_read_ports(3'd4, 3'd3, "Write-disabled cycle is ignored");

        // ---- TC6: Hardwired zero register ignores writes ----
        $display("\n--- TC6: Hardwired zero register ignores writes ---");
        write_reg({ADDR_WIDTH{1'b0}}, 8'hFF);
        check_read_ports({ADDR_WIDTH{1'b0}}, 3'd3, "Zero register ignores writes");

        // ---- TC7: Back-to-back writes ----
        $display("\n--- TC7: Back-to-back writes ---");
        write_reg(3'd6, 8'h66);
        write_reg(3'd7, 8'h77);
        check_read_ports(3'd6, 3'd7, "Back-to-back writes commit in order");

        // ---- TC8: Reset after activity clears state ----
        $display("\n--- TC8: Reset after activity clears state ---");
        apply_reset();

        // ---- Final verdict ----
        $display("-----------------------------------------------");
        if (fail_count == 0)
            $display("=== PASS: all %0d checks passed ===", pass_count);
        else
            $display("=== FAIL: %0d passed, %0d failed ===", pass_count, fail_count);

        $finish;
    end

endmodule
