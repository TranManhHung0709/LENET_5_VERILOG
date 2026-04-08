`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: lenet5_tb
// Description: General Testbench for the complete LeNet-5 system.
// This TB feeds a 28x28 image into the pipeline and waits for the final prediction.
//////////////////////////////////////////////////////////////////////////////////

module lenet5_tb;

    reg clk;
    reg rst_n;
    reg valid_in;
    reg signed [15:0] pixel_in;

    wire [3:0] prediction;
    wire result_valid;

    // --- TOP MODULE INSTANTIATION ---
    lenet5_top u_top (
        .clk(clk), .rst_n(rst_n),
        .valid_in(valid_in), .pixel_in(pixel_in),
        .prediction(prediction), .result_valid(result_valid)
    );

    // --- INPUT IMAGE LOADING ---
    reg signed [15:0] img_mem [0:783]; // 28x28 = 784 pixels
    integer i;

    // 100MHz Global Clock (10ns period)
    initial begin clk = 0; forever #5 clk = ~clk; end

    initial begin
        $dumpfile("lenet5_sim.vcd");
        $dumpvars(0, lenet5_tb);
        
        $readmemh("e:/Vivado_projects/LENET_5_VERILOG/img/input_img.mem", img_mem);
        
        rst_n = 0; valid_in = 0; pixel_in = 0;
        #100;
        rst_n = 1; #20;

        $display("=============================================================");
        $display("       LENET-5 FPGA INFERENCE - FULL SYSTEM TEST");
        $display("=============================================================");
        $display("Feeding 28x28 image into pipeline...");
        
        // Scan 28x28 image (784 pixels)
        for (i = 0; i < 784; i = i + 1) begin
            @(posedge clk);
            #1;
            valid_in <= 1;
            pixel_in <= img_mem[i];
        end
        
        // Dummy cycle for pipeline flushing
        @(posedge clk); #1;
        valid_in <= 1; pixel_in <= 0;
        @(posedge clk); #1;
        valid_in <= 0; pixel_in <= 0;
        
        $display("Image feeding complete. Waiting for prediction...");
        
        // Wait for result or timeout after 500,000 ns
        fork
            begin
                wait(result_valid);
                #10;
            end
            begin
                #500000;
                $display("[ERROR] TIMEOUT! No prediction after 500,000 ns.");
            end
        join_any
        
        if (result_valid || prediction !== 4'bx) begin
            $display("=============================================================");
            $display("  >>> PREDICTION: The network says this is number [%0d] <<<", prediction);
            $display("=============================================================");
        end
        
        #100;
        $finish;
    end

    // --- PIPELINE MONITORING (Tracking outputs at each layer) ---
    integer c1_cnt = 0, p1_cnt = 0, c2_cnt = 0, p2_cnt = 0;
    integer f1_cnt = 0, f2_cnt = 0, out_cnt = 0;

    always @(posedge clk) begin
        if (u_top.c1_valid) c1_cnt = c1_cnt + 1;
        if (u_top.p1_valid) p1_cnt = p1_cnt + 1;
        if (u_top.c2_valid) c2_cnt = c2_cnt + 1;
        if (u_top.p2_valid) p2_cnt = p2_cnt + 1;
        if (u_top.f1_valid) f1_cnt = f1_cnt + 1;
        if (u_top.f2_valid) f2_cnt = f2_cnt + 1;
        if (u_top.out_valid) begin
            out_cnt = out_cnt + 1;
            $display("  Output Neuron %0d: %h (decimal: %0d)", 
                      out_cnt-1, u_top.out_data, $signed(u_top.out_data));
        end
        
        if (result_valid) begin
            $display("");
            $display("--- PIPELINE SUMMARY ---");
            $display("  Conv1:   %0d outputs (expected 576)", c1_cnt);
            $display("  Pool1:   %0d outputs (expected 144)", p1_cnt);
            $display("  Conv2:   %0d outputs (expected 64)",  c2_cnt);
            $display("  Pool2:   %0d outputs (expected 16)",  p2_cnt);
            $display("  Dense1:  %0d outputs (expected 32)",  f1_cnt);
            $display("  Dense2:  %0d outputs (expected 16)",  f2_cnt);
            $display("  Output:  %0d outputs (expected 10)",  out_cnt);
        end
    end

endmodule
