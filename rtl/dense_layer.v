// Generic Dense Layer (Fully Connected): Sequential architecture with 1 DSP (MAC)
module dense_layer #(
    parameter INPUT_SIZE  = 128,
    parameter OUTPUT_SIZE = 32,
    parameter WEIGHT_FILE = "weights/f1_weight.mem",
    parameter BIAS_FILE   = "weights/f1_bias.mem",
    parameter HAS_RELU    = 1
)(
    input  wire clk,
    input  wire rst_n,
    input  wire valid_in,
    input  wire signed [15:0] data_in,
    
    output reg valid_out,
    output reg signed [15:0] data_out,
    output reg done          // Pulse when all OUTPUT_SIZE neurons are computed
);

    // 1. Weight and Bias Memory (ROM)
    reg signed [15:0] weight [0:INPUT_SIZE*OUTPUT_SIZE-1];
    reg signed [15:0] bias   [0:OUTPUT_SIZE-1];
    
    initial begin
        $readmemh(WEIGHT_FILE, weight);
        $readmemh(BIAS_FILE,   bias);
    end

    // 2. Input Buffer to store the flattened input vector
    reg signed [15:0] input_buf [0:INPUT_SIZE-1];

    // 3. Finite State Machine (FSM)
    localparam S_IDLE    = 2'd0;  // Waiting for data
    localparam S_COLLECT = 2'd1;  // Collecting INPUT_SIZE values
    localparam S_CALC    = 2'd2;  // Multiply-Accumulate for one neuron
    localparam S_BIAS    = 2'd3;  // Add bias, Apply ReLU, and Output
    
    reg [1:0]  state;
    reg [7:0]  collect_cnt;   // Counter for collected inputs (max 128)
    reg [7:0]  input_idx;     // Counter for multiplication (max 128)
    reg [5:0]  neuron_idx;    // Counter for current output neuron (max 32)
    reg signed [31:0] acc;    // 32-bit accumulator to prevent overflow

    // 4. Single MAC Unit (1-DSP implementation)
    wire [15:0] weight_addr = input_idx * OUTPUT_SIZE + neuron_idx;
    wire signed [15:0] mul_a = input_buf[input_idx];
    wire signed [15:0] mul_b = weight[weight_addr];
    wire signed [15:0] mul_result;
    
    multiplier_q6_10 u_mac (.a(mul_a), .b(mul_b), .out(mul_result));

    // 5. Bias and ReLU Logic (Combinational)
    wire signed [31:0] acc_plus_bias = acc + {{16{bias[neuron_idx][15]}}, bias[neuron_idx]};
    wire signed [15:0] final_val     = acc_plus_bias[15:0];
    wire signed [15:0] relu_out      = (HAS_RELU && final_val[15]) ? 16'h0000 : final_val;

    // 6. Main Control Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= S_IDLE;
            collect_cnt <= 0;
            input_idx   <= 0;
            neuron_idx  <= 0;
            acc         <= 0;
            valid_out   <= 0;
            data_out    <= 0;
            done        <= 0;
        end else begin
            // Default: clear flags every cycle
            valid_out <= 0;
            done      <= 0;
            
            case (state)
                // --- IDLE: Wait for the first valid input ---
                S_IDLE: begin
                    if (valid_in) begin
                        input_buf[0] <= data_in;
                        collect_cnt  <= 1;
                        state        <= S_COLLECT;
                    end
                end
                
                // --- COLLECT: Fill the input buffer ---
                S_COLLECT: begin
                    if (valid_in) begin
                        input_buf[collect_cnt] <= data_in;
                        if (collect_cnt == INPUT_SIZE - 1) begin
                            // Buffer full; start computation
                            collect_cnt <= 0;
                            input_idx   <= 0;
                            neuron_idx  <= 0;
                            acc         <= 0;
                            state       <= S_CALC;
                        end else begin
                            collect_cnt <= collect_cnt + 1;
                        end
                    end
                end
                
                // --- CALC: Sequential Multiply-Accumulate ---
                S_CALC: begin
                    acc <= acc + {{16{mul_result[15]}}, mul_result};
                    if (input_idx == INPUT_SIZE - 1) begin
                        input_idx <= 0;
                        state     <= S_BIAS;
                    end else begin
                        input_idx <= input_idx + 1;
                    end
                end
                
                // --- BIAS: Finalize neuron result and output ---
                S_BIAS: begin
                    data_out  <= relu_out;
                    valid_out <= 1;
                    if (neuron_idx == OUTPUT_SIZE - 1) begin
                        // All output neurons computed
                        neuron_idx <= 0;
                        done       <= 1;
                        state      <= S_IDLE;
                    end else begin
                        // Move to next output neuron
                        neuron_idx <= neuron_idx + 1;
                        acc        <= 0;
                        state      <= S_CALC;
                    end
                end
            endcase
        end
    end

endmodule
