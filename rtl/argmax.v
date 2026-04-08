// Argmax Module: Finds the index of the maximum value
module argmax (
    input  wire clk,
    input  wire rst_n,
    input  wire valid_in,
    input  wire signed [15:0] data_in,
    input  wire done_in,
    
    output reg [3:0] prediction,
    output reg valid_out
);

    reg signed [15:0] max_val; // Register to store the current maximum value
    reg [3:0] max_idx;         // Register to store the current maximum index
    reg [3:0] cnt;             // Counter for the input window index

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            max_val    <= 16'h8000; // Initialize to smallest possible signed value
            max_idx    <= 0;
            cnt        <= 0;
            prediction <= 0;
            valid_out  <= 0;
        end else begin
            valid_out <= 0;
            
            if (done_in) begin
                // Final comparison when the window is complete
                if (valid_in && data_in > max_val)
                    prediction <= cnt;
                else
                    prediction <= max_idx;
                valid_out <= 1;
                
                // Reset for next window
                max_val <= 16'h8000;
                max_idx <= 0;
                cnt     <= 0;
            end else if (valid_in) begin
                // Sequential comparison
                if (data_in > max_val) begin
                    max_val <= data_in;
                    max_idx <= cnt;
                end
                cnt <= cnt + 1;
            end
        end
    end

endmodule
