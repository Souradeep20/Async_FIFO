`timescale 1ns / 1ps

module top(

    input  [31:0] data_in,
    input         w_en,
    input         wclk,
    input         wrst_n,

    input         rclk,
    input         r_en,
    input         rrst_n,

    output [31:0] data_out,

    output reg    full,
    output reg    empty

);

    // =========================================================
    // POINTER SIGNALS
    // =========================================================

    wire [3:0] b_wptr_next;
    wire [3:0] g_wptr_next;
    wire       w_full;

    wire [3:0] b_rptr_next;
    wire [3:0] g_rptr_next;
    wire       r_empty;

    reg [3:0] b_rptr, g_rptr;
    reg [3:0] b_wptr, g_wptr;

    // =========================================================
    // SYNCHRONIZED GRAY POINTERS
    // =========================================================

    wire [3:0] g_rptr_sync;
    wire [3:0] g_wptr_sync;

    // =========================================================
    // FIFO MEMORY
    // 8 locations x 32 bits
    // =========================================================

    reg [31:0] fifo_mem [7:0];

    // =========================================================
    // 2-FLOP SYNCHRONIZERS
    // =========================================================

    synchronizer_2ff w_sync(
        .clk    (wclk),
        .rst_n  (wrst_n),
        .d_in   (g_rptr),
        .d_sync (g_rptr_sync)
    );

    synchronizer_2ff r_sync(
        .clk    (rclk),
        .rst_n  (rrst_n),
        .d_in   (g_wptr),
        .d_sync (g_wptr_sync)
    );

    // =========================================================
    // WRITE POINTER
    // =========================================================

    assign b_wptr_next = b_wptr + (w_en && !full);

    // Binary -> Gray
    assign g_wptr_next = b_wptr_next ^ (b_wptr_next >> 1);

    // FULL detection
    assign w_full =
        (g_wptr_next ==
        {~g_rptr_sync[3:2], g_rptr_sync[1:0]});

    // =========================================================
    // READ POINTER
    // =========================================================

    assign b_rptr_next = b_rptr + (r_en && !empty);

    // Binary -> Gray
    assign g_rptr_next = b_rptr_next ^ (b_rptr_next >> 1);

    // EMPTY detection
    assign r_empty =
        (g_rptr_next == g_wptr_sync);

    // =========================================================
    // WRITE CLOCK DOMAIN
    // =========================================================

    always @(posedge wclk or negedge wrst_n) begin

        if (!wrst_n) begin

            b_wptr <= 4'b0000;
            g_wptr <= 4'b0000;
            full   <= 1'b0;

        end

        else begin

            b_wptr <= b_wptr_next;
            g_wptr <= g_wptr_next;
            full   <= w_full;

        end

    end

    // =========================================================
    // READ CLOCK DOMAIN
    // =========================================================

    always @(posedge rclk or negedge rrst_n) begin

        if (!rrst_n) begin

            b_rptr <= 4'b0000;
            g_rptr <= 4'b0000;
            empty  <= 1'b1;

        end

        else begin

            b_rptr <= b_rptr_next;
            g_rptr <= g_rptr_next;
            empty  <= r_empty;

        end

    end

    // =========================================================
    // WRITE DATA
    // =========================================================

    always @(posedge wclk) begin

        if (w_en && !full)
            fifo_mem[b_wptr[2:0]] <= data_in;

    end

    // =========================================================
    // READ DATA
    // =========================================================

    assign data_out = fifo_mem[b_rptr[2:0]];

endmodule
