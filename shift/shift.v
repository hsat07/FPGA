module shiftStage #(parameter N = 1) (
    input  [15:0] IN,
    input         SFTOUT1,   // carry chain in
    input         SFTIN,     // incoming ALU flagC, broadcast
    input  [1:0]  SHIFTOPC,
    input         EN,
    output [15:0] OUT,
    output        SFTOUT2
);
    wire fillBit = (SHIFTOPC == 2'b10) ? IN[15] :   // ASR: sign bit
                   (SHIFTOPC == 2'b11) ? SFTIN  :   // XSR: incoming flagC
                   1'b0;                             // LSL/LSR: zero

    wire [15:0] leftShifted  = {IN[15-N:0], {N{1'b0}}};
    wire [15:0] rightShifted = {{N{fillBit}}, IN[15:N]};

    wire [15:0] shiftedVal = (SHIFTOPC == 2'b00) ? leftShifted : rightShifted;
    wire fallenBit         = (SHIFTOPC == 2'b00) ? IN[16-N] : IN[N-1];

    assign OUT     = EN ? shiftedVal : IN;
    assign SFTOUT2 = EN ? fallenBit  : SFTOUT1;
endmodule

module shift(
    input  [15:0] IN,
    input  [3:0]  SCNT,
    input  [1:0]  SHIFTOPC,
    input         SFTIN,
    output [15:0] OUT,
    output        SFTOUT
);
    wire [15:0] out1, out2, out4;
    wire        sf1, sf2, sf4;
    wire [3:0]  effSCNT;

    // XSR always shifts by exactly 1, regardless of what SCNT says
    assign effSCNT = (SHIFTOPC == 2'b11) ? 4'b0001 : SCNT;

    shiftStage #(1) SHIFT1(.IN(IN),   .SFTOUT1(1'b0), .SFTIN(SFTIN), .SHIFTOPC(SHIFTOPC), .EN(effSCNT[0]), .OUT(out1), .SFTOUT2(sf1));
    shiftStage #(2) SHIFT2(.IN(out1), .SFTOUT1(sf1),  .SFTIN(SFTIN), .SHIFTOPC(SHIFTOPC), .EN(effSCNT[1]), .OUT(out2), .SFTOUT2(sf2));
    shiftStage #(4) SHIFT4(.IN(out2), .SFTOUT1(sf2),  .SFTIN(SFTIN), .SHIFTOPC(SHIFTOPC), .EN(effSCNT[2]), .OUT(out4), .SFTOUT2(sf4));
    shiftStage #(8) SHIFT8(.IN(out4), .SFTOUT1(sf4),  .SFTIN(SFTIN), .SHIFTOPC(SHIFTOPC), .EN(effSCNT[3]), .OUT(OUT),  .SFTOUT2(SFTOUT));
endmodule