// settings
`define DATA_LEN 8
`define START_LEN 3
`define START_BIT_PATTERN 3'b101

// command types to be received from the external controller
// after a command a zero stop bit is sent
// this ensures that the line is pulled down after a command
`define RESET_CMD         2'b00 // reset internal state
`define START_SEND_CMD    2'b01 // start transmission of saved data
`define START_RECEIVE_CMD 2'b10 // start receiving of data
`define UPDATE_CMD        2'b11 // update the shift registers output cells
`define CMD_LEN 2

// the minimum number of consecutive ones for internal reset
// depends on the longest legal sequence of ones
// every command ends with a zero stop bit
// when 1...1 is sent as data, this data are surrounded by:
// START SEQUENCE (101) + stop bit (0) + 1...1 + high value of next start pattern
// !WITH THE CURRENT START SEQUENCE! this means that the longest legal consecutive
// sequence of ones is DATA_LEN + 1
// the number of reset bits must be twice this and a power of two
`define RESET_LEN $clog2(`DATA_LEN + 1) + 1
`define RESET_NUMBITS 2 ** `RESET_LEN

// derived defines
`define BIT_COUNT_LEN $clog2(`DATA_LEN + 1)
