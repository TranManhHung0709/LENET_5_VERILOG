// Synchronous FIFO with First-Word Fall-Through (FWFT)
module sync_fifo_32x64 (
    input clk,
    input rst_n,
    input wr_en,
    input [63:0] wr_data,
    input rd_en,
    
    output [63:0] rd_data,
    output full,
    output empty
);

    // Buffer memory
    reg [63:0] mem [0:31];
    
    // Read and Write pointers
    reg [5:0] wr_ptr;
    reg [5:0] rd_ptr;
    
    // Status flags
    assign empty = (wr_ptr == rd_ptr);
    assign full = (wr_ptr[4:0] == rd_ptr[4:0]) && (wr_ptr[5] != rd_ptr[5]);
    
    // Write logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr[4:0]] <= wr_data;
            wr_ptr <= wr_ptr + 1;
        end
    end
    
    // Read logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 0;
        end else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1;
        end
    end
    
    // FWFT read data output
    assign rd_data = mem[rd_ptr[4:0]];

endmodule
