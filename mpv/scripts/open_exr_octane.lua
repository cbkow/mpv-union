-- Extracts a layer from an EXR seqeunce and dumps PNGs into a subfolder for preview
-- Reads C4D (and probably other DCCs) Octane formatted EXR channels

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
package.path = mp.command_native({"expand-path", "~~/scripts/?.lua;"}) .. package.path
local input = require "user-input-module"

-- Figure out the sequence frame index
function format_digit_count(file_path)
    local _, _, digits = string.find(file_path, "_(%d+)$")
    local num_digits = digits and #digits or 0
    return string.format("%%0%dd", num_digits)
end

-- Count the exr files in directory
function count_exr_files(directory)
    local count = 0
    local p = io.popen('dir "' .. directory .. '" /b')
    for file in p:lines() do
        if file:match("%.exr$") then
            count = count + 1
        end
    end
    p:close()
    return count
end

-- Create a directory for preview images
function capture_command_output(command)
    local full_command = 'start cmd /c "' .. command .. ' 2>&1"'
    local f = io.popen(full_command)
    local result = f:read("*a")
    f:close()
    return result
end

-- Play the sequence
function loadseq(directory, filtered_channel_name, fileNameWithoutNumericSequence, send_end)
    input.get_user_input(function(line2, err)

        if not err then
            local fps = line2
            local play_file_path = 'mf://' .. directory .. 'z_' .. filtered_channel_name .. '_' .. fileNameWithoutNumericSequence .. '/' .. filtered_channel_name .. '_' .. fileNameWithoutNumericSequence .. '_*' .. send_end
            play_file_path = play_file_path:gsub("\\", "/")
            local set_fps = '--mf-fps=' .. tostring(fps)
            local args = {"mpv", play_file_path, set_fps, "--loop=inf", "--lut="}
            utils.subprocess_detached({args = args})
            mp.add_timeout(0.2, function()
                mp.command_native({"quit"})
            end)
        else
            mp.osd_message("Canceled")
        end

    end, {request_text = "Enter the framerate (24, 25, 30, etc.):"})
end

-- Parse EXR layers channels and hide Cryptomattes
function parse_channels(output)
    local channels = {}
    for line in output:gmatch("[^\r\n]+") do
        local channel_list = line:match("%s*channel list:%s*(.*)")

        if channel_list then
            for channel in channel_list:gmatch("[^,]+") do
                local base_name = channel:match("([^%.]+)"):gsub("^%s*(.-)%s*$", "%1")
                if base_name and not (base_name == "R" or base_name == "G" or base_name == "B" or base_name:match("^Crypt")) then
                    print("Base Name: " .. base_name)
                    channels[base_name] = {
                        original_name = channel
                    }
                end
            end
        end
    end
    return channels
end


-- Use oiio to find layer channels
function os.capture(cmd, raw)
    local f = assert(io.popen(cmd, 'r'))
    local s = assert(f:read('*a'))
    f:close()

    if raw then return s end
    s = string.gsub(s, '^%s+', '')
    s = string.gsub(s, '%s+$', '')
    s = string.gsub(s, '[\n\r]+', ' ')
    return s

end

-- EXR proccess prep
function list_exr_channels(s_ocio, ocio_colorspace, ocio_display, ocio_view, ocio_config, expanded_home_path, normalized_home_path)
    local file_path = mp.get_property("path")

    if file_path:match("%.exr$") then
        local oiio_path = normalized_home_path .. "/oiio/oiiotool.exe"
        local command = oiio_path .. " --info -v \"" .. file_path .. "\""
        local output = os.capture(command, true)
        local channels = parse_channels(output)
        local channel_list_str = "Available Channels:\n"
        local channel_table = {}
        local index = 1

        for channel in pairs(channels) do
            channel_list_str = channel_list_str .. index .. ": " .. channel .. "\n"
            channel_table[index] = channel
            index = index + 1
        end

        input.get_user_input(function(line)
            local choice = tonumber(line)
            if choice and channel_table[choice] then
                local selected_channel_name = channel_table[choice]
                local filtered_channel_name = selected_channel_name:match("([^%.]+)")
                mp.osd_message(filtered_channel_name .. " extraction started.")
                local channel_name_view = filtered_channel_name
                local orig_path = tostring(file_path)
                local directory, fileNameWithExtension = orig_path:match("(.-)([^\\/]-%.?([^%.\\/]*))$")
                local fileName, extension = fileNameWithExtension:match("(.+)%.(.+)")
                local fileNameWithoutNumericSequence = fileName:match("(.+)_[%d]+")
                local formatted_fileName = format_digit_count(fileName)
                local output = os.capture(oiio_path .. ' --info -v "' .. file_path .. '"', true)
                local has_alpha_channel = output:match(filtered_channel_name .. "%.A") ~= nil
                local exr_count = count_exr_files(directory)
                local count_str = "_1-" .. tostring(exr_count)
                local in_path = directory .. fileNameWithoutNumericSequence .. count_str .. formatted_fileName .. "." .. extension
                local filtered_channel_name = filtered_channel_name:gsub(" ", "_")
                local new_channel_dir = directory .. "z_" .. filtered_channel_name .. "_" .. fileNameWithoutNumericSequence
                local mk_command = string.format('mkdir "%s"', new_channel_dir)
                
                capture_command_output(mk_command)
                local out_path = new_channel_dir .. "\\" .. filtered_channel_name .. "_" .. fileNameWithoutNumericSequence .. count_str .. formatted_fileName
                if s_ocio == true then
                    output_selected_channel_lut(file_path, oiio_path, channel_name_view, filtered_channel_name, out_path, in_path, has_alpha_channel, fileNameWithoutNumericSequence, directory, ocio_config, ocio_colorspace, ocio_display, ocio_view)
                else
                    output_selected_channel(file_path, oiio_path, channel_name_view, filtered_channel_name, out_path, in_path, has_alpha_channel, fileNameWithoutNumericSequence, directory)
                end
            else
                mp.msg.warn("Invalid selection.")
                mp.osd_message("Invalid selection.", 5)
            end
        end, {request_text = "Select a channel by number:\n" .. channel_list_str})
    else
        mp.msg.warn("The current file is not an EXR file.")
    end
end

-- EXR processing - No color conversions
function output_selected_channel(file_path, oiio_path, channel_name_view, filtered_channel_name, out_path, in_path, has_alpha_channel, fileNameWithoutNumericSequence, directory)
   
    local command
    local send_end

    if has_alpha_channel then
        out_path = out_path .. ".png"
        send_end = ".png"
        command = string.format('%s -v -i "%s" --ch "%s.R,%s.G,%s.B,%s.A" --chnames "R=%s.R,G=%s.G,B=%s.B,A=%s.A" --quality 100 -d uint16 --resize 0x1080 -o "%s"', oiio_path, in_path, channel_name_view, channel_name_view, channel_name_view, channel_name_view, channel_name_view, channel_name_view, channel_name_view, channel_name_view, out_path)
    else
        out_path = out_path .. ".jpg"
        send_end = ".jpg"
        command = string.format('%s -v -i "%s" --ch "%s.R,%s.G,%s.B" --quality 100 --resize 0x1080 -o "%s"', oiio_path, in_path, channel_name_view, channel_name_view, channel_name_view, out_path)
    end

    capture_command_output(command)
    
    mp.msg.info("Output EXR created: " .. out_path)
    mp.osd_message("Created: " .. out_path, 5)

    loadseq(directory, filtered_channel_name, fileNameWithoutNumericSequence, send_end)
end

-- EXR processing - OCIO color conversions
function output_selected_channel_lut(file_path, oiio_path, channel_name_view, filtered_channel_name, out_path, in_path, has_alpha_channel, fileNameWithoutNumericSequence, directory, ocio_config, ocio_colorspace, ocio_display, ocio_view)
   
    local command
    local send_end

    if has_alpha_channel then
        out_path = out_path .. ".png"
        send_end = ".png"
        print(ocio_config)
        command = string.format('%s -v -i "%s" --ch "%s.R,%s.G,%s.B,%s.A" --chnames "R=%s.R,G=%s.G,B=%s.B,A=%s.A"  --colorconfig "%s" --iscolorspace "%s"  --ociodisplay "%s" "%s" --quality 100 -d uint16 --resize 0x1080 -o "%s"', oiio_path, in_path, channel_name_view, channel_name_view, channel_name_view, channel_name_view, channel_name_view, channel_name_view, channel_name_view, channel_name_view, ocio_config, ocio_colorspace, ocio_display, ocio_view, out_path)
    else
        out_path = out_path .. ".jpg"
        send_end = ".jpg"
        command = string.format('%s -v -i "%s" --ch "%s.R,%s.G,%s.B" --colorconfig "%s" --iscolorspace "%s"  --ociodisplay "%s" "%s" --quality 100 --resize 0x1080 -o "%s"', oiio_path, in_path, channel_name_view, channel_name_view, channel_name_view, ocio_config, ocio_colorspace, ocio_display, ocio_view, out_path)
    end

    capture_command_output(command)
    
    mp.msg.info("Output EXR created: " .. out_path)
    mp.osd_message("Created: " .. out_path, 5)

    loadseq(directory, filtered_channel_name, fileNameWithoutNumericSequence, send_end)
end

-- Command formats
function exr_breakup_octane_normal()
    local is_ocio = false
    local expanded_home_path = mp.command_native({"expand-path", "~~home/"})
    local normalized_home_path = expanded_home_path:gsub("\\", "/")
    local ocio_config =""
    local ocio_colorspace = ""
    local ocio_display = ""
    local ocio_view = ""
    list_exr_channels(is_ocio, ocio_colorspace, ocio_display, ocio_view, ocio_config, expanded_home_path, normalized_home_path)
end

function exr_breakup_octane_aces_srgb()
    local is_ocio = true
    local expanded_home_path = mp.command_native({"expand-path", "~~home/"})
    local normalized_home_path = expanded_home_path:gsub("\\", "/")
    local ocio_config = normalized_home_path .. "/luts/ACES/config.ocio"
    local ocio_colorspace = "ACES - ACEScg"
    local ocio_display = "ACES"
    local ocio_view = "sRGB"
    list_exr_channels(is_ocio, ocio_colorspace, ocio_display, ocio_view, ocio_config, expanded_home_path, normalized_home_path)
end

function exr_breakup_octane_aces_r709()
    local is_ocio = true
    local expanded_home_path = mp.command_native({"expand-path", "~~home/"})
    local normalized_home_path = expanded_home_path:gsub("\\", "/")
    local ocio_config = normalized_home_path .. "/luts/ACES/config.ocio"
    local ocio_colorspace = "ACES - ACEScg"
    local ocio_display = "ACES"
    local ocio_view = "Rec.709"
    list_exr_channels(is_ocio, ocio_colorspace, ocio_display, ocio_view, ocio_config, expanded_home_path, normalized_home_path)
end

function exr_breakup_octane_agx_srgb()
    local is_ocio = true
    local expanded_home_path = mp.command_native({"expand-path", "~~home/"})
    local normalized_home_path = expanded_home_path:gsub("\\", "/")
    local ocio_config = normalized_home_path .. "/luts/AGX/config.ocio"
    local ocio_colorspace = "Linear Rec.709"
    local ocio_display = "sRGB"
    local ocio_view = "AgX"
    list_exr_channels(is_ocio, ocio_colorspace, ocio_display, ocio_view, ocio_config, expanded_home_path, normalized_home_path)
end

function exr_breakup_octane_agx_r709()
    local is_ocio = true
    local expanded_home_path = mp.command_native({"expand-path", "~~home/"})
    local normalized_home_path = expanded_home_path:gsub("\\", "/")
    local ocio_config = normalized_home_path .. "/luts/AGX/config.ocio"
    local ocio_colorspace = "Linear Rec.709"
    local ocio_display = "Rec.1886"
    local ocio_view = "AgX"
    list_exr_channels(is_ocio, ocio_colorspace, ocio_display, ocio_view, ocio_config, expanded_home_path, normalized_home_path)
end

function exr_breakup_octane_linear_srgb()
    local is_ocio = true
    local expanded_home_path = mp.command_native({"expand-path", "~~home/"})
    local normalized_home_path = expanded_home_path:gsub("\\", "/")
    local ocio_config = normalized_home_path .. "/luts/AGX/config.ocio"
    local ocio_colorspace = "Linear Rec.709"
    local ocio_display = "sRGB"
    local ocio_view = "Standard"
    list_exr_channels(is_ocio, ocio_colorspace, ocio_display, ocio_view, ocio_config, expanded_home_path, normalized_home_path)
end

function exr_breakup_octane_linear_r709()
    local is_ocio = true
    local expanded_home_path = mp.command_native({"expand-path", "~~home/"})
    local normalized_home_path = expanded_home_path:gsub("\\", "/")
    local ocio_config = normalized_home_path .. "/luts/AGX/config.ocio"
    local ocio_colorspace = "Linear Rec.709"
    local ocio_display = "Rec.1886"
    local ocio_view = "Standard"
    list_exr_channels(is_ocio, ocio_colorspace, ocio_display, ocio_view, ocio_config, expanded_home_path, normalized_home_path)
end

-- Bindings
mp.add_key_binding("", "exr_breakup_octane_normal", exr_breakup_octane_normal)
mp.add_key_binding("", "exr_breakup_octane_aces_srgb", exr_breakup_octane_aces_srgb)
mp.add_key_binding("", "exr_breakup_octane_aces_r709", exr_breakup_octane_aces_r709)
mp.add_key_binding("", "exr_breakup_octane_agx_srgb", exr_breakup_octane_agx_srgb)
mp.add_key_binding("", "exr_breakup_octane_agx_r709", exr_breakup_octane_agx_r709)
mp.add_key_binding("", "exr_breakup_octane_linear_srgb", exr_breakup_octane_linear_srgb)
mp.add_key_binding("", "exr_breakup_octane_linear_r709", exr_breakup_octane_linear_r709)
