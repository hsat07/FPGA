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
    mux8to1 addSubCMux(.sel(ALUOPC), .a(0),.b(0),.c(0),.d(flagCin),.e(flagCin),.f(0),.g(1),.h(0), .out(addSubCin));
    mux8to1 invertMux(.sel(ALUOPC), .a(0),.b(0),.c(1),.d(0),.e(1),.f(0),.g(1),.h(0), .out(invert));
endmodule