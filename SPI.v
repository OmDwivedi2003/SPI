`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.02.2026
// Design Name: SPI Master–Slave
// Module Name: SPI_Master, SPI_Slave, SPI_Top
// Description:
//   Simple SPI Master and Slave implementation.
//   - SPI Mode-1 (CPOL = 0, CPHA = 1)
//   - Master changes MOSI on posedge SCLK
//   - Slave samples MOSI on negedge SCLK
//////////////////////////////////////////////////////////////////////////////////

// ============================================================================
// SPI MASTER MODULE
// ============================================================================
module SPI_Master (
    input  clk,          // System clock
    input  rst,          // Active-high reset
    input  tx_enable,    // Start SPI transmission
    output reg mosi,     // Master-Out Slave-In
    output reg cs,       // Chip Select (active low)
    output wire sclk     // SPI clock
);

    // -------------------------------
    // FSM State Encoding
    // -------------------------------
    parameter IDLE    = 2'b00;
    parameter TX_DATA = 2'b01;

    reg [1:0] state;          // FSM current state
    reg [7:0] din = 8'hFE;    // Data to be transmitted

    // SPI clock generation registers
    reg spi_sclk = 0;         // Internal SPI clock
    reg [2:0] ccount = 0;     // Clock divider counter
    reg [2:0] count  = 0;     // Bit counter (0–7)

    // -------------------------------
    // Clock Divider
    // Generates SPI clock from system clock
    // -------------------------------
    always @(posedge clk) begin
        if (!rst && tx_enable) begin
            if (ccount < 3)
                ccount <= ccount + 1;
            else begin
                ccount   <= 0;
                spi_sclk <= ~spi_sclk; // Toggle SPI clock
            end
        end
    end

    // -------------------------------
    // SPI Master FSM
    // Operates on SPI clock
    // -------------------------------
    always @(posedge spi_sclk) begin
        case (state)

            // ---------------------------
            // IDLE State
            // ---------------------------
            IDLE: begin
                cs   <= 1'b1;   // Deassert CS
                mosi <= 1'b0;

                if (tx_enable && !rst) begin
                    cs    <= 1'b0;   // Assert CS
                    state <= TX_DATA;
                end else
                    state <= IDLE;
            end

            // ---------------------------
            // TRANSMIT DATA State
            // ---------------------------
            TX_DATA: begin
                if (count < 8) begin
                    mosi  <= din[7 - count]; // Send MSB first
                    count <= count + 1;
                end else begin
                    // Transmission complete
                    mosi  <= 1'b0;
                    cs    <= 1'b1;   // Deassert CS
                    count <= 0;
                    state <= IDLE;
                end
            end

            default: state <= IDLE;
        endcase
    end

    // Assign internal SPI clock to output
    assign sclk = spi_sclk;

endmodule

// ============================================================================
// SPI SLAVE MODULE
// ============================================================================
module SPI_Slave (
    input  sclk,        // SPI clock from master
    input  mosi,        // Master-Out Slave-In
    input  cs,          // Chip Select (active low)
    output [7:0] dout,  // Received data
    output reg done     // Transfer completion flag
);

    // FSM states
    parameter IDLE   = 1'b0;
    parameter SAMPLE = 1'b1;

    reg state;              // FSM state
    integer count = 0;      // Bit counter
    reg [7:0] data = 8'b0;  // Shift register for received data

    // -------------------------------
    // SPI Slave FSM
    // Samples data on negedge of SCLK
    // -------------------------------
    always @(negedge sclk) begin
        case (state)

            // ---------------------------
            // IDLE State
            // ---------------------------
            IDLE: begin
                done <= 1'b0;
                if (cs == 1'b0)
                    state <= SAMPLE; // Start sampling
                else
                    state <= IDLE;
            end

            // ---------------------------
            // SAMPLE State
            // ---------------------------
            SAMPLE: begin
                if (count < 8) begin
                    count <= count + 1;
                    data  <= {data[6:0], mosi}; // Shift in MOSI
                end else begin
                    // Reception complete
                    count <= 0;
                    state <= IDLE;
                    done  <= 1'b1;
                end
            end

            default: state <= IDLE;
        endcase
    end

    // Assign received data to output
    assign dout = data;

endmodule

// ============================================================================
// SPI TOP MODULE (Master + Slave Integration)
// ============================================================================
module SPI_Top (
    input  clk,
    input  rst,
    input  tx_enable,
    output [7:0] dout,
    output done
);

    wire mosi;
    wire ss;
    wire sclk;

    // SPI Master Instance
    SPI_Master spi_m (
        .clk(clk),
        .rst(rst),
        .tx_enable(tx_enable),
        .mosi(mosi),
        .cs(ss),
        .sclk(sclk)
    );

    // SPI Slave Instance
    SPI_Slave spi_s (
        .sclk(sclk),
        .mosi(mosi),
        .cs(ss),
        .dout(dout),
        .done(done)
    );

endmodule
