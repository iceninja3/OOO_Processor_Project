`timescale 1ns / 1ps

module priority_decoder_tb;

localparam WIDTH = 4;
localparam OUT_WIDTH = $clog2(WIDTH);

logic [WIDTH-1:0]     tb_in;
wire  [OUT_WIDTH-1:0] tb_out;
wire  tb_valid;


priority_decoder #(
    .WIDTH(WIDTH) // Set the parameter for this specific test
) dut (
    .in(tb_in),       // Connect DUT's 'in' port to our tb_in signal
    .out(tb_out),     // Connect DUT's 'out' port to our tb_out signal
    .valid(tb_valid)  // Connect DUT's 'valid' port to our tb_valid signal
);

initial begin
        $monitor("Time=%0t ns | in = %4b | out = %d | valid = %b",
                 $time, tb_in, tb_out, tb_valid);
end

initial begin
        $display("Priority Decoder Test Sequence...");

        // Test Case 1: Initial state, all zeros.
        // The 'valid' signal should be 0.
        tb_in = 4'b0000;
        #10; // Wait 10 ns

        // Test Case 2: Lowest priority bit active.
        tb_in = 4'b0001;
        #10;

        // Test Case 3: A middle bit active.
        tb_in = 4'b0100;
        #10;

        // Test Case 4: Test the priority logic.
        // Both bits 1 and 2 are active. The output should be 2.
        tb_in = 4'b0110;
        #10;

        // Test Case 5: Highest priority bit active.
        tb_in = 4'b1000;
        #10;

        // Test Case 6: Boundary case, all bits active.
        // The output should be 3 (the highest priority).
        tb_in = 4'b1111;
        #10;

        // Test Case 7: Return to all zeros to check that 'valid' goes low again.
        tb_in = 4'b0000;
        #20; // Wait a bit longer before finishing.

        $display("Test Sequence Complete.");
        $finish; // End the simulation.
    end

endmodule




