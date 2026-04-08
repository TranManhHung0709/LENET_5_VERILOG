// Max-Pooling Layer 2 (2x2, stride=2) for 8 Channels
module maxpool_layer_2 (
    input clk,
    input rst_n,
    input valid_in,
    input signed [15:0] in_ch0,
    input signed [15:0] in_ch1,
    input signed [15:0] in_ch2,
    input signed [15:0] in_ch3,
    input signed [15:0] in_ch4,
    input signed [15:0] in_ch5,
    input signed [15:0] in_ch6,
    input signed [15:0] in_ch7,
    
    output valid_out,
    output signed [15:0] out_ch0,
    output signed [15:0] out_ch1,
    output signed [15:0] out_ch2,
    output signed [15:0] out_ch3,
    output signed [15:0] out_ch4,
    output signed [15:0] out_ch5,
    output signed [15:0] out_ch6,
    output signed [15:0] out_ch7
);

    parameter IMG_WIDTH = 8;

    // Pack 8 channels into a 128-bit bus
    wire [127:0] packed_in;
    assign packed_in = {in_ch7, in_ch6, in_ch5, in_ch4, in_ch3, in_ch2, in_ch1, in_ch0};

    // Line buffer for storing one previous row (8 elements)
    reg [127:0] line_buf [0:IMG_WIDTH-1];
    
    // Buffers for neighboring pixels
    reg [127:0] prev_pixel;
    reg [127:0] shifted_out_pixel;
    
    // Current data stream coordinates
    reg [3:0] col_cnt; // 0 to 7
    reg [3:0] row_cnt; // 0 to 7
    
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            col_cnt <= 0;
            row_cnt <= 0;
            prev_pixel <= 0;
            shifted_out_pixel <= 0;
            for (i=0; i<IMG_WIDTH; i=i+1) begin
                line_buf[i] <= 0;
            end
        end else if (valid_in) begin
            // Update coordinates
            if (col_cnt == IMG_WIDTH - 1) begin
                col_cnt <= 0;
                if (row_cnt == IMG_WIDTH - 1)
                    row_cnt <= 0;
                else
                    row_cnt <= row_cnt + 1;
            end else begin
                col_cnt <= col_cnt + 1;
            end
            
            // Store previous pixel (Left)
            prev_pixel <= packed_in;
            
            // Store diagonal pixel (Top-Left)
            shifted_out_pixel <= line_buf[IMG_WIDTH-1];
            
            // Shift line buffer
            for (i=IMG_WIDTH-1; i>0; i=i-1) begin
                line_buf[i] <= line_buf[i-1];
            end
            line_buf[0] <= packed_in;
        end
    end

    // Define 4 window corners for each channel
    // Locations: TL (Top Left), TR (Top Right), BL (Bottom Left), BR (Bottom Right)
    
    // Channel 0
    wire signed [15:0] ch0_TL = shifted_out_pixel[15:0];
    wire signed [15:0] ch0_TR = line_buf[IMG_WIDTH-1][15:0];
    wire signed [15:0] ch0_BL = prev_pixel[15:0];
    wire signed [15:0] ch0_BR = packed_in[15:0];
    wire signed [15:0] max_ch0;
    maxpool2d_window m_pool_0 (.d0(ch0_TL), .d1(ch0_TR), .d2(ch0_BL), .d3(ch0_BR), .max_out(max_ch0));

    // Channel 1
    wire signed [15:0] ch1_TL = shifted_out_pixel[31:16];
    wire signed [15:0] ch1_TR = line_buf[IMG_WIDTH-1][31:16];
    wire signed [15:0] ch1_BL = prev_pixel[31:16];
    wire signed [15:0] ch1_BR = packed_in[31:16];
    wire signed [15:0] max_ch1;
    maxpool2d_window m_pool_1 (.d0(ch1_TL), .d1(ch1_TR), .d2(ch1_BL), .d3(ch1_BR), .max_out(max_ch1));

    // Channel 2
    wire signed [15:0] ch2_TL = shifted_out_pixel[47:32];
    wire signed [15:0] ch2_TR = line_buf[IMG_WIDTH-1][47:32];
    wire signed [15:0] ch2_BL = prev_pixel[47:32];
    wire signed [15:0] ch2_BR = packed_in[47:32];
    wire signed [15:0] max_ch2;
    maxpool2d_window m_pool_2 (.d0(ch2_TL), .d1(ch2_TR), .d2(ch2_BL), .d3(ch2_BR), .max_out(max_ch2));

    // Channel 3
    wire signed [15:0] ch3_TL = shifted_out_pixel[63:48];
    wire signed [15:0] ch3_TR = line_buf[IMG_WIDTH-1][63:48];
    wire signed [15:0] ch3_BL = prev_pixel[63:48];
    wire signed [15:0] ch3_BR = packed_in[63:48];
    wire signed [15:0] max_ch3;
    maxpool2d_window m_pool_3 (.d0(ch3_TL), .d1(ch3_TR), .d2(ch3_BL), .d3(ch3_BR), .max_out(max_ch3));

    // Channel 4
    wire signed [15:0] ch4_TL = shifted_out_pixel[79:64];
    wire signed [15:0] ch4_TR = line_buf[IMG_WIDTH-1][79:64];
    wire signed [15:0] ch4_BL = prev_pixel[79:64];
    wire signed [15:0] ch4_BR = packed_in[79:64];
    wire signed [15:0] max_ch4;
    maxpool2d_window m_pool_4 (.d0(ch4_TL), .d1(ch4_TR), .d2(ch4_BL), .d3(ch4_BR), .max_out(max_ch4));

    // Channel 5
    wire signed [15:0] ch5_TL = shifted_out_pixel[95:80];
    wire signed [15:0] ch5_TR = line_buf[IMG_WIDTH-1][95:80];
    wire signed [15:0] ch5_BL = prev_pixel[95:80];
    wire signed [15:0] ch5_BR = packed_in[95:80];
    wire signed [15:0] max_ch5;
    maxpool2d_window m_pool_5 (.d0(ch5_TL), .d1(ch5_TR), .d2(ch5_BL), .d3(ch5_BR), .max_out(max_ch5));

    // Channel 6
    wire signed [15:0] ch6_TL = shifted_out_pixel[111:96];
    wire signed [15:0] ch6_TR = line_buf[IMG_WIDTH-1][111:96];
    wire signed [15:0] ch6_BL = prev_pixel[111:96];
    wire signed [15:0] ch6_BR = packed_in[111:96];
    wire signed [15:0] max_ch6;
    maxpool2d_window m_pool_6 (.d0(ch6_TL), .d1(ch6_TR), .d2(ch6_BL), .d3(ch6_BR), .max_out(max_ch6));

    // Channel 7
    wire signed [15:0] ch7_TL = shifted_out_pixel[127:112];
    wire signed [15:0] ch7_TR = line_buf[IMG_WIDTH-1][127:112];
    wire signed [15:0] ch7_BL = prev_pixel[127:112];
    wire signed [15:0] ch7_BR = packed_in[127:112];
    wire signed [15:0] max_ch7;
    maxpool2d_window m_pool_7 (.d0(ch7_TL), .d1(ch7_TR), .d2(ch7_BL), .d3(ch7_BR), .max_out(max_ch7));
    
    // Valid logic: Asserted when Row and Column indices are odd (End of 2x2 window)
    wire window_valid_comb = valid_in && (col_cnt[0] == 1'b1) && (row_cnt[0] == 1'b1);

    // Output Registers
    reg reg_valid_out;
    reg signed [15:0] reg_out_ch0, reg_out_ch1, reg_out_ch2, reg_out_ch3;
    reg signed [15:0] reg_out_ch4, reg_out_ch5, reg_out_ch6, reg_out_ch7;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_valid_out <= 0;
            reg_out_ch0 <= 0; reg_out_ch1 <= 0; reg_out_ch2 <= 0; reg_out_ch3 <= 0;
            reg_out_ch4 <= 0; reg_out_ch5 <= 0; reg_out_ch6 <= 0; reg_out_ch7 <= 0;
        end else begin
            if (window_valid_comb) begin
                reg_out_ch0 <= max_ch0; reg_out_ch1 <= max_ch1;
                reg_out_ch2 <= max_ch2; reg_out_ch3 <= max_ch3;
                reg_out_ch4 <= max_ch4; reg_out_ch5 <= max_ch5;
                reg_out_ch6 <= max_ch6; reg_out_ch7 <= max_ch7;
            end
            reg_valid_out <= window_valid_comb;
        end
    end

    assign valid_out = reg_valid_out;
    assign out_ch0 = reg_out_ch0; assign out_ch1 = reg_out_ch1;
    assign out_ch2 = reg_out_ch2; assign out_ch3 = reg_out_ch3;
    assign out_ch4 = reg_out_ch4; assign out_ch5 = reg_out_ch5;
    assign out_ch6 = reg_out_ch6; assign out_ch7 = reg_out_ch7;

endmodule
