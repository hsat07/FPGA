`timescale 1ns/1ps

module logic_tb;
    reg  [7:0] A, B;
    wire [7:0] C_and, C_or, C_xor;

    andGate g1(.A(A), .B(B), .C(C_and));
    orGate  g2(.A(A), .B(B), .C(C_or));
    xorGate g3(.A(A), .B(B), .C(C_xor));

    initial begin
        $dumpfile("dump_logic.vcd");
        $dumpvars(0, logic_tb);

        $display("     A          B      |    AND       OR       XOR");
        $display("------------------------------------------------------------");

        A = 8'b0000_0000; B = 8'b0000_0000; #10;
        $display("%b  %b  |  %b  %b  %b", A, B, C_and, C_or, C_xor);

        A = 8'b1111_1111; B = 8'b0000_0000; #10;
        $display("%b  %b  |  %b  %b  %b", A, B, C_and, C_or, C_xor);

        A = 8'b1111_1111; B = 8'b1111_1111; #10;
        $display("%b  %b  |  %b  %b  %b", A, B, C_and, C_or, C_xor);

        A = 8'b1010_1010; B = 8'b0101_0101; #10;
        $display("%b  %b  |  %b  %b  %b", A, B, C_and, C_or, C_xor);

        A = 8'b1100_1100; B = 8'b1010_1010; #10;
        $display("%b  %b  |  %b  %b  %b", A, B, C_and, C_or, C_xor);

        $finish;
    end
endmodule
