-- Loads an image sequence and asks user for playback fps.

--[[
Copyright (c) 2024 CBkow

Permission to use, copy, modify, and/or distribute this software
for any purpose with or without fee is hereby granted.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
]]

local utils = require 'mp.utils'
package.path = mp.command_native({"expand-path", "~~/scripts/?.lua;"})..package.path
local input = require "user-input-module"

-- DPI PS script
local ps_script_path = mp.command_native({"expand-path", "~~/powershell/GetDPI.ps1"})


-- Get DPI value
function run_ps_get_dpi(ps_script)
    local args = {
        'powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ps_script
    }
    local result = utils.subprocess({ args = args })
    
    if result.error or result.status ~= 0 then
        mp.msg.error("Failed to execute PowerShell script")
        return nil
    end
    
    local dpi = tonumber(result.stdout:match("AppliedDPI%s*:%s*(%d+)"))
    return dpi
end

-- Calculate proportional offset based on distance from top left corner
function calculate_proportional_offset(x, y)

    local dpi_scaling = run_ps_get_dpi(ps_script_path)
    if not dpi_scaling then
        mp.msg.error("Failed to get DPI scaling")
        return 0, 0
    end

    local dpi_convert_up = dpi_scaling / 96
    local dpi_get_before = math.floor(dpi_convert_up)
    local dpi_convert_down = dpi_convert_up - dpi_get_before

    -- Define base offsets
    local base_offset_x = 8 * dpi_convert_up
    local base_offset_y = 31 * dpi_convert_up
    local adjustment_factor = dpi_convert_down

    -- Calculate distance from top left corner (0,0)
    local distance_x = math.abs(x)
    local distance_y = math.abs(y)

    -- Calculate proportional offsets
    local proportional_offset_x = base_offset_x + (distance_x * adjustment_factor)
    local proportional_offset_y = base_offset_y + (distance_y * adjustment_factor)

    return proportional_offset_x, proportional_offset_y
end

-- Get the window position
function get_window_position()
    local script_path = mp.command_native({"expand-path", "~~/powershell/GetMPVPosition.ps1"})
    local args = {
        'powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', script_path
    }

    local result = utils.subprocess({ args = args })

    if result.error or result.status ~= 0 then
        mp.msg.error("Failed to execute PowerShell script")
        return nil, nil
    end
    
    local x, y = result.stdout:match("(%d+),(%d+)")
    if not x or not y then
        mp.msg.error("Failed to parse window position")
        return nil, nil
    end

    return tonumber(x), tonumber(y)
end

local function playseq(fps)
    local filePath = tostring(mp.get_property("path"))
    local directory, fileNameWithExtension = filePath:match("(.-)([^\\/]-%.?([^%.\\/]*))$")
    local fileName, extension = fileNameWithExtension:match("(.+)%.(.+)")
    local fileNameWithoutNumericSequence = fileName:match("(.+)_[%d]+")
    local file_path = "mf://" .. directory .. fileNameWithoutNumericSequence .. "_*." .. extension
    local scale = mp.get_property_number("current-window-scale")
    local set_scale = "--window-scale=" .. tostring(scale)
    local set_fps = '--mf-fps=' .. tostring(fps)
    local x, y = get_window_position()
    local args = {}
    if x and y then
        local offset_x, offset_y = calculate_proportional_offset(x, y)
        
        x = math.floor(x + offset_x)
        y = math.floor(y + offset_y)
        args.args = {"mpv", '--geometry=' .. x .. ':' .. y, file_path, set_fps, set_scale, '--loop=inf'}
    else
        args.args = {"mpv", file_path, set_fps, set_scale, '--loop=inf'}
    end
    utils.subprocess_detached(args)
    mp.add_timeout(0.2, function()
        mp.command_native({"quit"})
    end)
end

local function loadseq()
    input.get_user_input(function(line, err)
        if not err then
            fps = line
            playseq(fps)
        else
            mp.osd_message("Canceled")
        end
    end, { request_text = "Enter the framerate (24, 25, 30, etc.):" })
end


mp.add_key_binding("", "loadseq", loadseq)