`timescale 1ns/1ps

module tb_fifo;

  localparam int DEPTH  = 8;
  localparam int CYCLES = 500;
  typedef logic [31:0] T;

  //dut signals
  logic clk, reset;
  logic write_en, read_en;
  T     write_data, read_data;
  logic full, empty;

  //instantiation 
  fifo #(.T(T), .DEPTH(DEPTH)) dut (
    .clk, .reset,
    .write_en, .write_data,
    .read_en,  .read_data,
    .full, .empty
  );


  initial clk = 0;
  always #5 clk = ~clk;


  T     model_q[$];      
  logic read_fired_d;     
  T     exp_data_d;       
  bit   do_write, do_read;
  int   size_q;         
  
 
  initial begin
    reset      = 1;
    write_en   = 0;
    read_en    = 0;
    write_data = '0;
    repeat (3) @(negedge clk);
    reset = 0;
  end

  
  initial begin
    @(negedge reset);

    repeat (CYCLES) begin
      @(negedge clk);

      // defaults
      write_en = 0;
      read_en  = 0;

      // choose ops randomly
      do_write = $urandom_range(0,1);
      do_read  = $urandom_range(0,1);

      // Gate by GOLDEN MODEL prior size to avoid under/overflow
      if (size_q == DEPTH) do_write = 0;
      if (size_q == 0)     do_read  = 0;

      // occasional biases to hit edges
      if ($urandom_range(0,9) == 0) begin do_write = (size_q < DEPTH); do_read = 0; end
      if ($urandom_range(0,9) == 1) begin do_read  = (size_q > 0);     do_write = 0; end

      // drive
      if (do_write) begin
        write_en   = 1;
        write_data = $urandom();
      end
      if (do_read) begin
        read_en = 1;
      end
    end


    forever begin
      @(negedge clk);
      if (size_q == 0) begin
        write_en = 0;
        read_en  = 0;
        break;
      end
      write_en = 0;
      read_en  = 1;
    end

    repeat (2) @(negedge clk);
    $display("[TB] PASS: ran %0d cycles", CYCLES);
    $finish;
  end

  // Scoreboard & checks
  always_ff @(posedge clk) begin
    if (reset) begin
      model_q.delete();
      read_fired_d <= 0;
      exp_data_d   <= '0;
      size_q       <= 0;
    end else begin
      // === Check DUT flags against PRIOR-cycle occupancy ===
      assert (full  == (size_q == DEPTH))
        else $fatal(1, "[TB] full flag mismatch: prior_size=%0d full=%0b", size_q, full);
      assert (empty == (size_q == 0))
        else $fatal(1, "[TB] empty flag mismatch: prior_size=%0d empty=%0b", size_q, empty);

      // === Update golden model for THIS cycle ===
      if (write_en && (size_q < DEPTH)) begin
        model_q.push_back(write_data);
      end
      if (read_en && (size_q > 0)) begin
        exp_data_d   <= model_q.pop_front(); // capture for next-cycle compare
        read_fired_d <= 1;
      end else begin
        read_fired_d <= 0;
      end

      // Check registered read data (one-cycle latency)
      if (read_fired_d) begin
        assert (read_data === exp_data_d)
          else $fatal(1, "[TB] Data mismatch: got 0x%08x exp 0x%08x", read_data, exp_data_d);
      end

      // Update prior-size for next cycle (after applying this cycle's ops)
      size_q <= model_q.size();
    end
  end

  always_ff @(posedge clk) if (!reset) begin
    if (read_en && (size_q == 0))
      $warning("[TB] Read attempted when EMPTY");
    if (write_en && (size_q == DEPTH))
      $warning("[TB] Write attempted when FULL");
  end
  
  

endmodule