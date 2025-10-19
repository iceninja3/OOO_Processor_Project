`timescale 1ns/1ps
//used LLM for tb 
// ------------------ Writer ------------------
module cb_writer #(
  parameter type T = logic [31:0]
)(
  input  logic clk,
  input  logic rst_n,
  input  logic full,
  output logic write_en,
  output T     write_data,
  output logic done
);
  T cnt;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      write_en   <= 1'b0;
      write_data <= '0;
      cnt        <= '0;
      done       <= 1'b0;
    end else begin
      if (!full && !done) begin
        write_en   <= 1'b1;
        write_data <= cnt;
        cnt        <= cnt + T'(1);
      end else begin
        write_en <= 1'b0;
        if (full) done <= 1'b1; // stop once FIFO is full
      end
    end
  end
endmodule

// ------------------ Reader ------------------
module cb_reader #(
  parameter type T = logic [31:0]
)(
  input  logic clk,
  input  logic rst_n,
  input  logic full,
  input  logic empty,
  input  T     read_data,
  output logic read_en,
  output logic done
);
  typedef enum logic [1:0] {WAIT_FULL, DRAIN, DONE} state_t;
  state_t state;

  T expected;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state    <= WAIT_FULL;
      read_en  <= 1'b0;
      expected <= '0;
      done     <= 1'b0;
    end else begin
      unique case (state)
        WAIT_FULL: begin
          read_en <= 1'b0;
          if (full) begin
            state    <= DRAIN;
            expected <= '0; // expect what writer wrote: 0..7
          end
        end

        DRAIN: begin
          read_en <= ~empty; // read every cycle until empty

          // With your circular buffer design, read_data is registered on this edge.
          if (read_en) begin
            if (read_data !== expected) begin
              $error("[READ] Mismatch: got %0d (0x%0h), expected %0d (0x%0h)",
                     read_data, read_data, expected, expected);
            end else begin
              $display("[%0t] READ OK: %0d", $time, read_data);
            end
            expected <= expected + T'(1);
          end

          if (empty && !read_en) begin
            state <= DONE;
            done  <= 1'b1;
          end
        end

        DONE: begin
          read_en <= 1'b0;
        end
      endcase
    end
  end
endmodule

// ------------------ Testbench Top ------------------
module tb_circular_buffer;
  localparam type T     = logic [31:0];
  localparam int  DEPTH = 8;

  // DUT I/O
  logic clk;
  logic reset; // active-high to match your module
  logic write_en;
  T     write_data;
  logic read_en;
  T     read_data;
  logic full, empty;

  // Instantiate your circular buffer DUT
  circular_buffer #(.T(T), .DEPTH(DEPTH)) dut (
    .clk        (clk),
    .reset      (reset),
    .write_en   (write_en),
    .write_data (write_data),
    .read_en    (read_en),
    .read_data  (read_data),
    .full       (full),
    .empty      (empty)
  );

  // Agents
  logic writer_done, reader_done;

  cb_writer #(.T(T)) u_writer (
    .clk        (clk),
    .rst_n      (~reset),
    .full       (full),
    .write_en   (write_en),
    .write_data (write_data),
    .done       (writer_done)
  );

  cb_reader #(.T(T)) u_reader (
    .clk        (clk),
    .rst_n      (~reset),
    .full       (full),
    .empty      (empty),
    .read_data  (read_data),
    .read_en    (read_en),
    .done       (reader_done)
  );

  // Clock: 10 ns
  initial clk = 0;
  always #5 clk = ~clk;

  // Reset + VCD
  initial begin
    reset = 1'b1;
    $dumpfile("tb_circular_buffer.vcd");
    $dumpvars(0, tb_circular_buffer);
    repeat (3) @(posedge clk);
    reset = 1'b0;
    $display("[%0t] Deasserted reset; writer will fill until FULL, then reader drains.", $time);
  end

  // Timeout guard
  initial begin
    #5000;
    $fatal(1, "Test timed out.");
  end

  // Finish when drained
  always @(posedge clk) begin
    if (reader_done) begin
      $display("[%0t] TEST PASS: Filled to FULL and drained to EMPTY with correct data.", $time);
      $finish; // no argument → exit code 0
    end
  end
endmodule
