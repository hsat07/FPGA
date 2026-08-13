`timescale 1ns/1ps

module alu_tb;
    reg         clk, reset, start;
    reg  [2:0]  ALUOPC;
    reg  [15:0] RA, RB, IMM;
    reg         OP2SEL;
    reg  [3:0]  SCNT;
    reg  [1:0]  SHIFTOPC;
    reg  [3:0]  flagsIn;
    wire [15:0] result;
    wire [3:0]  flagsOut;
    wire        busy, done;

    alu uut (
        .clk(clk), .reset(reset), .start(start),
        .ALUOPC(ALUOPC), .RA(RA), .RB(RB), .IMM(IMM), .OP2SEL(OP2SEL),
        .SCNT(SCNT), .SHIFTOPC(SHIFTOPC), .flagsIn(flagsIn),
        .result(result), .flagsOut(flagsOut), .busy(busy), .done(done)
    );

    // clock: 10ns period
    always #5 clk = ~clk;

    // Runs one instruction: sets inputs, pulses start for one cycle, waits for done, prints.
    task runOp;
        input [127:0] label;
        begin
            @(negedge clk);
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;
            @(negedge clk); // let done settle after the latching edge
            $display("%-6s ALUOPC=%b RA=%h RB=%h IMM=%h OP2SEL=%b SCNT=%d SHIFTOPC=%b flagsIn=%b | result=%h flagsOut=%b(NZCV) done=%b",
                       label, ALUOPC, RA, RB, IMM, OP2SEL, SCNT, SHIFTOPC, flagsIn, result, flagsOut, done);
        end
    endtask

    initial begin
        $dumpfile("dump_alu.vcd");
        $dumpvars(0, alu_tb);

        clk = 0; reset = 1; start = 0;
        ALUOPC = 0; RA = 0; RB = 0; IMM = 0; OP2SEL = 0;
        SCNT = 0; SHIFTOPC = 0; flagsIn = 4'b0000;

        @(negedge clk);
        reset = 0;

        // MOV: result = RB
        ALUOPC = 3'b000; RA = 16'h1234; RB = 16'h00FF; OP2SEL = 0; flagsIn = 4'b0000;
        runOp("MOV");

        // ADD: 100 + 50 = 150
        ALUOPC = 3'b001; RA = 16'd100; RB = 16'd50; OP2SEL = 0; flagsIn = 4'b0000;
        runOp("ADD");

        // SUB: 100 - 50 = 50
        ALUOPC = 3'b010; RA = 16'd100; RB = 16'd50; OP2SEL = 0; flagsIn = 4'b0000;
        runOp("SUB");

        // ADC: 100 + 50 + C(1) = 151
        ALUOPC = 3'b011; RA = 16'd100; RB = 16'd50; OP2SEL = 0; flagsIn = 4'b0010; // C=1 (bit1)
        runOp("ADC");

        // SBC: 100 - 50 + (C-1), C=1 -> 100-50+0 = 50
        ALUOPC = 3'b100; RA = 16'd100; RB = 16'd50; OP2SEL = 0; flagsIn = 4'b0010;
        runOp("SBC");

        // SBC with C=0 -> 100-50-1 = 49
        ALUOPC = 3'b100; RA = 16'd100; RB = 16'd50; OP2SEL = 0; flagsIn = 4'b0000;
        runOp("SBC2");

        // AND: 0xFF0F & 0x0FF0 = 0x0F00
        ALUOPC = 3'b101; RA = 16'hFF0F; RB = 16'h0FF0; OP2SEL = 0; flagsIn = 4'b0000;
        runOp("AND");

        // CMP: 50 - 50 = 0, result should NOT update (stays from previous AND result)
        ALUOPC = 3'b110; RA = 16'd50; RB = 16'd50; OP2SEL = 0; flagsIn = 4'b0000;
        runOp("CMP");

        // Shift: LSL RA by SCNT=3 -> should shift result of previous op? No: shift uses RA as IN
        ALUOPC = 3'b111; RA = 16'h0001; SCNT = 4'd3; SHIFTOPC = 2'b00; flagsIn = 4'b0000;
        runOp("LSL");

        // Shift: XSR, SCNT deliberately wrong (should still shift by 1)
        ALUOPC = 3'b111; RA = 16'hAAAA; SCNT = 4'd5; SHIFTOPC = 2'b11; flagsIn = 4'b0010; // flagC=1
        runOp("XSR");

        // MOV via immediate: OP2SEL=1
        ALUOPC = 3'b000; RB = 16'h0000; IMM = 16'hBEEF; OP2SEL = 1; flagsIn = 4'b0000;
        runOp("MOVimm");

        $finish;
    end

endmodule
