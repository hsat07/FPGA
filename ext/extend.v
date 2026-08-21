module extBlock(input clk, input [15:0] imm8, input ext, output [15:0] imm16);
    reg [7:0] MSBstore;
    reg dff;

    wire [7:0] newMSB = dff ? MSBstore : imm8[15:8];

    always @(posedge clk) begin
        MSBstore <= imm8 [7:0];   
        dff <= ext;
    end

    assign imm16 = {newMSB, imm8[7:0]};
endmodule