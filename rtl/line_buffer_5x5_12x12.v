// 5x5 Line Buffer for 12x12 Images (4-channel packed 64-bit data)
module line_buffer_5x5_12x12 (
    input clk,
    input rst_n,
    input valid_in,            
    input [63:0] pixel_in,     
    
    // Window outputs (25 pixels). 64-bit containers.
    output [63:0] w00, output [63:0] w01, output [63:0] w02, output [63:0] w03, output [63:0] w04,
    output [63:0] w10, output [63:0] w11, output [63:0] w12, output [63:0] w13, output [63:0] w14,
    output [63:0] w20, output [63:0] w21, output [63:0] w22, output [63:0] w23, output [63:0] w24,
    output [63:0] w30, output [63:0] w31, output [63:0] w32, output [63:0] w33, output [63:0] w34,
    output [63:0] w40, output [63:0] w41, output [63:0] w42, output [63:0] w43, output [63:0] w44,
    
    output valid_out          
);
    // Image dimensions
    parameter IMG_WIDTH = 12;  
    
    // 5 Shift registers (Line buffers)
    reg [63:0] row0 [0:IMG_WIDTH-1];
    reg [63:0] row1 [0:IMG_WIDTH-1];
    reg [63:0] row2 [0:IMG_WIDTH-1];
    reg [63:0] row3 [0:IMG_WIDTH-1];
    reg [63:0] row4 [0:IMG_WIDTH-1];
    
    // Row and Column counters
    reg [3:0] col_cnt; 
    reg [3:0] row_cnt; 
    integer i;

    // Buffer management logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            col_cnt <= 0;
            row_cnt <= 0;
            for (i=0; i<IMG_WIDTH; i=i+1) begin
                row0[i] <= 0; row1[i] <= 0; row2[i] <= 0; row3[i] <= 0; row4[i] <= 0;
            end
        end else if (valid_in) begin
            // Increment counters
            if (col_cnt == IMG_WIDTH - 1) begin
                col_cnt <= 0;
                if (row_cnt != IMG_WIDTH - 1)
                    row_cnt <= row_cnt + 1;
            end else begin
                col_cnt <= col_cnt + 1;
            end
            
            // Shift data right (vertical pipeline for each row)
            for (i=IMG_WIDTH-1; i>0; i=i-1) begin
                row0[i] <= row0[i-1];
                row1[i] <= row1[i-1];
                row2[i] <= row2[i-1];
                row3[i] <= row3[i-1];
                row4[i] <= row4[i-1];
            end
            
            // Move overflow pixels to the next row (horizontal shift)
            row0[0] <= row1[IMG_WIDTH-1];
            row1[0] <= row2[IMG_WIDTH-1];
            row2[0] <= row3[IMG_WIDTH-1];
            row3[0] <= row4[IMG_WIDTH-1];
            
            // Load new pixel into the last row
            row4[0] <= pixel_in;
        end
    end

    // Valid signal logic
    reg out_valid_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid_reg <= 1'b0;
        end else begin
            // Assert valid when a 5x5 window is ready
            if (valid_in && row_cnt >= 4 && col_cnt >= 4)
                out_valid_reg <= 1'b1;
            else
                out_valid_reg <= 1'b0;
        end
    end
    assign valid_out = out_valid_reg;

    // Map shift registers to window outputs (5x5 kernel)
    assign w00 = row0[4]; assign w01 = row0[3]; assign w02 = row0[2]; assign w03 = row0[1]; assign w04 = row0[0];
    assign w10 = row1[4]; assign w11 = row1[3]; assign w12 = row1[2]; assign w13 = row1[1]; assign w14 = row1[0];
    assign w20 = row2[4]; assign w21 = row2[3]; assign w22 = row2[2]; assign w23 = row2[1]; assign w24 = row2[0];
    assign w30 = row3[4]; assign w31 = row3[3]; assign w32 = row3[2]; assign w33 = row3[1]; assign w34 = row3[0];
    assign w40 = row4[4]; assign w41 = row4[3]; assign w42 = row4[2]; assign w43 = row4[1]; assign w44 = row4[0];

endmodule
