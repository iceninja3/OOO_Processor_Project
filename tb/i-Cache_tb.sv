`timescale 1ns/1ps

module tb_iCache;

  // Match DUT parameters
  localparam ADDR_WIDTH = 4;              // 16 words
  localparam DATA_WIDTH = 32;
  localparam DEPTH      = (1 << ADDR_WIDTH);

  // DUT I/O
  logic                   clk;
  logic [ADDR_WIDTH-1:0]  addr;
  logic [DATA_WIDTH-1:0]  rdata;

  // Expected contents loaded from the same hex file
  logic [DATA_WIDTH-1:0] expected_mem [0:DEPTH-1];

  // Instantiate DUT
  iCache #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) dut (
    .clk  (clk),
    .addr (addr),
    .rdata(rdata)
  );

  // Clock: 10 ns period
  initial clk = 0;
  always #5 clk = ~clk;

  initial begin : TEST
    int i;

    // Initialize addr
    addr = '0;

    // Load expected data from the same file as DUT
    $readmemh("program.hex", expected_mem);

    // Give some time before we start checking
    repeat (2) @(posedge clk);

    $display("=== Starting iCache read test (file-driven) ===");

    // Read out and compare every address
    for (i = 0; i < DEPTH; i++) begin
      addr = i;

      // Synchronous read: rdata updates on this posedge
      @(posedge clk);
      #1; // let rdata settle

      if (rdata !== expected_mem[i]) begin
        $error("Mismatch at addr %0d: expected %h, got %h",
               i, expected_mem[i], rdata);
      end else begin
        $display("PASS: addr=%0d  rdata=%h", i, rdata);
      end
    end

    $display("=== iCache file-based test completed ===");
    $finish;
  end

endmodule