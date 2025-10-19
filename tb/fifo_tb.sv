`timescale 1ns/1ps
//used LLM for tb creation 
// ------------------ Writer ------------------
module writer #(
  parameter type T = logic [31:0],
  parameter int DEPTH = 8
)(
  input  logic clk,
  input  logic rst_n,
  input  logic full,
  output logic write_en,
  output T     write_data,
  output logic done
);
  T   data_cnt;
  logic started;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      write_en   <= 1'b0;
      write_data <= '0;
      data_cnt   <= '0;
      started    <= 1'b0;
      done       <= 1'b0;
    end else begin
      if (!full && !done) begin
        // keep writing until FIFO asserts full
        write_en   <= 1'b1;
        write_data <= data_cnt;
        data_cnt   <= data_cnt + T'(1);
        started    <= 1'b1;
      end else begin
        write_en <= 1'b0;
        if (started && full) begin
          done <= 1'b1; // latched once we've seen full
        end
      end
    end
  end
endmodule

// ------------------ Reader ------------------
module reader #(
  parameter type T = logic [31:0],
  parameter int  DEPTH = 8
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
      done     <= 1'b0;
      expected <= '0;
    end else begin
      case (state)
        WAIT_FULL: begin
          read_en <= 1'b0;
          if (full) begin
            state    <= DRAIN;
            expected <= '0;
          end
        end

        DRAIN: begin
          // Assert read_en while not empty
          read_en <= ~empty;

          // Compare in the SAME cycle as read_en, since the FIFO outputs data that cycle
          if (read_en) begin
            if (read_data !== expected) begin
              $error("[READ] Mismatch: got %0d (0x%0h), expected %0d (0x%0h)",
                     read_data, read_data, expected, expected);
            end else begin
              $display("[%0t] READ OK: %0d", $time, read_data);
            end
            expected <= expected + T'(1);
          end

          // Move to DONE right after we see empty and stop reading
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