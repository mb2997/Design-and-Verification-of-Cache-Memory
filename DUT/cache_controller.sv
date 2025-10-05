/*
Specification:
- Direct Mapped Cache
- Block size = 4 words (1 word = 4 bytes)
- Cache size = 1024 blocks
- Write-back scheme
*/

module cache_controller(clk,
                        rstn,
                        cpu_req_addr,
                        cpu_req_datain,
                        cpu_req_dataout,
                        cpu_req_rw,
                        cpu_req_valid,
                        cache_ready,
                        mem_req_addr,
                        mem_req_datain,
                        mem_req_dataout,
                        mem_req_rw,
                        mem_req_valid,
                        mem_req_ready,
                        );

    parameter IDLE = 2'b00;
    parameter COMPARE_TAG = 2'b01;
    parameter ALLOCATE = 2'b10;
    parameter WRITE_BACK = 2'b11;

    // IO SIGNALS
    // Global inputs
    input clk, rstn;

    // CPU Request to cache controller
    input [`ADDR_BITS-1:0] cpu_req_addr;
    input [`DATA_IN_BITS-1:0] cpu_req_datain;       // Writing to all words of cache line/block (4 words)
    output logic [`DATA_OUT_BITS-1:0] cpu_req_dataout;      // Reading only one word of cache line/block (1 words)
    input cpu_req_rw;
    input cpu_req_valid;
    
    // Main Memory Request from cache controller
    output logic [`ADDR_BITS-1:0] mem_req_addr;
    input [`DATA_IN_BITS-1:0] mem_req_datain;       // Writing to all words of cache line/block (4 words)
    output logic [`DATA_OUT_BITS-1:0] mem_req_dataout;      // Reading only one word of cache line/block (1 words)
    output logic mem_req_rw;
    output logic mem_req_valid;
    input mem_req_ready;

    // Cache ready
    output logic cache_ready, next_cache_ready;

    // LOCAL VARIABLES
    // Cache data memory and tag memory
    logic [`TAG_MEM_WIDTH-1:0] tag_memory [`CACHE_LINES-1:0];
    logic [`DATA_IN_BITS-1:0] data_memory [`CACHE_LINES-1:0];
    logic [`TAG_MEM_WIDTH-1:0] tag_memory_entry;
    logic [`DATA_IN_BITS-1:0] data_memory_entry;
    
    // Variables for address bit slicing
    logic [`TAG_BITS-1:0] cpu_addr_tag;
    logic [`INDEX_BITS-1:0] cpu_addr_index;
    logic [(`BYTE_OFFSET_BITS/2)-1:0] cpu_addr_blk_offset;
    logic [(`BYTE_OFFSET_BITS/2)-1:0] cpu_addr_byte_offset;

    // Other variables
    logic hit;
    logic [1:0] present_state, next_state;
    logic [`DATA_OUT_BITS-1:0] cpu_req_addr_reg, next_cpu_req_addr_reg;
    logic [`DATA_IN_BITS-1:0] cpu_req_datain_reg, next_cpu_req_datain_reg;
    logic cpu_req_rw_reg, next_cpu_req_rw_reg;
    logic tag_mem_en;
    logic valid_bit, dirty_bit;
    logic write_mem_from_cpu;
    logic write_mem_from_mem;
    logic [`DATA_OUT_BITS-1:0] next_cpu_req_dataout;
    logic [`ADDR_BITS-1:0] next_mem_req_addr;
    logic next_mem_req_rw;
    logic next_mem_req_valid;
    logic [`DATA_OUT_BITS-1:0] next_mem_req_dataout;      // Reading only one word of cache line/block (1 words)


    // CPU Address = Tag + Index + Block offset + Byte offset
    assign cpu_addr_tag = cpu_req_addr_reg [31:14];
    assign cpu_addr_index = cpu_req_addr_reg [13:4];
    assign cpu_addr_blk_offset = cpu_req_addr_reg [3:2];
    assign cpu_addr_byte_offset = cpu_req_addr_reg [1:0];

    // Memory entry fetch
    assign tag_memory_entry = tag_memory[cpu_addr_index];
    assign data_memory_entry = data_memory[cpu_addr_index];
    // hit = valid_bit == 1 && tag bits match done - need not to consider dirty bit for this process
    assign hit = tag_memory_entry[`TAG_MEM_WIDTH-1] && (cpu_addr_tag == tag_memory_entry[`TAG_MEM_WIDTH-3:0]);

    // Initialize tag and data memory
    initial begin
        $readmemh("tag_memory.mem", tag_memory);
    end
    
    initial begin
        $readmemh("data_memory.mem", data_memory);
    end

    always@(posedge clk or negedge rstn)
    begin
        if(!rstn)
        begin
            tag_memory[cpu_addr_index] <= tag_memory[cpu_addr_index];
            data_memory[cpu_addr_index] <= data_memory[cpu_addr_index];
            present_state <= IDLE;
            cpu_req_dataout <= 0;
            cpu_req_addr_reg <= 0;
            cpu_req_datain_reg <= 0;
            cpu_req_rw_reg <= 0;
            mem_req_addr <= 0;
            mem_req_rw <= 0;
            mem_req_valid <= 0;
            mem_req_dataout <= 0;
            cache_ready <= 0;
        end
        else
        begin
            tag_memory[cpu_addr_index] <= tag_mem_en ? ({valid_bit, dirty_bit, cpu_addr_tag}) : (tag_memory[cpu_addr_index]);
            data_memory[cpu_addr_index] <= write_mem_from_mem ? mem_req_datain : write_mem_from_cpu ? cpu_req_datain_reg : data_memory[cpu_addr_index];
            present_state <= next_state;
            cpu_req_dataout <= next_cpu_req_dataout;
            cache_ready <= next_cache_ready;
            mem_req_addr <= next_mem_req_addr;
	        mem_req_rw <= next_mem_req_rw;
	        mem_req_valid <= next_mem_req_valid;
	        mem_req_dataout <= next_mem_req_dataout;
	        cpu_req_addr_reg <= next_cpu_req_addr_reg;
	        cpu_req_datain_reg <= next_cpu_req_datain_reg;
	        cpu_req_rw_reg <= next_cpu_req_rw_reg;
        end
    end



endmodule