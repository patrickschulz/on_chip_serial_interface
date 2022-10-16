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
// this means that !WITH THE CURRENT START SEQUENCE! the longest legal consecutive
// sequence of ones is DATA_LEN + 1
// the number of reset bits must be the *next* power of two
// (e.g. if DATA_LEN + 1 is 4, the number of reset bits must be 8!)
// the following expression calculates this by adding one more (+2)
// FIXME: for a very small DATA_LEN, the command length has to be considered
// as well, as the command register needs to be flushed during the reset
// this is important for the interfacing circuits
`define RESET_LEN ($clog2(`DATA_LEN + 2) + 1)
`define RESET_NUMBITS 2 ** `RESET_LEN

// derived defines
`define BIT_COUNT_LEN $clog2(`DATA_LEN + 1)
