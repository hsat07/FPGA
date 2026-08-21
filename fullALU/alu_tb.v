`timescale 1ns/1ps

module alu_tb;

    reg         clk;
    reg         reset;
    reg         start;
    reg  [2:0]  ALUOPC;
    reg  [15:0] RA, RB, IMM;
    reg         OP2SEL;
    reg  [3:0]  SCNT;
    reg  [1:0]  SHIFTOPC;
    reg  [3:0]  flagsIn;
    wire [15:0] result;
    wire        flagC, flagV;
    wire        busy, done;

    integer errors;

    alu uut (
        .clk(clk), .reset(reset), .start(start),
        .ALUOPC(ALUOPC), .RA(RA), .RB(RB), .IMM(IMM), .OP2SEL(OP2SEL),
        .SCNT(SCNT), .SHIFTOPC(SHIFTOPC), .flagsIn(flagsIn),
        .result(result), .flagC(flagC), .flagV(flagV),
        .busy(busy), .done(done)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // Pulse start for one op, wait for it to land, then check.
    // busy is checked every op too, since it should always read 0 here
    // (single-cycle ops only -- MUL/DIV will be the first thing to ever
    // drive this high once built).
    //
    // checkResult/checkC/checkV let a call opt OUT of asserting a specific
    // value where the ALU's own diagram shows that output isn't gated for
    // this opcode:
    //   - CMP: result write is suppressed -> checkResult=0
    //   - MOV/AND: MUX3 always taps addSub's raw carryout for non-shift
    //     ops, so flagC for these is just leftover addSub arithmetic,
    //     not architecturally meaningful -> checkC=0
    //   - MOV/AND/Shift: FLAGV is wired straight off addSub's FLAGV with
    //     no mux at all, for every opcode including Shift -- so it's only
    //     meaningful for the real arithmetic ops (ADD/SUB/ADC/SBC/CMP)
    //     -> checkV=0 for MOV/AND/Shift
    task runOp(
        input [2:0]  opc,
        input [15:0] a, input [15:0] b, input [15:0] imm, input useImm,
        input [1:0]  shiftopc, input [3:0] scnt,
        input [3:0]  fin,
        input [15:0] expResult, input expC, input expV,
        input        checkResult, input checkC, input checkV,
        input [127:0] label
    );
        begin
            @(negedge clk);
            ALUOPC   = opc;
            RA       = a;
            RB       = b;
            IMM      = imm;
            OP2SEL   = useImm;
            SHIFTOPC = shiftopc;
            SCNT     = scnt;
            flagsIn  = fin;
            start    = 1;
            @(posedge clk); // result/flagC/flagV/done register here
            @(negedge clk);
            start = 0;
            #1;

            if (busy !== 1'b0) begin
                $display("FAIL [%0s] busy: expected 0, got %b", label, busy);
                errors = errors + 1;
            end
            if (done !== 1'b1) begin
                $display("FAIL [%0s] done: expected 1, got %b", label, done);
                errors = errors + 1;
            end
            if (checkResult && result !== expResult) begin
                $display("FAIL [%0s] result: expected %h, got %h", label, expResult, result);
                errors = errors + 1;
            end
            if (checkC && flagC !== expC) begin
                $display("FAIL [%0s] flagC: expected %b, got %b", label, expC, flagC);
                errors = errors + 1;
            end
            if (checkV && flagV !== expV) begin
                $display("FAIL [%0s] flagV: expected %b, got %b", label, expV, flagV);
                errors = errors + 1;
            end
            if ((!checkResult || result === expResult) &&
                (!checkC      || flagC  === expC)      &&
                (!checkV      || flagV  === expV)      &&
                done === 1'b1 && busy === 1'b0) begin
                $display("PASS [%0s] result=%h flagC=%b flagV=%b (checked: result=%0d C=%0d V=%0d)",
                          label, result, flagC, flagV, checkResult, checkC, checkV);
            end
        end
    endtask

    initial begin
        errors  = 0;
        reset   = 1;
        start   = 0;
        ALUOPC  = 0; RA = 0; RB = 0; IMM = 0; OP2SEL = 0;
        SCNT    = 0; SHIFTOPC = 0; flagsIn = 0;

        @(negedge clk);
        @(negedge clk);
        reset = 0;

        // ---- MOV (register form): result = RB ---- (C, V not architecturally meaningful)
        runOp(3'b000, 16'd0, 16'd42, 16'd0, 0, 2'b00, 4'b0, 4'b0,
              16'd42, 1'b0, 1'b0, 1, 0, 0, "MOV RB=42");

        // ---- MOV (immediate form): result = IMM ----
        runOp(3'b000, 16'd0, 16'd0, 16'd99, 1, 2'b00, 4'b0, 4'b0,
              16'd99, 1'b0, 1'b0, 1, 0, 0, "MOV imm=99");

        // ---- ADD: 5 + 3 = 8, no carry, no overflow ----
        runOp(3'b001, 16'd5, 16'd3, 16'd0, 0, 2'b00, 4'b0, 4'b0,
              16'd8, 1'b0, 1'b0, 1, 1, 1, "ADD 5+3");

        // ---- ADD overflow case: 0x7FFF + 1 -> signed overflow, V=1 ----
        runOp(3'b001, 16'h7FFF, 16'h0001, 16'd0, 0, 2'b00, 4'b0, 4'b0,
              16'h8000, 1'b0, 1'b1, 1, 1, 1, "ADD signed overflow 0x7FFF+1");

        // ---- SUB: 3 - 5 -> borrow, C=0 ----
        runOp(3'b010, 16'd3, 16'd5, 16'd0, 0, 2'b00, 4'b0, 4'b0,
              -16'd2, 1'b0, 1'b0, 1, 1, 1, "SUB 3-5 (borrow)");

        // ---- SUB: 5 - 3 -> no borrow, C=1 ----
        runOp(3'b010, 16'd5, 16'd3, 16'd0, 0, 2'b00, 4'b0, 4'b0,
              16'd2, 1'b1, 1'b0, 1, 1, 1, "SUB 5-3 (no borrow)");

        // ---- ADC: RA+RB+Cin, Cin=1 -> 5+3+1=9 ----
        runOp(3'b011, 16'd5, 16'd3, 16'd0, 0, 2'b00, 4'b0, 4'b0010,
              16'd9, 1'b0, 1'b0, 1, 1, 1, "ADC 5+3+C(1)");

        // ---- SBC: RA-RB+(C-1), Cin=1 -> behaves like plain SUB: 5-3+0=2 ----
        runOp(3'b100, 16'd5, 16'd3, 16'd0, 0, 2'b00, 4'b0, 4'b0010,
              16'd2, 1'b1, 1'b0, 1, 1, 1, "SBC 5-3+(C-1), C=1");

        // ---- SBC with Cin=0 -> extra -1: 5-3-1=1 ----
        runOp(3'b100, 16'd5, 16'd3, 16'd0, 0, 2'b00, 4'b0, 4'b0000,
              16'd1, 1'b1, 1'b0, 1, 1, 1, "SBC 5-3+(C-1), C=0");

        // ---- AND: 0xF0F0 & 0x0FF0 = 0x00F0 ---- (C, V not architecturally meaningful)
        runOp(3'b101, 16'hF0F0, 16'h0FF0, 16'd0, 0, 2'b00, 4'b0, 4'b0,
              16'h00F0, 1'b0, 1'b0, 1, 0, 0, "AND 0xF0F0 & 0x0FF0");

        // ---- CMP: 5 vs 3 -> flags only, result NOT checked (should be
        // suppressed / hold previous value, not necessarily 2) ----
        runOp(3'b110, 16'd5, 16'd3, 16'd0, 0, 2'b00, 4'b0, 4'b0,
              16'd0, 1'b1, 1'b0, 0, 1, 1, "CMP 5,3 (flags only)");

        // confirm CMP really didn't clobber result: previous op's result
        // (AND -> 0x00F0) should still be sitting in result_reg
        #1;
        if (result !== 16'h00F0) begin
            $display("FAIL [CMP result-suppression] result changed to %h, expected unchanged 00F0", result);
            errors = errors + 1;
        end else begin
            $display("PASS [CMP result-suppression] result unchanged = %h", result);
        end

        // ---- LSL: RA=0x0001, shift left by 4 -> 0x0010 ---- (V not meaningful for shift)
        runOp(3'b111, 16'h0001, 16'd0, 16'd0, 0, 2'b00, 4'b0100, 4'b0,
              16'h0010, 1'b0, 1'b0, 1, 1, 0, "LSL 0x0001 << 4");

        // ---- LSR: RA=0x0080, shift right by 4 -> 0x0008 ----
        runOp(3'b111, 16'h0080, 16'd0, 16'd0, 0, 2'b01, 4'b0100, 4'b0,
              16'h0008, 1'b0, 1'b0, 1, 1, 0, "LSR 0x0080 >> 4");

        // ---- ASR: RA=0x8000 (negative), shift right by 1 -> sign-fills: 0xC000 ----
        runOp(3'b111, 16'h8000, 16'd0, 16'd0, 0, 2'b10, 4'b0001, 4'b0,
              16'hC000, 1'b0, 1'b0, 1, 1, 0, "ASR 0x8000 >> 1 (sign fill)");

        // ---- XSR: forced to shift-by-1 regardless of SCNT, fills from flagCin ----
        // RA=0x0002, SCNT deliberately wrong (0b1111) to confirm override,
        // flagsIn carry bit = 1 -> expect 0x0001 with fill bit 1 shifted into bit15
        runOp(3'b111, 16'h0002, 16'd0, 16'd0, 0, 2'b11, 4'b1111, 4'b0010,
              16'h8001, 1'b0, 1'b0, 1, 1, 0, "XSR 0x0002 >>1, fill=1, SCNT override");

        if (errors == 0)
            $display("\nALL ALU TESTS PASSED");
        else
            $display("\n%0d ALU TEST(S) FAILED", errors);

        $finish;
    end

endmodule