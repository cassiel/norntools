-- -*- lua-indent-level: 4; -*-
-- Unit testing.

local lu = require "luaunit"
local inspect = require "inspect"

local midi_ports = require "endpoints.lib.midi-ports"

test_Start = { }

function test_Start.testStart()
    lu.assertEquals(1, 1)
    lu.assertEquals({1, 2}, {1, 2})
    lu.assertEquals({A=1, B=2}, {B=2, A=1})
end

test_Endpoint = { }

function test_Endpoint:setUp()
    self.log = { }
    local log = self.log

    --[[
        Mock out the MIDI library:
    ]]
    midi = { }

    --[[
        All remembered devices. It's not clear that these
        values are ever examined in user code - we just
        do a `midi.connect()` based on index.
    ]]
    midi.vports = { "...", "...", "..." }

    function midi.connect(i)
        return {name="midi.connected(" .. i .. ")"}
    end

    util = { }

    function util.trim_string_to_width(str, w)
        lu.assertNotNil(str)
        return str
    end

    params = { }

    -- TODO: in the docs this is id * label.
    function params:add_separator(header)
        table.insert(log, "add_separator " .. header)
    end

    function params:add_option(id, name, options, default)
        table.insert(log, "add_option " .. id .. " " .. name .. " " .. inspect.inspect(options) .. " " .. default)
    end

    function params:set_action(id, callback)
        table.insert(log, "set_action " .. id)
    end
end

function test_Endpoint:tearDown()
end

function test_Endpoint:testGo()
    local result = midi_ports.setup("TestApp", {
        port_a = {
            name="Port A",
            event=function(x)
                table.insert(self.log, "event.A")
            end
        },
        port_z = {
            name="Port Z",
            event=function(x)
                table.insert(self.log, "event.Z")
            end
        },
        port_b = {
            name="Port B",
            event=function(x)
                table.insert(self.log, "event.B")
            end
        }
    })

    -- Here we're expecting user ports in order - we need to
    -- do an ordering somewhere:
    lu.assertEquals(
        self.log,
        {
            "add_separator TestApp",
            'add_option port_a Port A { "port 1: midi.connected(1)", "port 2: midi.connected(2)", "port 3: midi.connected(3)" } 1',
            "set_action port_a",
            'add_option port_b Port B { "port 1: midi.connected(1)", "port 2: midi.connected(2)", "port 3: midi.connected(3)" } 2',
            "set_action port_b",
            'add_option port_z Port Z { "port 1: midi.connected(1)", "port 2: midi.connected(2)", "port 3: midi.connected(3)" } 3',
            "set_action port_z"
        }
    )
    lu.assertEquals(result, {port_a=1, port_b=2, port_z=3})
end

runner = lu.LuaUnit.new()
runner:runSuite("--pattern", ".*" .. "%." .. ".*", "--verbose", "--failure")
