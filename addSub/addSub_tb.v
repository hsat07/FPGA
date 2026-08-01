`timescale 1ns/1ps

module addsub_tb;
    reg  [7:0] A, B;
    reg        Cin, sub;
    wire [7:0] S;
    wire       Cout;

    addSub uut (
        .A(A),
        .B(B),
        .Cin(Cin),
        .sub(sub),
        .S(S),
        .Cout(Cout)
    );

    initial begin
        $dumpfile("dump_addsub.vcd");
        $dumpvars(0, addsub_tb);

        $display("  A     B   Cin sub |    S   Cout");
        $display("---------------------------------");

        // Addition mode (sub = 0)
        A = 8'd10;  B = 8'd20;  Cin = 0; sub = 0; #10;
        $display("%3d  %3d   %b    %b  |  %3d   %b", A, B, Cin, sub, S, Cout);

        A = 8'd200; B = 8'd100; Cin = 0; sub = 0; #10;
        $display("%3d  %3d   %b    %b  |  %3d   %b", A, B, Cin, sub, S, Cout);

        // Subtraction mode (sub = 1): S = A - B
        A = 8'd20;  B = 8'd10;  Cin = 0; sub = 1; #10;
        $display("%3d  %3d   %b    %b  |  %3d   %b", A, B, Cin, sub, S, Cout);

        A = 8'd50;  B = 8'd50;  Cin = 0; sub = 1; #10;
        $display("%3d  %3d   %b    %b  |  %3d   %b", A, B, Cin, sub, S, Cout);

        A = 8'd10;  B = 8'd20;  Cin = 0; sub = 1; #10;   // negative result (wraps)
        $display("%3d  %3d   %b    %b  |  %3d   %b", A, B, Cin, sub, S, Cout);

        $finish;
    end

endmodule
