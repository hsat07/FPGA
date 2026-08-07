module fullAdder2(input A, input B, input Cin, output S, output Cout);
    assign S = A^B^Cin;
    assign Cout = (A&B) | (Cin&(A^B));
endmodule

module invert(input [7:0] B, input sub,output [7:0]B_mod);    
    // XOR each B bit with 'sub': passes B through unchanged if sub=0,
    // inverts every bit if sub=1 (first half of two's complement)
    genvar i;
    generate
        for (i = 0; i < 8; i = i+1) begin: invert_stage
            assign B_mod[i] = B[i] ^ sub;
        end
    endgenerate
endmodule

module rippleAdder(input [7:0] A, input [7:0] B, input Cin, output [7:0] S, output Cout);
    wire[8:0] carry;
    assign carry[0] = Cin;

    genvar i;
    generate
        for(i=0; i<8; i = i+1) begin:stage
            fullAdder2 newAdder(.A(A[i]), .B(B[i]), .Cin(carry[i]), .S(S[i]), .Cout(carry[i+1]));
        end
    endgenerate

    assign Cout = carry[8];

endmodule


module addSub(input [7:0] A, input [7:0] B, input Cin, input sub, output [7:0] S, output Cout);
    wire cinFinal;
    wire [7:0] B_mod;

    invert mySub(.B(B), .sub(sub), .B_mod(B_mod));
    // second half of two's complement: add 1 via carry-in when subtracting
    assign cinFinal = Cin | sub;

    rippleAdder core(.A(A), .B(B_mod), .Cin(cinFinal), .S(S), .Cout(Cout));

endmodule 

//ShiftOPC == LSL, LSR, ASR, XSR
//LSL = <<
//LSR = >>
//ASR = >>>
//XSR = hardcode

module LSL(input signed [7:0] A, input [3:0] shiftVal, output [7:0] A_mod, output flagC);
    assign A_mod = A << shiftVal;
    assign flagC = (shiftVal == 0) ? 1'b0 : A[8 - shiftVal];
endmodule

module LSR(input signed [7:0] A, input [3:0] shiftVal, output [7:0] A_mod, output flagC);
    assign A_mod = A >> shiftVal;
    assign flagC = (shiftVal == 0) ? 1'b0 : A[shiftVal - 1];
endmodule

module ASR(input signed[7:0] A, input [3:0] shiftVal, output [7:0] A_mod, output flagC);
    assign A_mod = A >>> shiftVal;
    assign flagC = (shiftVal == 0) ? 1'b0 : A[shiftVal - 1];
endmodule

module mux4to1Bus(input [7:0] B, input [7:0] C, input [7:0] D, input [1:0] select, output reg [7:0] outputData);
    always @(select, B, C,D) begin
        case(select)
            2'b00: outputData = B;
            2'b01: outputData = C;
            2'b10: outputData = D;
            2'b11: outputData = 8'b0000_0000;
        endcase
    end
endmodule

module mux4to1Wire(input flagC1, input flagC2, input flagC3, input [1:0] select, output reg flagCNew);
    always @(select, flagC1, flagC2, flagC3) begin
        case(select)
            2'b00: flagCNew = flagC1;
            2'b01: flagCNew = flagC2;
            2'b10: flagCNew = flagC3;
            2'b11: flagCNew = 1'b0;
        endcase
    end
endmodule


module shift(input [7:0] A, input [3:0] shiftVal, input [1:0] shiftOPC, input flagC, output [7:0] A_mod, output flagCNew);
    wire [7:0] B,C,D;
    wire flagC1, flagC2, flagC3;
    LSL myLSL(.A(A), .shiftVal(shiftVal), .A_mod(B), .flagC(flagC1));
    LSR myLSR(.A(A), .shiftVal(shiftVal), .A_mod(C), .flagC(flagC2));
    ASR myASR(.A(A), .shiftVal(shiftVal), .A_mod(D), .flagC(flagC3));

    mux4to1Bus setOutput(.B(B), .C(C), .D(D), .select(shiftOPC), .outputData(A_mod));
    mux4to1Wire setFlag(.flagC1(flagC1), .flagC2(flagC2), .flagC3(flagC3),.select(shiftOPC), .flagCNew(flagCNew));
endmodule  

module andGate(input [7:0] A, input [7:0] B, output [7:0] C);
    genvar i;
    generate 
        for(i=0; i<8; i=i+1) begin: andStage
            assign C[i] = A[i] & B[i];
        end
    endgenerate
endmodule

module orGate(input [7:0] A, input [7:0] B, output [7:0] C);
    genvar i;
    generate 
        for(i=0; i<8; i=i+1) begin: orStage
            assign C[i] = A[i] | B[i];
        end
    endgenerate
endmodule

module xorGate(input [7:0] A, input [7:0] B, output [7:0] C);
    genvar i;
    generate 
        for(i=0; i<8; i=i+1) begin: xorStage
            assign C[i] = A[i] ^ B[i];
        end
    endgenerate

endmodule





module alu(input clk, input reset, input start, input [2:0] ALUOPC,input [7:0] A, input [7:0] B, input [3:0] shiftVal, input [1:0] shiftOPC, input [3:0] flagsIn, output [7:0] result, output [3:0] flagsOut, output busy, output done);

endmodule