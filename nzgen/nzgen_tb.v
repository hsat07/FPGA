`timescale 1ns/1ps

module nzgen_tb;

    reg  [15:0] data;
    wire        flagN, flagZ;

    integer errors;

    nzgen uut (
        .data(data),
        .flagN(flagN),
        .flagZ(flagZ)
    );

    task check(input [15:0] val, input expN, input expZ, input [127:0] label);
        begin
            data = val;
            #1; // let the combinational assigns settle
            if (flagN !== expN) begin
                $display("FAIL [%0s] flagN: expected %b, got %b", label, expN, flagN);
                errors = errors + 1;
            end else if (flagZ !== expZ) begin
                $display("FAIL [%0s] flagZ: expected %b, got %b", label, expZ, flagZ);
                errors = errors + 1;
            end else begin
                $display("PASS [%0s] data=%h -> flagN=%b flagZ=%b", label, val, flagN, flagZ);
            end
        end
    endtask

    initial begin
        errors = 0;

        check(16'h0000, 1'b0, 1'b1, "zero");
        check(16'h0001, 1'b0, 1'b0, "small positive, nonzero");
        check(16'h7FFF, 1'b0, 1'b0, "largest positive (MSB=0)");
        check(16'h8000, 1'b1, 1'b0, "smallest negative (MSB=1, only that bit set)");
        check(16'hFFFF, 1'b1, 1'b0, "all ones (negative, nonzero)");
        check(16'h8001, 1'b1, 1'b0, "negative, nonzero, low bit set");
        check(16'h0080, 1'b0, 1'b0, "mid-range positive, nonzero");

        // change data twice in a row without waiting extra time, to confirm
        // this really is combinational (no stale/registered leftover value)
        data = 16'hFFFF; #1;
        data = 16'h0000; #1;
        if (flagN !== 1'b0 || flagZ !== 1'b1) begin
            $display("FAIL [back-to-back change] expected flagN=0 flagZ=1, got flagN=%b flagZ=%b", flagN, flagZ);
            errors = errors + 1;
        end else begin
            $display("PASS [back-to-back change] flags updated immediately, no stale value");
        end

        if (errors == 0)
            $display("\nALL NZGEN TESTS PASSED");
        else
            $display("\n%0d NZGEN TEST(S) FAILED", errors);

        $finish;
    end

endmodule