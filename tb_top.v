`timescale 1ns / 1ps

module tb_top;

    // =========================================================
    // DUT INPUTS
    // =========================================================

    reg [31:0] data_in;

    reg        w_en;
    reg        wclk;
    reg        wrst_n;

    reg        rclk;
    reg        r_en;
    reg        rrst_n;

    // =========================================================
    // DUT OUTPUTS
    // =========================================================

    wire [31:0] data_out;

    wire full;
    wire empty;

    // =========================================================
    // DUT INSTANTIATION
    // =========================================================

    top dut (
        .data_in  (data_in),

        .w_en     (w_en),
        .wclk     (wclk),
        .wrst_n   (wrst_n),

        .rclk     (rclk),
        .r_en     (r_en),
        .rrst_n   (rrst_n),

        .data_out (data_out),

        .full     (full),
        .empty    (empty)
    );

    // =========================================================
    // WRITE CLOCK
    //
    // 100 MHz
    // Period = 10 ns
    // =========================================================

    initial begin
        wclk = 1'b0;

        forever
            #5 wclk = ~wclk;
    end

    // =========================================================
    // READ CLOCK
    //
    // 50 MHz
    // Period = 20 ns
    // =========================================================

    initial begin
        rclk = 1'b0;

        forever
            #10 rclk = ~rclk;
    end

    // =========================================================
    // INITIALIZATION / RESET
    // =========================================================

    initial begin

        wrst_n = 1'b0;
        rrst_n = 1'b0;

        w_en = 1'b0;
        r_en = 1'b0;

        data_in = 32'b0;

        // Reset for 50 ns
        #50;

        wrst_n = 1'b1;
        rrst_n = 1'b1;

        $display("");
        $display("==============================================");
        $display("         ASYNCHRONOUS FIFO TEST");
        $display("==============================================");
        $display("FIFO       : 8 x 32-bit");
        $display("WRITE CLK  : 100 MHz / 10 ns");
        $display("READ CLK   : 50 MHz / 20 ns");
        $display("==============================================");
        $display("");

    end

    // =========================================================
    // MAIN TEST
    // =========================================================

    integer i;

    reg [31:0] expected_data;

    initial begin

        // -----------------------------------------------------
        // Wait until reset is released
        // -----------------------------------------------------

        wait(wrst_n == 1'b1);
        wait(rrst_n == 1'b1);

        #20;

        // =====================================================
        // CHECK INITIAL EMPTY
        // =====================================================

        $display("==============================================");
        $display("        INITIAL EMPTY CHECK");
        $display("==============================================");

        if (empty == 1'b1)
            $display("%0t ns : PASS - FIFO is EMPTY", $time);
        else
            $display("%0t ns : FAIL - FIFO is NOT EMPTY", $time);

        // =====================================================
        // WRITE 8 WORDS
        // =====================================================

        $display("");
        $display("==============================================");
        $display("             WRITE 8 WORDS");
        $display("==============================================");

        for (i = 0; i < 8; i = i + 1) begin

            @(negedge wclk);

            if (full) begin

                $display(
                    "%0t ns : ERROR - FIFO FULL before WRITE[%0d]",
                    $time,
                    i
                );

            end

            w_en    = 1'b1;
            data_in = 32'h1000_0000 + i;

            @(posedge wclk);

            $display(
                "%0t ns : WRITE[%0d] = %h",
                $time,
                i,
                data_in
            );

        end

        @(negedge wclk);

        w_en    = 1'b0;
        data_in = 32'b0;

        // =====================================================
        // WAIT FOR FULL FLAG
        //
        // Because the read pointer is synchronized into the
        // write domain, FULL is not necessarily asserted
        // immediately after the 8th write.
        // =====================================================

        #100;

        $display("");
        $display("==============================================");
        $display("               FULL CHECK");
        $display("==============================================");

        if (full == 1'b1) begin

            $display(
                "%0t ns : PASS - FIFO FULL = 1",
                $time
            );

        end

        else begin

            $display(
                "%0t ns : FAIL - FIFO FULL = 0",
                $time
            );

        end

        // =====================================================
        // READ 8 WORDS
        // =====================================================

        $display("");
        $display("==============================================");
        $display("              READ 8 WORDS");
        $display("==============================================");

        expected_data = 32'h1000_0000;

        for (i = 0; i < 8; i = i + 1) begin

            @(negedge rclk);

            if (empty) begin

                $display(
                    "%0t ns : ERROR - FIFO EMPTY before READ[%0d]",
                    $time,
                    i
                );

            end

            r_en = 1'b1;

            @(posedge rclk);

            #1;

            if (data_out == expected_data) begin

                $display(
                    "%0t ns : READ[%0d] = %h  PASS",
                    $time,
                    i,
                    data_out
                );

            end

            else begin

                $display(
                    "%0t ns : READ[%0d] = %h  FAIL - Expected %h",
                    $time,
                    i,
                    data_out,
                    expected_data
                );

            end

            expected_data = expected_data + 1;

        end

        @(negedge rclk);

        r_en = 1'b0;

        // =====================================================
        // WAIT FOR EMPTY FLAG
        // =====================================================

        #100;

        $display("");
        $display("==============================================");
        $display("              EMPTY CHECK");
        $display("==============================================");

        if (empty == 1'b1) begin

            $display(
                "%0t ns : PASS - FIFO EMPTY = 1",
                $time
            );

        end

        else begin

            $display(
                "%0t ns : FAIL - FIFO EMPTY = 0",
                $time
            );

        end

        // =====================================================
        // FINISH
        // =====================================================

        $display("");
        $display("==============================================");
        $display("          TEST COMPLETED");
        $display("==============================================");
        $display("");

        #50;

        $finish;

    end

endmodule
