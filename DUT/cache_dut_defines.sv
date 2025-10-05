`define BYTE_OFFSET_BITS 4 // 2-bits to select 1 word out of 4 in a line, 2-bits to select byte out of selected 1 word output data
`define INDEX_BITS 10
`define TAG_BITS 18
`define ADDR_BITS 32
`define DATA_OUT_BITS 32
`define DATA_IN_BITS (`DATA_OUT_BITS*`BYTE_OFFSET_BITS)
`define VALID_BITS 1
`define DIRTY_BITS 1
`define TAG_MEM_WIDTH (`TAG_BITS+`VALID_BITS+`DIRTY_BITS)
`define CACHE_LINES 1024