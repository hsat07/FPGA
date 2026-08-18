`timescale 1ns/1ps

module registerFile_tb;

    reg clk;
    reg [15:0] dataIn;
    reg [2:0] raddrA, raddrB, raddrW;
    reg writeEn;
    wire [15:0] dataOutA, dataOutB;

    integer errors;

    registerFile uut (
        .clk(clk),
        .dataIn(dataIn),
        .raddrA(raddrA),
        .raddrB(raddrB),
        .raddrW(raddrW),
        .writeEn(writeEn),
        .dataOutA(dataOutA),
        .dataOutB(dataOutB)
    );

    // 10ns period clock
    initial clk = 0;
    always #5 clk = ~clk;

    // Write reg[addr] = val on the next rising edge, then de-assert writeEn.
    task doWrite(input [2:0] addr, input [15:0] val);
        begin
            @(negedge clk);
            raddrW  = addr;
            dataIn  = val;
            writeEn = 1;
            @(posedge clk); // write commits here
            @(negedge clk);
            writeEn = 0;
        end
    endtask

    // Present read addresses, wait one clock edge for the registered
    // outputs to latch, then check them.
    task doReadCheck(input [2:0] addrA, input [2:0] addrB,
                      input [15:0] expA, input [15:0] expB,
                      input [127:0] label);
        begin
            @(negedge clk);
            raddrA = addrA;
            raddrB = addrB;
            @(posedge clk); // dataOutA/B latch here, using pre-edge reg contents
            #1; // let the nonblocking assigns settle
            if (dataOutA !== expA) begin
                $display("FAIL [%0s] dataOutA: expected %h, got %h", label, expA, dataOutA);
                errors = errors + 1;
            end else begin
                $display("PASS [%0s] dataOutA = %h", label, dataOutA);
            end
            if (dataOutB !== expB) begin
                $display("FAIL [%0s] dataOutB: expected %h, got %h", label, expB, dataOutB);
                errors = errors + 1;
            end else begin
                $display("PASS [%0s] dataOutB = %h", label, dataOutB);
            end
        end
    endtask

    initial begin
        errors  = 0;
        dataIn  = 0;
        raddrA  = 0;
        raddrB  = 0;
        raddrW  = 0;
        writeEn = 0;

        // NOTE: no reset in this module. Vivado is expected to init the
        // underlying flops/LUTRAM to 0 on the real FPGA; iverilog does NOT
        // do this automatically, so registers start as X in simulation.
        // We therefore write every register we intend to read before
        // reading it, so we never observe the X startup state here.

        // Write a distinct value into every register
        doWrite(0, 16'h0000);
        doWrite(1, 16'h1111);
        doWrite(2, 16'h2222);
        doWrite(3, 16'h3333);
        doWrite(4, 16'h4444);
        doWrite(5, 16'h5555);
        doWrite(6, 16'h6666);
        doWrite(7, 16'h7777);

        // Basic read-back, two different registers on the two ports
        doReadCheck(1, 2, 16'h1111, 16'h2222, "readback R1/R2");

        // Read the same register on both ports simultaneously
        doReadCheck(5, 5, 16'h5555, 16'h5555, "readback R5/R5 same addr");

        // Overwrite R3, confirm new value is seen (old value must be gone)
        doWrite(3, 16'hBEEF);
        doReadCheck(3, 0, 16'hBEEF, 16'h0000, "readback after overwrite R3");

        // Write-then-immediately-read-same-address-same-cycle behavior:
        // with this design (non-blocking write + non-blocking read of pre-
        // edge value, no forwarding), addressing the just-written register
        // in the SAME cycle as the write should still show the OLD value,
        // since dataOut latches using registers[] as it was just before
        // this edge (i.e. before the write commits).
        @(negedge clk);
        raddrW  = 3;
        dataIn  = 16'hCAFE;
        writeEn = 1;
        raddrA  = 3;      // address the register being written, same cycle
        raddrB  = 0;
        @(posedge clk);   // write commits AND dataOut latches old value here
        #1;
        if (dataOutA !== 16'hBEEF) begin
            $display("FAIL [same-cycle write/read] expected OLD value BEEF (no write-through), got %h", dataOutA);
            errors = errors + 1;
        end else begin
            $display("PASS [same-cycle write/read] dataOutA = %h (old value, no write-through, as expected)", dataOutA);
        end
        @(negedge clk);
        writeEn = 0;

        // Now confirm the write from above DID land, one cycle later
        doReadCheck(3, 0, 16'hCAFE, 16'h0000, "readback confirms delayed write landed");

        // writeEn=0 must not disturb storage
        doWrite(4, 16'hAAAA);
        @(negedge clk);
        raddrW  = 4;
        dataIn  = 16'hFFFF;
        writeEn = 0; // write disabled
        raddrA  = 4;
        raddrB  = 4;
        @(posedge clk);
        #1;
        if (dataOutA !== 16'hAAAA) begin
            $display("FAIL [writeEn=0] register was modified despite writeEn=0, got %h", dataOutA);
            errors = errors + 1;
        end else begin
            $display("PASS [writeEn=0] register unchanged = %h", dataOutA);
        end

        if (errors == 0)
            $display("\nALL TESTS PASSED");
        else
            $display("\n%0d TEST(S) FAILED", errors);

        $finish;
    end

endmodule