module register(input clk, input [15:0] dataIn, input enable, output reg[15:0] dataOut = 16'b0);
    always @(posedge clk) begin
        if(enable)
            dataOut <= dataIn;
    end
endmodule

module registerFile(input clk, input [15:0] dataIn, input [2:0] raddrA,input [2:0] raddrB,input [2:0] raddrW, input writeEn, output reg [15:0] dataOutA,output reg[15:0] dataOutB);
    reg [15:0] registers [0:7];

    always @(posedge clk) begin        
        if(writeEn)
           registers[raddrW] <= dataIn;
        {dataOutA, dataOutB} <= {registers[raddrA], registers[raddrB]};
    end
endmodule   