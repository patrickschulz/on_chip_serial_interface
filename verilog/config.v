// settings
`define DATA_LEN 8
`define START_LEN 3
`define START_BIT_PATTERN 3'b101

// command types to be received from the external controller
// all commands end with a zero bit
// this ensures that the line is pulled down after a command
`define RESET_CMD         3'b000 // reset internal state
`define START_SEND_CMD    3'b010 // start transmission of saved data
`define START_RECEIVE_CMD 3'b100 // start receiving of data
`define UPDATE_CMD        3'b110 // update the shift registers output cells
`define CMD_LEN 3

// derived defines
`define BIT_COUNT_LEN $clog2(`DATA_LEN + 1)
