module invert(input [15:0] B, input sub,output [15:0]B_mod);    
    // XOR each B bit with 'sub': passes B through unchanged if sub=0,
    // inverts every bit if sub=1 (first half of two's complement)
    assign B_mod = B ^ {16{sub}};
endmodule

module fullAdder2(input A, input B, input Cin, output S, output Cout);
    assign S = A^B^Cin;
    assign Cout = (A&B) | (Cin&(A^B));
endmodule

module rippleAdder(input [15:0] A, input [15:0] B, input Cin, output [15:0] S, output Cout);
    wire[16:0] carry;
    assign carry[0] = Cin;
    genvar i;
    generate
        for(i=0; i<16; i = i+1) begin:stage
            fullAdder2 newAdder(.A(A[i]), .B(B[i]), .Cin(carry[i]), .S(S[i]), .Cout(carry[i+1]));
        end
    endgenerate
    assign Cout = carry[16];
endmodule

module addSub(input [15:0] A, input [15:0] B, input Cin, input sub, output [15:0] S, output Cout, output V);
    wire [15:0] B_mod;

    invert mySub(.B(B), .sub(sub), .B_mod(B_mod));
    rippleAdder core(.A(A), .B(B_mod), .Cin(Cin), .S(S), .Cout(Cout));

    assign V = (~(A[15]^B_mod[15])) & (A[15]^S[15]);
endmodule

module andGate(input [15:0] A, input [15:0] B, output [15:0] C);
    assign C = A&B;
endmodule

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

module mux8to1(input [2:0]sel, input a,b,c,d,e,f,g,h, output reg out);
    always @(*) begin
        case (sel)
        3'b000: out = a;
        3'b001: out = b;
        3'b010: out = c;
        3'b011: out = d;
        3'b100: out = e;
        3'b101: out = f;
        3'b110: out = g;
        3'b111: out = h;
        endcase
    end
endmodule

module aludecode(input [2:0] ALUOPC, input flagCin, output addSubCin, output invert);
    mux8to1 addSubCMux(.sel(ALUOPC), .a(0),.b(0),.c(1),.d(flagCin),.e(flagCin),.f(0),.g(1),.h(0), .out(addSubCin));
    mux8to1 invertMux(.sel(ALUOPC), .a(0),.b(0),.c(1),.d(0),.e(1),.f(0),.g(1),.h(0), .out(invert));
endmodule

module alu(
    input         clk,
    input         reset,
    input         start,
    input  [2:0]  ALUOPC,
    input  [15:0] RA,
    input  [15:0] RB,
    input  [15:0] IMM,
    input         OP2SEL,
    input  [3:0]  SCNT,
    input  [1:0]  SHIFTOPC,
    input  [3:0]  flagsIn,
    output [15:0] result,
    output [3:0]  flagsOut,
    output        busy,
    output        done
);

    // ---- MUX1: register vs immediate for second operand ----
    wire [15:0] Bsel;
    assign Bsel = OP2SEL ? IMM : RB;

    // ---- Decode ----
    wire invertSel, addSubCinSel;
    aludecode decoder(.ALUOPC(ALUOPC), .flagCin(flagsIn[1]), .invert(invertSel), .addSubCin(addSubCinSel));

    // ---- Parallel functional units ----
    wire [15:0] addSubOut;
    wire addSubCout, addSubV;
    addSub myAddSub(.A(RA), .B(Bsel), .Cin(addSubCinSel), .sub(invertSel), .S(addSubOut), .Cout(addSubCout), .V(addSubV));

    wire [15:0] andOut;
    andGate myAnd(.A(RA), .B(Bsel), .C(andOut));

    wire [15:0] shiftOut;
    wire shiftSFTOUT;
    shift myShift(.IN(RA), .SCNT(SCNT), .SHIFTOPC(SHIFTOPC), .SFTIN(flagsIn[1]), .OUT(shiftOut), .SFTOUT(shiftSFTOUT));

    // ---- MUX2: 8-way result select on ALUOPC ----
    reg [15:0] result_comb;
    always @(*) begin
        case (ALUOPC)
            3'b000: result_comb = Bsel;      // MOV
            3'b001: result_comb = addSubOut; // ADD
            3'b010: result_comb = addSubOut; // SUB
            3'b011: result_comb = addSubOut; // ADC
            3'b100: result_comb = addSubOut; // SBC
            3'b101: result_comb = andOut;    // AND
            3'b110: result_comb = addSubOut; // CMP
            3'b111: result_comb = shiftOut;  // Shift
        endcase
    end

    // ---- MUX3: FlagC select (shift path vs addSub path) ----
    wire eq7;
    assign eq7 = (ALUOPC == 3'b111);

    wire flagC_comb;
    assign flagC_comb = eq7 ? shiftSFTOUT : addSubCout;

    wire flagV_comb;
    assign flagV_comb = addSubV;

    // ---- Z/N, generic from result_comb ----
    wire flagZ_comb, flagN_comb;
    assign flagZ_comb = (result_comb == 16'b0);
    assign flagN_comb = result_comb[15];

    // ---- Flag packing: {N, Z, C, V} ----
    wire [3:0] flags_comb;
    assign flags_comb = {flagN_comb, flagZ_comb, flagC_comb, flagV_comb};

    // ---- Sequential shell ----
    reg [15:0] result_reg;
    reg [3:0]  flags_reg;
    reg        done_reg;

    always @(posedge clk) begin
        if (reset) begin
            result_reg <= 16'b0;
            flags_reg  <= 4'b0;
            done_reg   <= 1'b0;
        end else begin
            done_reg <= start;
            if (start) begin
                flags_reg <= flags_comb;
                if (ALUOPC != 3'b110)   // CMP: skip result write, flags still update
                    result_reg <= result_comb;
            end
        end
    end

    assign result   = result_reg;
    assign flagsOut = flags_reg;
    assign busy     = 1'b0;
    assign done     = done_reg;

endmodule