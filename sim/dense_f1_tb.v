`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: dense_f1_tb
// Description: Testbench to verify the connection between Flatten 8ch and Dense Layer (f1).
// Simulates loading 16 sets of pixels (8 channels each) = 128 inputs.
//////////////////////////////////////////////////////////////////////////////////

module dense_f1_tb;

    reg clk;
    reg rst_n;
    reg valid_in;
    reg signed [15:0] ch0, ch1, ch2, ch3, ch4, ch5, ch6, ch7;

    wire flatten_valid;
    wire signed [15:0] flatten_data;
    
    wire f1_valid;
    wire signed [15:0] f1_out;
    wire f1_done;

    // --- 1. Interconnect: Flatten -> Dense F1 ---
    flatten_8ch u_flatten (
        .clk(clk), .rst_n(rst_n),
        .valid_in(valid_in),
        .ch0(ch0), .ch1(ch1), .ch2(ch2), .ch3(ch3),
        .ch4(ch4), .ch5(ch5), .ch6(ch6), .ch7(ch7),
        .valid_out(flatten_valid),
        .data_out(flatten_data)
    );

    dense_layer #(
        .INPUT_SIZE(128),
        .OUTPUT_SIZE(32),
        .WEIGHT_FILE("e:/Vivado_projects/LENET_5_VERILOG/weights/f1_weight.mem"),
        .BIAS_FILE("e:/Vivado_projects/LENET_5_VERILOG/weights/f1_bias.mem"),
        .HAS_RELU(1)
    ) u_dense_f1 (
        .clk(clk), .rst_n(rst_n),
        .valid_in(flatten_valid),
        .data_in(flatten_data),
        .valid_out(f1_valid),
        .data_out(f1_out),
        .done(f1_done)
    );

    // 100MHz Global Clock
    initial begin clk = 0; forever #5 clk = ~clk; end

    integer i;
    initial begin
        $dumpfile("dense_f1_sim.vcd");
        $dumpvars(0, dense_f1_tb);
        
        rst_n = 0; valid_in = 0;
        ch0=0; ch1=0; ch2=0; ch3=0; ch4=0; ch5=0; ch6=0; ch7=0;
        #100;
        rst_n = 1; #20;

        $display("======= STARTING DENSE F1 TEST =======");
        
        // Simulate 16 row flushes from Pool2 (8 channels each)
        for (i = 0; i < 16; i = i + 1) begin
            @(posedge clk);
            #1; // Signal stabilization after clock edge
            valid_in <= 1;
            ch0 <= i*8 + 0; ch1 <= i*8 + 1; ch2 <= i*8 + 2; ch3 <= i*8 + 3;
            ch4 <= i*8 + 4; ch5 <= i*8 + 5; ch6 <= i*8 + 6; ch7 <= i*8 + 7;
            
            @(posedge clk);
            #1;
            valid_in <= 0;
            
            // Wait for Flatten module to push all 8 channels to Dense (approx 100ns)
            #100; 
        end

        $display("--- DATA COLLECTION FINISHED. STARTING CALCULATION... ---");
        
        // Wait for Dense layer to finish computing 32 neurons
        // (128 cycles per neuron -> Total ~4,100 cycles = 41,000 ns)
        wait(f1_done);
        #100;
        
        $display("======= DENSE F1 TEST COMPLETED =======");
        $finish;
    end

    // Output monitoring logic
    integer out_cnt = 0;
    always @(posedge clk) begin
        if (f1_valid) begin
            out_cnt = out_cnt + 1;
            $display("Time %0d ns | Neuron %02d Output: %h", $time, out_cnt-1, f1_out);
        end
    end

endmodule
