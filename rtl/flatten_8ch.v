// Flatten Module: Converts 8 parallel channels to a serial data stream
module flatten_8ch (
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    input wire signed [15:0] ch0, ch1, ch2, ch3, ch4, ch5, ch6, ch7,
    
    output reg valid_out,
    output reg signed [15:0] data_out
);

    reg signed [15:0] buffer [0:7]; // Internal buffer to latch 8 channels
    reg [3:0] cnt;                  // Output counter
    reg busy;                       // Busy flag during serial output
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 0;
            data_out  <= 0;
            cnt       <= 0;
            busy      <= 0;
            for (i=0; i<8; i=i+1) begin
                buffer[i] <= 0;
            end
        end else begin
            if (valid_in && !busy) begin
                // Latch 8 channels into the buffer
                buffer[0] <= ch0; buffer[1] <= ch1;
                buffer[2] <= ch2; buffer[3] <= ch3;
                buffer[4] <= ch4; buffer[5] <= ch5;
                buffer[6] <= ch6; buffer[7] <= ch7;
                busy      <= 1;
                cnt       <= 0;
                valid_out <= 0;
            end else if (busy) begin
                // Output channels sequentially
                data_out  <= buffer[cnt];
                valid_out <= 1;
                if (cnt == 4'd7) begin
                    busy <= 0;
                end
                cnt <= cnt + 1;
            end else begin
                valid_out <= 0;
            end
        end
    end

endmodule
