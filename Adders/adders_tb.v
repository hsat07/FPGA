`timescale 1ns/1ps

module adders_tb;
    reg[7:0] A, B;
    reg  Cin;
    wire [7:0] S;
    wire Cout;

    rippleAdder uut (
        .A(A),
        .B(B),
        .Cin(Cin),
        .S(S),
        .Cout(Cout)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, adders_tb);

        $display("   A     B   Cin |    S   Cout");
        $display("-------------------------------");

        A = 8'd10;  B = 8'd20;  Cin = 0; #10;
        $display("%3d  %3d   %b  |  %3d   %b", A, B, Cin, S, Cout);

        A = 8'd200; B = 8'd100; Cin = 0; #10;   // triggers overflow/carry
        $display("%3d  %3d   %b  |  %3d   %b", A, B, Cin, S, Cout);

        A = 8'd255; B = 8'd1;   Cin = 0; #10;   // max value rollover
        $display("%3d  %3d   %b  |  %3d   %b", A, B, Cin, S, Cout);

        A = 8'd0;   B = 8'd0;   Cin = 1; #10;   // just carry-in
        $display("%3d  %3d   %b  |  %3d   %b", A, B, Cin, S, Cout);

        A = 8'd127; B = 8'd127; Cin = 1; #10;   // carry chain stress test
        $display("%3d  %3d   %b  |  %3d   %b", A, B, Cin, S, Cout);

        $finish;
    end

endmodule