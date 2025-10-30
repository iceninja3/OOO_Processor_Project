`timescale 1ns / 1ps

module priority_decoder_tb;

// Use localparams for testbench-specific settings
localparam WIDTH = 4;
localparam OUT_WIDTH = $clog2(WIDTH);

// Testbench signals
logic [WIDTH-1:0]     tb_in;
wire  [OUT_WIDTH-1:0] tb_out;
wire  tb_valid;

// create DUT
priority_decoder #(
    .WIDTH(WIDTH) // Pass the parameter to the DUT
) dut (
    .in(tb_in),
    .out(tb_out),
    .valid(tb_valid)
);

// Self-checking, exhaustive test block
initial begin
    logic [OUT_WIDTH-1:0] expected_out;
    logic                 expected_valid;
    int                   errors = 0;

    $display("Starting Exhaustive Test for WIDTH=%0d...", WIDTH);
    $display("-----------------------------------------------");
    
    // Loop from 0 to 2^WIDTH - 1
    // (e.g., for WIDTH=4, this loops from 0 to 15)
    for (int i = 0; i < (1 << WIDTH); i++) begin
        tb_in = i;
        
        // calc expected answer
        // logic re-implements the priority decoder's specification to check against.
        expected_valid = 0;
        expected_out = '0; // Default output
        
        for (int j = WIDTH - 1; j >= 0; j--) begin
            if (i[j] == 1'b1) begin
                expected_out = j;   // Highest priority bit index
                expected_valid = 1; // It's valid
                break;              // Stop searching
            end
        end //no
        
        #10;
        
        // actual testing part
        if (tb_out !== expected_out || tb_valid !== expected_valid) begin
            $error("FAIL: in=%b | Expected: out=%d valid=%b | GOT: out=%d valid=%b",
                   i, expected_out, expected_valid, tb_out, tb_valid);
            errors++;
        end
    end

    // reuslts
    if (errors == 0) begin
        $display("-----------------------------------------------");
        $display("SUCCESS: All %0d test cases PASSED.", (1 << WIDTH));
    end else begin
        $display("-----------------------------------------------");
        $display("FAILURE: Test FAILED with %0d error(s).", errors);
    end
    
    $finish; // use close_sim or else vivado will tweak
end

endmodule