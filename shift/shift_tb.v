`timescale 1ns/1ps

module shift_tb;
    reg  [7:0] A;
    reg  [3:0] shiftVal;
    reg  [1:0] shiftOPC;
    reg        flagC;
    wire [7:0] A_mod;
    wire       flagCNew;

    shift uut (
        .A(A),
        .shiftVal(shiftVal),
        .shiftOPC(shiftOPC),
        .flagC(flagC),
        .A_mod(A_mod),
        .flagCNew(flagCNew)
    );

    initial begin
        $dumpfile("dump_shift.vcd");
        $dumpvars(0, shift_tb);

        $display("      A     SHIFTVAL OPC |    A_mod   flagCNew");
        $display("--------------------------------------------------");

        // LSL tests (OPC = 00)
        A = 8'b0000_1011; shiftVal = 4'b0000; shiftOPC = 2'b00; flagC = 1'b0; #10;
        $display("%b  %b     %b  |  %b     %b", A, shiftVal, shiftOPC, A_mod, flagCNew);

        A = 8'b0000_1011; shiftVal = 4'b0010; shiftOPC = 2'b00; flagC = 1'b0; #10;
        $display("%b  %b     %b  |  %b     %b", A, shiftVal, shiftOPC, A_mod, flagCNew);

        A = 8'b1111_1111; shiftVal = 4'b1000; shiftOPC = 2'b00; flagC = 1'b0; #10;
        $display("%b  %b     %b  |  %b     %b", A, shiftVal, shiftOPC, A_mod, flagCNew);

        // LSR tests (OPC = 01)
        A = 8'b1000_0000; shiftVal = 4'b0001; shiftOPC = 2'b01; flagC = 1'b0; #10;
        $display("%b  %b     %b  |  %b     %b", A, shiftVal, shiftOPC, A_mod, flagCNew);

        A = 8'b1111_1111; shiftVal = 4'b0100; shiftOPC = 2'b01; flagC = 1'b0; #10;
        $display("%b  %b     %b  |  %b     %b", A, shiftVal, shiftOPC, A_mod, flagCNew);

        // ASR tests (OPC = 10)
        A = 8'b1000_0000; shiftVal = 4'b0001; shiftOPC = 2'b10; flagC = 1'b0; #10;
        $display("%b  %b     %b  |  %b     %b", A, shiftVal, shiftOPC, A_mod, flagCNew);

        A = 8'b0111_1111; shiftVal = 4'b0011; shiftOPC = 2'b10; flagC = 1'b0; #10;
        $display("%b  %b     %b  |  %b     %b", A, shiftVal, shiftOPC, A_mod, flagCNew);

        // Unused/default case (OPC = 11)
        A = 8'b1010_1010; shiftVal = 4'b0011; shiftOPC = 2'b11; flagC = 1'b0; #10;
        $display("%b  %b     %b  |  %b     %b", A, shiftVal, shiftOPC, A_mod, flagCNew);

        $finish;
    end

endmodule
