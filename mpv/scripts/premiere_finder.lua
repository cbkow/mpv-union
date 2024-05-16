-- Uses Exiftool to extract Adobe Metadata

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
local exif_path = mp.command_native({"expand-path", "~~/exiftool/exiftool.exe"})
local exif = exif_path:gsub("\\", "/")


local function getPremDirectoryPath(output)
  local dir, _ = utils.split_path(output)
  if not dir:match("\\$") then
      dir = dir .. "\\"
  end
  return dir
end


local function get_premiere_cmd(output)
    input.get_user_input(function(line, err)
        if not err then
            local fixed_output = output:gsub("\\\\%?\\", "")
            if line == "1" then 
                local dir = getPremDirectoryPath(fixed_output)
                if package.config:sub(1,1) == '\\' then
                    os.execute(string.format('explorer /select,' .. fixed_output))
                else
                    os.execute(string.format('open -R "%s"', fixed_output))
                end
                if package.config:sub(1,1) == '\\' then
                    os.execute('echo ' .. fixed_output .. ' | clip')
                else
                    os.execute('echo ' .. fixed_output .. ' | pbcopy')
                end
            elseif line == "2" then 
                if package.config:sub(1,1) == '\\' then
                    os.execute(string.format('start "" "%s"', fixed_output))
                else
                    os.execute(string.format('open "%s"', fixed_output))
                end
                if package.config:sub(1,1) == '\\' then
                    os.execute('echo ' .. fixed_output .. ' | clip')
                else
                    os.execute('echo ' .. fixed_output .. ' | pbcopy')
                end
            elseif line == "3" then 
                if package.config:sub(1,1) == '\\' then
                    os.execute('echo ' .. fixed_output .. ' | clip')
                else
                    os.execute('echo ' .. fixed_output .. ' | pbcopy')
                end
            elseif line == "4" then 
                mp.osd_message("Canceled")
            end
        else
            mp.osd_message("Canceled")
        end
    end, { request_text = "Project found:   [1. Show File]   [2. Open AE]   [3. Copy Path]   [4. Cancel]" })
end


function get_premiere_project()
    local path = mp.get_property("path")

    local function run_exif(args)
        local exif = {
            args = args,
            capture_stdout = true,
            capture_stderr = true
        }
        return utils.subprocess(exif)
    end

    local exif_run = run_exif({exif, "-s", "-s", "-s", "-WindowsAtomUncProjectPath", path})
    if exif_run and exif_run.status == 0 and exif_run.stdout and exif_run.stdout ~= "" then
        local output = exif_run.stdout:gsub("%s+$", "")
        if output ~= "" then
            local fixed_output = output:gsub("\\\\%?\\", "")
            mp.osd_message("Premiere project found: " .. fixed_output)
            get_premiere_cmd(output)
            return
        end
    end


    local exifm_run = run_exif({exif, "-s", "-s", "-s", "-MacAtomPosixProjectPath", path})
    if exifm_run and exifm_run.status == 0 and exifm_run.stdout and exifm_run.stdout ~= "" then
        local output = exifm_run.stdout:gsub("%s+$", "")
        if output ~= "" then
            local fixed_output = output:gsub("\\\\%?\\", "")
            mp.osd_message("Premiere project found: " .. fixed_output)
            get_premiere_cmd(output)
        else
            mp.osd_message("Premiere project data not found.")
        end
    else
        mp.osd_message("Failed to retrieve Premiere project data.")
    end
end

mp.add_key_binding("Ctrl+a", 'get_premiere_project', get_premiere_project)
