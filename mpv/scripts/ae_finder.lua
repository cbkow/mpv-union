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
local exif_path = mp.command_native({"expand-path", "~~/exiftool/exiftool.exe"})
local exif = exif_path:gsub("\\", "/")
local input = require "user-input-module"


local function getDirectoryPath(output)
  local dir, _ = utils.split_path(output)
  if not dir:match("\\$") then
      dir = dir .. "\\"
  end
  return dir
end


local function get_ae_cmd(output)
    input.get_user_input(function(line, err)
        if not err then
            if line == "1" then 
                local dir = getDirectoryPath(output)
                if package.config:sub(1,1) == '\\' then
                    os.execute(string.format('explorer /select,' .. output))
                else
                    os.execute(string.format('open -R "%s"', output))
                end
                if package.config:sub(1,1) == '\\' then
                    os.execute('echo ' .. output .. ' | clip')
                else
                    os.execute('echo ' .. output .. ' | pbcopy')
                end
            elseif line == "2" then 
                if package.config:sub(1,1) == '\\' then
                    os.execute(string.format('start "" "%s"', output))
                else
                    os.execute(string.format('open "%s"', output))
                end
                if package.config:sub(1,1) == '\\' then
                    os.execute('echo ' .. output .. ' | clip')
                else
                    os.execute('echo ' .. output .. ' | pbcopy')
                end
            elseif line == "3" then 
                if package.config:sub(1,1) == '\\' then
                    os.execute('echo ' .. output .. ' | clip')
                else
                    os.execute('echo ' .. output .. ' | pbcopy')
                end
            elseif line == "4" then 
                p.osd_message("Canceled")
            end
        else
            mp.osd_message("Canceled")
        end
    end, { request_text = "Project found:   [1. Show File]   [2. Open AE]   [3. Copy Path]   [4. Cancel]" })
end


function get_ae_project()
    local path = mp.get_property("path")

    local exif = {
        args = {exif, "-s", "-s", "-s", "-AeProjectLinkFullPath", path},
        capture_stdout = true,
        capture_stderr = true
    }

    local exif_run = utils.subprocess(exif)
    if exif_run and exif_run.status == 0 and exif_run.stdout and exif_run.stdout ~= "" then
        local output = exif_run.stdout:gsub("%s+$", "")
        if output ~= "" then
            mp.osd_message("AE project found: " .. output)
            get_ae_cmd(output)
        else
            mp.osd_message("AE project data not found.")
        end
    else
        mp.osd_message("Failed to retrieve AE project data.")
    end
end


mp.add_key_binding("", 'get_ae_project', get_ae_project)
