`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: conv1_tb
// Description: Testbench for LeNet-5 Convolution Layer 1.
//////////////////////////////////////////////////////////////////////////////////

module conv1_tb;

    reg clk;
    reg rst_n;
    reg valid_in;
    reg signed [15:0] pixel_in;
    
    wire valid_out;
    wire signed [15:0] conv_out_0;
    wire signed [15:0] conv_out_1;
    wire signed [15:0] conv_out_2;
    wire signed [15:0] conv_out_3;

    // Instantiate Conv Layer 1
    conv_layer_1 uut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .pixel_in(pixel_in),
        .valid_out(valid_out),
        .conv_out_0(conv_out_0),
        .conv_out_1(conv_out_1),
        .conv_out_2(conv_out_2),
        .conv_out_3(conv_out_3)
    );

    // Memory buffer for input image 28x28 = 784 pixels
    reg signed [15:0] img_mem [0:783];
    integer i;

    // Register 100MHz clock (Period = 10ns)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test sequence
    initial begin
        // Load input image (Q6.10 format, e.g., 0400h = 1.0)
        $readmemh("e:/Vivado_projects/LENET_5_VERILOG/weights/input_img.mem", img_mem);
        
        // Initialize signals
        rst_n = 0;
        valid_in = 0;
        pixel_in = 0;
        
        // System Reset
        #100;
        rst_n = 1;
        #20;
        
        // Start streaming data into the Pipeline Line Buffer
        for (i = 0; i < 784; i = i + 1) begin
            valid_in = 1;
            pixel_in = img_mem[i];
            @(posedge clk);
        end
        
        // Wait for final pipeline processing cycles
        valid_in = 0;
        pixel_in = 0;
        #500;
        
        $display("=========== SIMULATION COMPLETED ===========");
        $display("Please open Behavioral Simulation in Vivado to see the Waveform!");
        $stop;
    end

    // Monitor output results for verification
    // When valid_out is asserted, the system has produced a valid convolution pixel.
    integer out_count = 0;
    always @(posedge clk) begin
        if (valid_out) begin
            // Display first few values to confirm calculation
            if (out_count < 10) begin
                $display("Time %t | Valid Pixel %0d | Channel 0: %h | Channel 1: %h | Channel 2: %h", 
                          $time, out_count, conv_out_0, conv_out_1, conv_out_2);
            end
            out_count = out_count + 1;
        end
    end

endmodule
