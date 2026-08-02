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

module invertGate(input [7:0] B, input sub, output [7:0]B_mod);    
    // XOR each B bit with 'sub': passes B through unchanged if sub=0,
    // inverts every bit if sub=1 (first half of two's complement)
    genvar i;
    generate
        for (i = 0; i < 8; i = i+1) begin: invert_stage
            assign B_mod[i] = B[i] ^ sub;
        end
    endgenerate
endmodule

