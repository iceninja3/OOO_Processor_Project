`timescale 1ns/1ps

module tb_Fetch;

  // Match DUT parameters
  localparam ADDR_WIDTH = 4;    // 16 instructions for easy sim
  localparam DATA_WIDTH = 32;
  localparam RESET_PC   = 32'h0000_0000;
  localparam DEPTH      = (1 << ADDR_WIDTH);

  // Clock / reset
  logic clk;
  logic reset;

  // Ready/valid interface to "decode" (next stage)
  logic        ready_i;
  logic        valid_o;
  logic [31:0] pc_o;
  logic [DATA_WIDTH-1:0] inst_o;

  // iCache <-> Fetch connection
  logic [ADDR_WIDTH-1:0] icache_addr;
  logic [DATA_WIDTH-1:0] icache_rdata;

  // -------------------------------
  // Instantiate DUTs
  // -------------------------------
  iCache #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) dut_icache (
    .clk   (clk),
    .addr  (icache_addr),
    .rdata (icache_rdata)
  );

  Fetch #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .RESET_PC  (RESET_PC)
  ) dut_fetch (
    .clk         (clk),
    .reset       (reset),
    .icache_addr (icache_addr),
    .icache_rdata(icache_rdata),
    .valid_o     (valid_o),
    .ready_i     (ready_i),
    .pc_o        (pc_o),
    .inst_o      (inst_o)
  );

  // -------------------------------
  // Clock generation
  // -------------------------------
  initial clk = 0;
  always #5 clk = ~clk;   // 10 ns period

  // -------------------------------
  // Stimulus
  // -------------------------------
  initial begin
    int i;

    // Initialize
    reset   = 1;
    ready_i = 0;

    // Preload iCache memory with known pattern:
    // mem[word] = 0x1000_0000 + word
    for (i = 0; i < DEPTH; i++) begin
      dut_icache.mem[i] = 32'h1000_0000 + i;
    end

    // Hold reset for a few cycles
    repeat (3) @(posedge clk);
    reset = 0;

    // After reset, let fetch run with ready=1 for a while
    ready_i = 1;
    repeat (6) @(posedge clk);

    // Insert a stall: ready=0 for 3 cycles
    ready_i = 0;
    repeat (3) @(posedge clk);

    // Then ready again
    ready_i = 1;
    repeat (8) @(posedge clk);

    $display("=== Test completed ===");
    $finish;
  end

  // -------------------------------
  // Self-check + tracing
  // -------------------------------
  logic [31:0] prev_pc;
  logic        prev_valid_and_ready;

  always_ff @(posedge clk) begin
    // Trace
    $display("t=%0t  rst=%0b  ready=%0b  valid=%0b  PC=%08h  INST=%08h",
             $time, reset, ready_i, valid_o, pc_o, inst_o);

    // Only check when output is valid (ignore reset/X time)
    if (!reset && valid_o) begin
      // Expected instruction from our pattern:
      // inst = 0x1000_0000 + (pc >> 2)
      logic [31:0] expected_inst;
      expected_inst = 32'h1000_0000 + (pc_o >> 2);

      if (inst_o !== expected_inst) begin
        $error("BAD INST: PC=%08h expected %08h got %08h",
               pc_o, expected_inst, inst_o);
      end

      // Check PC+4 behavior when we *weren't* stalled
      if (prev_valid_and_ready) begin
        if (ready_i) begin
          if (pc_o !== prev_pc + 32'd4) begin
            $error("BAD PC STEP: prev_pc=%08h  pc_o=%08h (expected %08h)",
                   prev_pc, pc_o, prev_pc + 32'd4);
          end
        end else begin
          // If we just deasserted ready, PC should NOT change
          if (pc_o !== prev_pc) begin
            $error("BAD STALL: ready_i=0 but PC changed from %08h to %08h",
                   prev_pc, pc_o);
          end
        end
      end
    end

    // Update history
    prev_pc             <= pc_o;
    prev_valid_and_ready <= (valid_o && ready_i && !reset);
  end

endmodule