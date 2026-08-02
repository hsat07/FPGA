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
