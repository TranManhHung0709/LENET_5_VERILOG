`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: conv2_tb
// Description: Integration test for Image -> Conv1 -> Maxpool1 -> Conv2 pipeline.
// This testbench verifies data flow and counts synchronization outputs.
//////////////////////////////////////////////////////////////////////////////////

module conv2_tb;

    reg clk;
    reg rst_n;
    reg valid_in;
    reg signed [15:0] pixel_in;

    // --- LAYER 1: CONV1 ---
    wire c1_valid;
    wire signed [15:0] c1_out0, c1_out1, c1_out2, c1_out3;
    
    conv_layer_1 u_conv1 (
        .clk(clk), .rst_n(rst_n), .valid_in(valid_in), .pixel_in(pixel_in),
        .valid_out(c1_valid), .conv_out_0(c1_out0), .conv_out_1(c1_out1), .conv_out_2(c1_out2), .conv_out_3(c1_out3)
    );

    // --- LAYER 2: MAXPOOL1 ---
    wire p1_valid;
    wire signed [15:0] p1_out0, p1_out1, p1_out2, p1_out3;
    
    maxpool_layer_1 u_pool1 (
        .clk(clk), .rst_n(rst_n), .valid_in(c1_valid), 
        .in_ch0(c1_out0), .in_ch1(c1_out1), .in_ch2(c1_out2), .in_ch3(c1_out3),
        .valid_out(p1_valid), 
        .out_ch0(p1_out0), .out_ch1(p1_out1), .out_ch2(p1_out2), .out_ch3(p1_out3)
    );

    // --- LAYER 3: CONV2 (FSM with 200 MACs & FIFO) ---
    wire c2_valid;
    wire signed [15:0] c2_out0, c2_out1, c2_out2, c2_out3, c2_out4, c2_out5, c2_out6, c2_out7;
    
    conv_layer_2 u_conv2 (
        .clk(clk), .rst_n(rst_n), .valid_in(p1_valid),
        .pixel_in_0(p1_out0), .pixel_in_1(p1_out1), .pixel_in_2(p1_out2), .pixel_in_3(p1_out3),
        .valid_out(c2_valid),
        .conv_out_0(c2_out0), .conv_out_1(c2_out1), .conv_out_2(c2_out2), .conv_out_3(c2_out3),
        .conv_out_4(c2_out4), .conv_out_5(c2_out5), .conv_out_6(c2_out6), .conv_out_7(c2_out7)
    );

    // --- LOAD INPUT IMAGE ---
    reg signed [15:0] img_mem [0:783];
    integer i;

    initial begin
        clk = 0; forever #5 clk = ~clk; // 10ns period
    end

    initial begin
        $dumpfile("conv2_sim.vcd");
        $dumpvars(0, conv2_tb);
        
        $readmemh("e:/Vivado_projects/LENET_5_VERILOG/weights/input_img.mem", img_mem);
        
        rst_n = 0; valid_in = 0; pixel_in = 0;
        #100;
        rst_n = 1; #20;

        $display("=========== BOOTING INTEGRATION TEST (C1 -> P1 -> C2) ===========");
        
        // Image Scan
        for (i = 0; i < 784; i = i + 1) begin
            valid_in = 1;
            pixel_in = img_mem[i];
            @(posedge clk);
        end
        
        // Final pixel flushing (Due to Conv1 valid signal latency)
        valid_in = 1; pixel_in = 0; @(posedge clk);
        valid_in = 0; pixel_in = 0;
        
        // Conv2 FSM is sequential (5 cycles per pixel), requiring extended simulation time
        #50000;
        
        $display("--- SUMMARY ---");
        $display("C1 Count: %0d (Expected: 576)", c1_cnt);
        $display("P1 Count: %0d (Expected: 144)", p1_cnt);
        $display("C2 Count: %0d (Expected: 64)", c2_cnt);
        $display("=========== SIMULATION COMPLETED ===========");
        $finish;
    end

    // --- MONITOR COUNTERS ---
    integer c1_cnt = 0; integer p1_cnt = 0; integer c2_cnt = 0;
    always @(posedge clk) begin
        if (c1_valid) c1_cnt = c1_cnt + 1;
        if (p1_valid) p1_cnt = p1_cnt + 1;
        if (c2_valid) begin
            c2_cnt = c2_cnt + 1;
            // Display first 3 Conv2 outputs for verification
            if (c2_cnt <= 3) begin
                $display("Time %0d ns | Conv2 Output %0d | C0:%h  C1:%h  C2:%h  C3:%h  C4:%h  C5:%h  C6:%h  C7:%h", 
                          $time, c2_cnt, c2_out0, c2_out1, c2_out2, c2_out3, c2_out4, c2_out5, c2_out6, c2_out7);
            end
        end
    end

endmodule
