local toplevel = object.create("serial_interface")

pcell.push_overwrites("basic/mosfet", {
    actext = 100
})
pcell.push_overwrites("stdcells/base", {
    basepwidth = 500,
    basenwidth = 500,
    glength = 40,
    gspace = 90,
    sdwidth = 60,
    routingwidth = 84,
    routingspace = 84,
    powerwidth = 160,
    pnumtracks = 4,
    nnumtracks = 4,
    drawtopbotwelltaps = false
})

local ctrl = pcell.create_layout("serial_interface/serial_ctrl", "ctrl")
toplevel:add_child(ctrl, "ctrl")

pcell.pop_overwrites("basic/mosfet")
pcell.pop_overwrites("stdcells/base")

return toplevel
