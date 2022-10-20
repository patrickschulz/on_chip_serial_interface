// command types to be received from the external controller
// after a command a zero stop bit is sent
// this ensures that the line is pulled down after a command
`define RESET_CMD         2'b00 // reset internal state
`define START_SEND_CMD    2'b01 // start transmission of saved data
`define START_RECEIVE_CMD 2'b10 // start receiving of data
`define UPDATE_CMD        2'b11 // update the shift registers output cells
`define CMD_LEN 2
