`timescale 1ns / 1ps

module synchronizer_2ff(
        input clk,
        input rst_n,
        input [3:0] d_in,
        output reg[3:0] d_sync
    );
    
    reg [7:0] q1;
    
    always @(posedge clk)begin
        if(!rst_n)begin
            q1 <= 4'b0;
            d_sync <= 4'b0;
        end else begin
            q1 <= d_in;
            d_sync <= q1;
        end
    end    
             
endmodule
