`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.02.2026 17:46:31
// Design Name: 
// Module Name: SPI_Master
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module SPI_Master(

     input  clk,
    input  rst,
    input  tx_enable,
    output reg mosi,
    output reg cs,
    output wire sclk
    );
   
    // FSM states (Verilog style)
    parameter idle    = 2'b00;
    parameter tx_data = 2'b01;

    reg [1:0] state;

    reg [7:0] din = 8'hFE;

    reg spi_sclk = 0;
    reg [2:0] ccount = 0;
    reg [2:0] count  = 0;

    ////////////////// CLOCK DIVIDER (System clk ? SPI clk)
    always @(posedge clk) begin
        if (!rst && tx_enable) begin
            if (ccount < 3)
                ccount <= ccount + 1;
            else begin
                ccount   <= 0;
                spi_sclk <= ~spi_sclk;
            end
        end
    end

    ////////////////// SPI MASTER FSM (runs on sclk)
    always @(posedge spi_sclk) begin
        case (state)

            idle: begin
            
                  cs    <= 1'b1;
                  mosi  <= 1'b0;
               
                     if (tx_enable && !rst) begin
                        cs    <= 1'b0;
                        state <= tx_data;
                             end
                    
                    else 
                        state <= idle;
                end
            tx_data: begin
                if (count < 8) begin
                    mosi  <= din[7-count];
                    count <= count + 1;
                end
                else begin
                    mosi  <= 1'b0;
                    cs    <= 1'b1;
                    count <= 0;
                    state <= idle;
                end
            end

            default: state <= idle;
        endcase
    end

    assign sclk = spi_sclk;

endmodule


module SPI_Slave (
    input  sclk,
    input  mosi,
    input  cs,
    output [7:0] dout,
    output reg done 
);

    parameter idle   = 1'b0;
    parameter sample = 1'b1;

    reg state;
    integer count = 0;
    reg [7:0] data = 8'b0;

    always @(negedge sclk) begin
        case (state)

                    idle: begin
                    
    
                    done <= 1'b0;
                    if (cs == 1'b0)
                        state <= sample;
                    else
                        state <= idle;
            end

            sample: begin
                if (count < 8) begin
                    count <= count + 1;
                    data  <= {data[6:0], mosi};
                end
                else begin
                    count <= 0;
                    state <= idle;
                    done  <= 1'b1;
                end
            end

            default: state <= idle;
        endcase
    end

    assign dout = data;

endmodule



//SPI Top
 module SPI_Top( 
 clk, rst, tx_enable , dout, done 
 );
 
 input clk, rst, tx_enable;
 output [7:0] dout;
 output done ;
 
 wire mosi, ss, sclk; 
 SPI_Master spi_m (clk, rst, tx_enable, mosi, ss, sclk); 
 SPI_Slave spi_s (sclk, mosi,ss, dout, done);
 
 endmodule
 
 
 




