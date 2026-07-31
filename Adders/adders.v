module halfAdder(input A, input B, output S, output Cout);

    assign S = A^B;
    assign Cout = A&B;

endmodule

module fullAdder(input A, input B, input Cin, output S, output Cout);
    wire sTemp, CoutTemp1, CoutTemp2;
    halfAdder HA1(.A(A), .B(B), .S(sTemp), .Cout(CoutTemp1));
    halfAdder HA2(.A(sTemp), .B(Cin), .S(S), .Cout(CoutTemp2));

    assign Cout = CoutTemp1|CoutTemp2; 
endmodule

module fullAdder2(input A, input B, input Cin, output S, output Cout);
    assign S = A^B^Cin;
    assign Cout = (A&B) | (Cin&(A^B));
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