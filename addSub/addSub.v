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