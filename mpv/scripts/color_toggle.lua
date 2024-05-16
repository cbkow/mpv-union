-- Restarts MPV with different viewing LUTs
-- LUTs extracted with ociobake lut from ACES 1.2 and the OCIO config in Blender 4.1

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
local image_formats = { "png", "jpg", "jpeg", "bmp", "tif", "tiff", "tga", "exr" }
local video_formats = { "mov", "mp4", "avi", "webm", "mxf", "gif"}
local mp = require 'mp'

-- Current playback time
function format_time(seconds)
    if not seconds then return nil end
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local seconds = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end


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


-- restart
function restart_mpv_cmd(lut_path)
    local scale = mp.get_property_number("current-window-scale")
    local set_scale = "--window-scale=" .. tostring(scale)
    local file_path = mp.get_property("path")
    local filename = mp.get_property("filename")
    local time_pos = mp.get_property_number("time-pos")

    if not time_pos then
        print("No valid current playback position available.")
        return
    end

    local formatted_time = format_time(time_pos)

    if not formatted_time then
        local formatted_time = "00:00:00"
        return
    end

    local x, y = get_window_position()
    local playback_pos = "--start=" .. formatted_time
    local is_paused = mp.get_property_native("pause")
    local args = {}
    
    for _, format in ipairs(image_formats) do
        if filename:lower():match("%.(" .. format .. ")$") then
            local fps = mp.get_property_native("estimated-vf-fps")
            local mf_fps = "--mf-fps=" .. tostring(fps)
            if x and y then
                local offset_x, offset_y = calculate_proportional_offset(x, y)
                
                x = math.floor(x + offset_x)
                y = math.floor(y + offset_y)
                
                if is_paused == nil then
                    args.args = {"mpv", set_scale, '--geometry=' .. x .. ':' .. y, file_path, mf_fps, playback_pos, lut_path}
                elseif is_paused then
                    args.args = {"mpv", set_scale, '--geometry=' .. x .. ':' .. y, file_path, mf_fps, playback_pos, "--pause", lut_path}
                else
                    args.args = {"mpv", set_scale, '--geometry=' .. x .. ':' .. y, file_path, mf_fps, playback_pos, lut_path}
                end

            else
                if is_paused == nil then
                    args.args = {"mpv", set_scale, file_path, mf_fps, playback_pos, lut_path}
                elseif is_paused then
                    args.args = {"mpv", set_scale, file_path, mf_fps, playback_pos, "--pause", lut_path}
                else
                    args.args = {"mpv", set_scale, file_path, mf_fps, playback_pos, lut_path}
                end
            end
            
            mp.add_timeout(0.2, function()
                mp.command_native({"quit"})
            end)
        end
    end

    for _, format in ipairs(video_formats) do
        if filename:lower():match("%.(" .. format .. ")$") then
            if x and y then
                local offset_x, offset_y = calculate_proportional_offset(x, y)
                
                x = math.floor(x + offset_x)
                y = math.floor(y + offset_y)
                
                if is_paused == nil then
                    args.args = {"mpv", set_scale, '--geometry=' .. x .. ':' .. y, file_path, playback_pos, lut_path}
                elseif is_paused then
                    args.args = {"mpv", set_scale, '--geometry=' .. x .. ':' .. y, file_path, playback_pos, "--pause", lut_path}
                else
                    args.args = {"mpv", set_scale, '--geometry=' .. x .. ':' .. y, file_path, playback_pos, lut_path}
                end
            else
                if is_paused == nil then
                    args.args = {"mpv", set_scale, file_path, playback_pos, lut_path}
                elseif is_paused then
                    args.args = {"mpv", set_scale, file_path, playback_pos, "--pause", lut_path}
                else
                    args.args = {"mpv", set_scale, file_path, playback_pos, lut_path}
                end
            end

            mp.add_timeout(0.2, function()
                mp.command_native({"quit"})
            end)
        end
    end
    
    utils.subprocess_detached(args)
end

-- AGX
function restart_mpv_agx()
    local lut_path = "--lut=~~/luts/AGX_to_sRGB.cube"
    restart_mpv_cmd(lut_path)    
end


-- ACEScg 
function restart_mpv_aces()
    local lut_path = "--lut=~~/luts/ACEScg_to_sRGB.cube"
    restart_mpv_cmd(lut_path) 
end


-- sRGB
function restart_mpv_srgb()
    local lut_path = "--lut=~~/luts/rec709_to_sRGB.cube"
    restart_mpv_cmd(lut_path) 
end


-- Linear
function restart_mpv_linear()
    local lut_path = "--lut=~~/luts/Linear_to_sRGB.cube"
    restart_mpv_cmd(lut_path) 
end


-- No LUTs
function restart_mpv_normal()
    local lut_path = "--lut="
    restart_mpv_cmd(lut_path)
end

-- Bindings
mp.add_key_binding("", "restart_mpv_agx", restart_mpv_agx)
mp.add_key_binding("", "restart_mpv_aces", restart_mpv_aces)
mp.add_key_binding("", "restart_mpv_normal", restart_mpv_normal)
mp.add_key_binding("", "restart_mpv_srgb", restart_mpv_srgb)
mp.add_key_binding("", "restart_mpv_linear", restart_mpv_linear)