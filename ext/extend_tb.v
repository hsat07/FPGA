`timescale 1ns/1ps

// NOTE: this testbench is written against the CORRECTED module
// (MSBstore <= imm8[7:0], not imm8[15:8] — see accompanying explanation).
// Run it against your fixed extBlock.

module extBlock_tb;

    reg clk;
    reg [15:0] imm8;
    reg ext;
    wire [15:0] imm16;

    integer errors;

    extBlock uut (
        .clk(clk),
        .imm8(imm8),
        .ext(ext),
        .imm16(imm16)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // Drive imm8/ext for one instruction "slot", advancing one clock edge
    // so dff/MSBstore update to reflect it.
    task step(input [15:0] val, input extBit);
        begin
            @(negedge clk);
            imm8 = val;
            ext  = extBit;
            @(posedge clk);
        end
    endtask

    task check(input [15:0] expected, input [127:0] label);
        begin
            #1; // let the combinational imm16 settle post-edge
            if (imm16 !== expected) begin
                $display("FAIL [%0s] expected %h, got %h", label, expected, imm16);
                errors = errors + 1;
            end else begin
                $display("PASS [%0s] imm16 = %h", label, imm16);
            end
        end
    endtask

    initial begin
        errors = 0;
        imm8   = 16'h0000;
        ext    = 0;

        // No reset in this module (dff/MSBstore start as X in sim) --
        // prime known state with one non-EXT step before trusting anything.
        step(16'h0000, 0);

        // ---- Plain passthrough, no EXT involved ----
        // dff is currently 0 (from priming step), so imm16 should equal
        // imm8 unchanged, immediately (combinational, no extra edge needed
        // beyond dff already being settled at 0).
        @(negedge clk);
        imm8 = 16'h1234;
        ext  = 0;
        #1;
        check(16'h1234, "plain passthrough positive value");

        @(negedge clk);
        imm8 = 16'hFFFE; // already sign-extended negative value
        ext  = 0;
        #1;
        check(16'hFFFE, "plain passthrough negative (sign-extended) value");

        // ---- The worked example from the slides ----
        // EXT 0x23 followed by JMP 0xF0 -> combined imm16 should be 0x23F0
        step(16'h0023, 1); // EXT instruction: imm8=0x23, positive -> sign-extends to 0x0023, ext=1
        // (imm16 during the EXT instruction's own cycle isn't architecturally meaningful; not checked)

        @(negedge clk);
        imm8 = 16'hFFF0; // JMP 0xF0: negative -> sign-extends to 0xFFF0
        ext  = 0;        // JMP itself is not an EXT instruction
        #1;
        check(16'h23F0, "EXT 0x23 + JMP 0xF0 -> combined imm16 (worked example)");

        // ---- Override must NOT persist into the instruction after that ----
        @(posedge clk); // advance past the JMP cycle so dff updates based on JMP's ext=0
        @(negedge clk);
        imm8 = 16'h0055; // some ordinary next instruction, positive -> sign-extends to 0x0055
        ext  = 0;
        #1;
        check(16'h0055, "instruction after JMP: override should NOT still apply");

        // ---- EXT with a negative literal byte (0xF0 as the donated byte itself) ----
        // EXT 0xF0 -> imm8[7:0]=0xF0 is what must be captured (the literal byte,
        // NOT its own sign-extended padding, which would incorrectly be 0xFF).
        step(16'hFFF0, 1); // EXT 0xF0: negative -> sign-extends to 0xFFF0, ext=1
        @(negedge clk);
        imm8 = 16'h0012; // next instruction: imm8=0x12, positive -> sign-extends to 0x0012
        ext  = 0;
        #1;
        check(16'hF012, "EXT 0xF0 + next 0x12 -> combined imm16 (negative donated byte)");

        if (errors == 0)
            $display("\nALL EXTBLOCK TESTS PASSED");
        else
            $display("\n%0d EXTBLOCK TEST(S) FAILED", errors);

        $finish;
    end

endmodule