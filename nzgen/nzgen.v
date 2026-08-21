module nzgen(input [15:0] data, output flagN, flagZ);
    assign flagN = data[15];
    assign flagZ = (data == 16'b0);
endmodule