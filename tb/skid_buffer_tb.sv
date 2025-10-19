`timescale 1ns/1ps

module skid_buffer_tb;

    parameter T_CLK = 10; // Clock period: 10 ns (100 MHz)
    parameter DATA_WIDTH = 8;
    typedef logic [DATA_WIDTH-1:0] T;


    logic clk;
    logic reset;
    logic valid_in;
    logic ready_in; // Wire to observe DUT output
    T     data_in;
    logic valid_out; // Wire to observe DUT output
    logic ready_out;
    T     data_out;  // Wire to observe DUT output

    skid_buffer_struct #(
        .T(T)
    ) dut (
        .clk(clk),
        .reset(reset),
        .valid_in(valid_in),
        .ready_in(ready_in),
        .data_in(data_in),
        .valid_out(valid_out),
        .ready_out(ready_out),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        forever #(T_CLK/2) clk = ~clk;
    end

    initial begin
        reset = 1;
        repeat(2) @(posedge clk);
        reset = 0;
    end


    initial begin
        // driving signals
        valid_in  = 0;
        ready_out = 0;
        data_in   = '0;

        // Wait for reset to finish
        @(negedge reset);
        @(posedge clk);

        $display("--------------------------------------------------");
        $display("SCENARIO 1: Ideal throughput (consumer is always ready)");
        $display("--------------------------------------------------");
        ready_out <= 1; // Consumer is always ready
        for (int i = 0; i < 3; i++) begin
            send_data($random);
        end
        
        // Let the last piece of data drain
        valid_in <= 0;
        @(posedge clk);
        @(posedge clk);

        $display("\n--------------------------------------------------");
        $display("SCENARIO 2: Consumer stalls, buffer should fill up");
        $display("--------------------------------------------------");
        ready_out <= 1;
        send_data(8'hAA); // Send one item successfully

        // Now, consumer stalls
        ready_out <= 0;
        $display("@%0t: Consumer STALLS (ready_out=0)", $time);

        send_data(8'hBB); // Send a second item, this one should get stuck in the buffer
        valid_in <= 0;
        // At this point, ready_in should go low because the buffer is full.

        repeat(3) @(posedge clk);

        $display("\n--------------------------------------------------");
        $display("SCENARIO 3: Consumer unstalls, buffer should drain");
        $display("--------------------------------------------------");
        ready_out <= 1; // Consumer is ready again
        $display("@%0t: Consumer UNSTALLS (ready_out=1)", $time);

        // Wait for the buffer to drain and become ready again
        wait (ready_in == 1);
        $display("@%0t: Buffer is ready again (ready_in=1)", $time);
        
        send_data(8'hCC); // Send a final piece of data
        valid_in <= 0;
        
        repeat(5) @(posedge clk);
        $display("\nSimulation finished.");
        $finish;
    end
    
    // Helper task to send data like a real producer
    task send_data(input T data);
        @(posedge clk);
        valid_in <= 1;
        data_in  <= data;
        $display("@%0t: Producer sends data 0x%h", $time, data);
        wait (ready_in == 1); // Wait until the buffer is ready
        @(posedge clk); // Hold for one cycle for the transfer
        valid_in <= 0;
    endtask

    // ## 4. Monitor ##
    // Display signals when they change for easy debugging
    initial begin
        $monitor("@%0t: [PRODUCER] valid_in=%b, ready_in=%b, data_in=0x%h | [CONSUMER] valid_out=%b, ready_out=%b, data_out=0x%h",
                 $time, valid_in, ready_in, data_in, valid_out, ready_out, data_out);
    end

endmodule