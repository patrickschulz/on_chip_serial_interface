// settings
`define DATA_LEN 8
`define START_LEN 3
`define START_BIT_PATTERN 3'b101

// constants (don't change)
`define CMD_LEN 3

// derived defines
`define BIT_COUNT_LEN $clog2(`DATA_LEN + 1)
