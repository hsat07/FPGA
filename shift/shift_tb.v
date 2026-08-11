`timescale 1ns/1ps

module shift_tb;
    reg  [15:0] IN;
    reg  [3:0]  SCNT;
    reg  [1:0]  SHIFTOPC;
    reg         SFTIN;
    wire [15:0] OUT;
    wire        SFTOUT;

    shift uut (
        .IN(IN),
        .SCNT(SCNT),
        .SHIFTOPC(SHIFTOPC),
        .SFTIN(SFTIN),
        .OUT(OUT),
        .SFTOUT(SFTOUT)
    );

    initial begin
        $dumpfile("dump_shift.vcd");
        $dumpvars(0, shift_tb);

        $display("         IN          SCNT OPC SFTIN |        OUT       SFTOUT");
        $display("--------------------------------------------------------------------");

        IN = 16'b0000_0000_0000_1011; SCNT = 4'b0000; SHIFTOPC = 2'b00; SFTIN = 1'b0; #10;
        $display("%b  %b  %b   %b  |  %b  %b", IN, SCNT, SHIFTOPC, SFTIN, OUT, SFTOUT);

        IN = 16'b0000_0000_0000_1011; SCNT = 4'b0010; SHIFTOPC = 2'b00; SFTIN = 1'b0; #10;
        $display("%b  %b  %b   %b  |  %b  %b", IN, SCNT, SHIFTOPC, SFTIN, OUT, SFTOUT);

        IN = 16'b1111_1111_1111_1111; SCNT = 4'b1000; SHIFTOPC = 2'b00; SFTIN = 1'b0; #10;
        $display("%b  %b  %b   %b  |  %b  %b", IN, SCNT, SHIFTOPC, SFTIN, OUT, SFTOUT);

        IN = 16'b1000_0000_0000_0000; SCNT = 4'b0001; SHIFTOPC = 2'b01; SFTIN = 1'b0; #10;
        $display("%b  %b  %b   %b  |  %b  %b", IN, SCNT, SHIFTOPC, SFTIN, OUT, SFTOUT);

        IN = 16'b1111_1111_1111_1111; SCNT = 4'b0100; SHIFTOPC = 2'b01; SFTIN = 1'b0; #10;
        $display("%b  %b  %b   %b  |  %b  %b", IN, SCNT, SHIFTOPC, SFTIN, OUT, SFTOUT);

        IN = 16'b1000_0000_0000_0000; SCNT = 4'b0001; SHIFTOPC = 2'b10; SFTIN = 1'b0; #10;
        $display("%b  %b  %b   %b  |  %b  %b", IN, SCNT, SHIFTOPC, SFTIN, OUT, SFTOUT);

        IN = 16'b0111_1111_1111_1111; SCNT = 4'b0011; SHIFTOPC = 2'b10; SFTIN = 1'b0; #10;
        $display("%b  %b  %b   %b  |  %b  %b", IN, SCNT, SHIFTOPC, SFTIN, OUT, SFTOUT);

        IN = 16'b1010_1010_1010_1010; SCNT = 4'b0011; SHIFTOPC = 2'b11; SFTIN = 1'b1; #10;
        $display("%b  %b  %b   %b  |  %b  %b", IN, SCNT, SHIFTOPC, SFTIN, OUT, SFTOUT);

        IN = 16'b1010_1010_1010_1010; SCNT = 4'b0000; SHIFTOPC = 2'b11; SFTIN = 1'b1; #10;
        $display("%b  %b  %b   %b  |  %b  %b", IN, SCNT, SHIFTOPC, SFTIN, OUT, SFTOUT);

        $finish;
    end

endmodule
