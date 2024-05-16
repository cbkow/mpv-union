-- Uses FFMPEG to compress videos to MP4
-- Provides a few LUT tranforms for common CG workflows

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
local expanded_home_path = mp.command_native({"expand-path", "~~home/"})
local normalized_home_path = expanded_home_path:gsub("\\", "/")
local fixC_homepath = normalized_home_path:gsub(":", "\\:")
local exif_path = mp.command_native({"expand-path", "~~/exiftool/exiftool.exe"})
local exif = exif_path:gsub("\\", "/")
local ffmpeg_path = mp.command_native({"expand-path", "~~/ffmpeg/ffmpeg.exe"})
local ffmpeg = ffmpeg_path:gsub("\\", "/")
local input = require "user-input-module"


local function getDirectoryPath(path)
    local dir, _ = utils.split_path(path)
    if not dir:match("\\$") then
        dir = dir .. "\\"
    end
    return dir
end

-- file name versioning
local function versionFileName(new_file_name)
    local versioned_name = new_file_name
    local version_count = 1
    while utils.file_info(versioned_name) do
        local name, ext = new_file_name:match("^(.+)(%..+)$")
        versioned_name = name .. "_" .. version_count .. ext
        version_count = version_count + 1
    end
    return versioned_name
end

local dir = ""

-- copy metdata
local function copy_metadata(file_path, versioned_file_name)
    mp.osd_message("Copying metadata")
    local exif_garbage_name = dir .. "AeProjectLinkFullPath"
    local args = {exif, "-TagsFromFile", file_path, "-AeProjectLinkFullPath>AeProjectLinkFullPath", "-overwrite_original", versioned_file_name}
    
    local result = mp.command_native({
        name = "subprocess",
        capture_stdout = true,
        capture_stderr = true,
        args = args
    })

    if result.status == 0 then
        mp.osd_message("Metadata copy finished")
        os.remove(exif_garbage_name)
        os.execute(string.format('start "" "%s"', dir))
    else
        mp.osd_message("Metadata copy failed")
    end
end

-- transcode video cmd
local function transcode_mp4_cmd(args, file_path, versioned_file_name)  
    local result = mp.command_native({
        name = "subprocess",
        capture_stdout = true,
        capture_stderr = true,
        args = args
    })
    
    if result.status == 0 then
        mp.osd_message("Transcoding finished")
        copy_metadata(file_path, versioned_file_name)
        versioned_file_name2 = string.gsub(versioned_file_name, "/", "\\")
        os.execute(string.format('explorer /select,"%s"', versioned_file_name2))
    else
        mp.osd_message("Transcoding failed")
    end
end

-- transcode img cmd
local function transcode_img_mp4_cmd(args, file_path, versioned_file_name)  
    local result = mp.command_native({
        name = "subprocess",
        capture_stdout = true,
        capture_stderr = true,
        args = args
    })
    
    if result.status == 0 then
        mp.osd_message("Transcoding finished")
        versioned_file_name2 = string.gsub(versioned_file_name, "/", "\\")
        os.execute(string.format('explorer /select,"%s"', versioned_file_name2))
    else
        mp.osd_message("Transcoding failed")
    end
end

-- transcoding file name
local function get_new_name()
    local file_path = mp.get_property("path")
    local file_name_no_ext = mp.get_property("filename/no-ext")
    dir = getDirectoryPath(file_path)
    local new_file_name = dir .. file_name_no_ext .. ".mp4"
    local versioned_file_name = versionFileName(new_file_name)
    return versioned_file_name
end

-- transcoding img options
local function transcode_img_options()
    local filePath = tostring(mp.get_property("path"))
    local directory, fileNameWithExtension = filePath:match("(.-)([^\\/]-%.?([^%.\\/]*))$")
    local clean_directory = string.gsub(directory, "mf://", "")
    local clean_directory = string.gsub(clean_directory, "\\", "/")
    local fileName, extension = fileNameWithExtension:match("(.+)%.(.+)")
    local fileNameWithoutNumericSequence = fileName:match("(.+)_[^_]*$")
    local length = #start_frame  

    if length == 1 then
        frame_ender = "_%01d."
    elseif length == 2 then
        frame_ender = "_%02d."
    elseif length == 3 then
        frame_ender = "_%03d."
    elseif length == 4 then
        frame_ender = "_%04d."
    elseif length == 5 then
        frame_ender = "_%05d."
    elseif length == 6 then
        frame_ender = "_%06d."
    elseif length == 7 then
        frame_ender = "_%07d."
    else
        frame_ender = "_%04d."
    end

    local file_path = clean_directory .. fileNameWithoutNumericSequence .. frame_ender .. extension
    local path = string.gsub(clean_directory, "[\\/]+$", "")
    local parent = path:match("(.+)[\\/].-$")
    local folder = path:match(".+[\\/](.-)$")
    local new_file_name = parent .. "/" .. fileNameWithoutNumericSequence .. ".mp4"
    return file_path, new_file_name, parent
end

-- img transcode lut
local function run_transcode_img_mp4_lut(captured_fps, start_frame, lut_path)
    mp.osd_message("Transcoding started")
    local file_path, new_file_name = transcode_img_options()
    local versioned_file_name = versionFileName(new_file_name)
    local args = {ffmpeg, "-framerate", captured_fps, "-start_number", start_frame, "-i", file_path, "-vf", lut_path, "-preset", "slow", "-g", "2", "-crf", "18", "-pix_fmt", "yuv420p", "-movflags", "write_colr+write_gama+faststart", "-color_trc", "2", "-color_primaries", "1", "-colorspace", "1", "-y", versioned_file_name}
    
    transcode_img_mp4_cmd(args, file_path, versioned_file_name)
end
-- img transcode lut
local function transcode_img_mp4_lut(lut_path)
    local fps = mp.get_property_native("estimated-vf-fps")
    fixed_fps = tostring(fps)
    input.get_user_input(function(line, err)
        if not err then
            captured_fps = line
            input.get_user_input(function(line2, err)
                if not err then
                    start_frame = line2
                    run_transcode_img_mp4_lut(captured_fps, start_frame, lut_path)
                else
                    start_frame = "0001"
                    run_transcode_img_mp4_lut(captured_fps, start_frame, lut_path)
                end
            end, { request_text = "Enter the first frame (1000, 0001, 000, 100, etc.):" })
        else
            captured_fps = fixed_fps
            input.get_user_input(function(line2, err)
                if not err then
                    start_frame = line2
                    run_transcode_img_mp4_lut(captured_fps, start_frame, lut_path)
                else
                    start_frame = "0001"
                    run_transcode_img_mp4_lut(captured_fps, start_frame, lut_path)
                end
            end, { request_text = "Enter the first frame (1000, 0001, 000, 100, etc.):" })
        end
    end, { request_text = "Enter the framerate (24, 25, 30, etc.):" })
end

-- transcoding Normal
local function transcode_mp4()
    mp.osd_message("Transcoding started")

    local file_path = mp.get_property("path")
    local versioned_file_name = get_new_name(versioned_file_name)
    local args = {ffmpeg, "-i", file_path, "-preset", "slow", "-g", "2", "-crf", "18", "-c:a", "aac", "-b:a", "192k", "-pix_fmt", "yuv420p", "-movflags", "write_colr+write_gama+faststart", "-color_trc", "2", "-color_primaries", "1", "-colorspace", "1", "-y", versioned_file_name}
    
    transcode_mp4_cmd(args, file_path, versioned_file_name)
end


local function run_transcode_img_mp4(captured_fps, start_frame)
    mp.osd_message("Transcoding started")
    local file_path, new_file_name = transcode_img_options()
    local versioned_file_name = versionFileName(new_file_name)
    local args = {ffmpeg, "-framerate", captured_fps, "-start_number", start_frame, "-i", file_path, "-preset", "slow", "-g", "2", "-crf", "18", "-pix_fmt", "yuv420p", "-movflags", "write_colr+write_gama+faststart", "-color_trc", "2", "-color_primaries", "1", "-colorspace", "1", "-y", versioned_file_name}
    
    transcode_img_mp4_cmd(args, file_path, versioned_file_name)
end

local function transcode_img_mp4()
    local fps = mp.get_property_native("estimated-vf-fps")
    fixed_fps = tostring(fps)
    input.get_user_input(function(line, err)
        if not err then
            captured_fps = line
            input.get_user_input(function(line2, err)
                if not err then
                    start_frame = line2
                    run_transcode_img_mp4(captured_fps, start_frame)
                else
                    start_frame = "0001"
                    run_transcode_img_mp4(captured_fps, start_frame)
                end
            end, { request_text = "Enter the first frame (1000, 0001, 000, 100, etc.):" })
        else
            captured_fps = fixed_fps
            input.get_user_input(function(line2, err)
                if not err then
                    start_frame = line2
                    run_transcode_img_mp4(captured_fps, start_frame)
                else
                    start_frame = "0001"
                    run_transcode_img_mp4(captured_fps, start_frame)
                end
            end, { request_text = "Enter the first frame (1000, 0001, 000, 100, etc.):" })
        end
    end, { request_text = "Enter the framerate (24, 25, 30, etc.):" })
end

local function transcode_mp4_aces()  
    mp.osd_message("Transcoding started")
    
    local file_path = mp.get_property("path")
    local versioned_file_name = get_new_name(versioned_file_name)
    local lut_path = "lut3d=file='" .. fixC_homepath .. "/luts/ACEScg_to_sRGB.cube'"
    local args = {ffmpeg, "-i", file_path, "-vf", lut_path, "-preset", "slow", "-g", "2", "-crf", "18", "-c:a", "aac", "-b:a", "192k", "-pix_fmt", "yuv420p", "-movflags", "write_colr+write_gama+faststart", "-color_trc", "1", "-color_primaries", "1", "-colorspace", "1", "-y", versioned_file_name}
    
    transcode_mp4_cmd(args, file_path, versioned_file_name)
end

local function transcode_img_mp4_aces()
    local lut_path = "lut3d=file='" .. fixC_homepath .. "/luts/ACEScg_to_sRGB.cube'"
    transcode_img_mp4_lut(lut_path)
end

local function transcode_mp4_aces_709() 
    mp.osd_message("Transcoding started")
    
    local file_path = mp.get_property("path")
    local versioned_file_name = get_new_name(versioned_file_name)
    local lut_path = "lut3d=file='" .. fixC_homepath .. "/luts/ACEScg_to_bt1886.cube'"
    local args = {ffmpeg, "-i", file_path, "-vf", lut_path, "-preset", "slow", "-g", "2", "-crf", "18", "-c:a", "aac", "-b:a", "192k", "-pix_fmt", "yuv420p", "-movflags", "write_colr+write_gama+faststart", "-color_trc", "2", "-color_primaries", "1", "-colorspace", "1", "-y", versioned_file_name}
    
    transcode_mp4_cmd(args, file_path, versioned_file_name)
end

local function transcode_img_mp4_aces_709()
    local lut_path = "lut3d=file='" .. fixC_homepath .. "/luts/ACEScg_to_bt1886.cube'"
    transcode_img_mp4_lut(lut_path)
end

local function transcode_mp4_agx()
    mp.osd_message("Transcoding started")
    
    local file_path = mp.get_property("path")
    local versioned_file_name = get_new_name(versioned_file_name)
    local lut_path = "lut3d=file='" .. fixC_homepath .. "/luts/AGX_to_sRGB.cube'"
    local args = {ffmpeg, "-i", file_path, "-vf", lut_path, "-preset", "slow", "-g", "2", "-crf", "18", "-c:a", "aac", "-b:a", "192k", "-pix_fmt", "yuv420p", "-movflags", "write_colr+write_gama+faststart", "-color_trc", "1", "-color_primaries", "1", "-colorspace", "1", "-y", versioned_file_name}
    
    transcode_mp4_cmd(args, file_path, versioned_file_name)
end

local function transcode_img_mp4_agx()
    local lut_path = "lut3d=file='" .. fixC_homepath .. "/luts/AGX_to_sRGB.cube'"
    transcode_img_mp4_lut(lut_path)
end

local function transcode_mp4_agx_709()
    mp.osd_message("Transcoding started")
    
    local file_path = mp.get_property("path")
    local versioned_file_name = get_new_name(versioned_file_name)
    local lut_path = "lut3d=file='" .. fixC_homepath .. "/luts/AGX_to_bt1886.cube'"
    local args = {ffmpeg, "-i", file_path, "-vf", lut_path, "-preset", "slow", "-g", "2", "-crf", "18", "-c:a", "aac", "-b:a", "192k", "-pix_fmt", "yuv420p", "-movflags", "write_colr+write_gama+faststart", "-color_trc", "2", "-color_primaries", "1", "-colorspace", "1", "-y", versioned_file_name}
    
    transcode_mp4_cmd(args, file_path, versioned_file_name)
end

local function transcode_img_mp4_agx_709()
    local lut_path = "lut3d=file='" .. fixC_homepath .. "/luts/AGX_to_bt1886.cube'"
    transcode_img_mp4_lut(lut_path)
end

local function transcode_mp4_srgb()
    mp.osd_message("Transcoding started")
    
    local file_path = mp.get_property("path")
    local versioned_file_name = get_new_name(versioned_file_name)
    local vf_extras = "zscale=transferin=bt709\\:transfer=iec61966-2-1\\:primariesin=709\\:primaries=709\\:w=0:h=0 ,"
    local lut_path = "lut3d=file='" .. fixC_homepath .. "/luts/rec709_to_sRGB.cube'"
    local args = {ffmpeg, "-i", file_path, "-vf", vf_extras, "-preset", "slow", "-g", "2", "-crf", "18", "-c:a", "aac", "-b:a", "192k", "-pix_fmt", "yuv420p", "-movflags", "write_colr+write_gama+faststart", "-color_trc", "1", "-color_primaries", "1", "-colorspace", "1", "-y", versioned_file_name}
    
    transcode_mp4_cmd(args, file_path, versioned_file_name)
end

local function transcode_img_mp4_srgb()
    local lut_path = "lut3d=file='" .. fixC_homepath .. "/luts/rec709_to_sRGB.cube'"
    transcode_img_mp4_lut(lut_path)
end

local function transcode_mp4_linear_srgb()
    mp.osd_message("Transcoding started")
    
    local file_path = mp.get_property("path")
    local versioned_file_name = get_new_name(versioned_file_name)
    local vf_extras = "zscale=transferin=bt709\\:transfer=iec61966-2-1\\:primariesin=709\\:primaries=709\\:w=0:h=0 ,"
    local lut_path = "lut3d=file='" .. fixC_homepath .. "/luts/Linear_to_sRGB.cube'"
    local args = {ffmpeg, "-i", file_path, "-vf", lut_path, "-preset", "slow", "-g", "2", "-crf", "18", "-c:a", "aac", "-b:a", "192k", "-pix_fmt", "yuv420p", "-movflags", "write_colr+write_gama+faststart", "-color_trc", "2", "-color_primaries", "1", "-colorspace", "1", "-y", versioned_file_name}
    
    transcode_mp4_cmd(args, file_path, versioned_file_name)
end

local function transcode_img_mp4_linear_srgb()
    local lut_path = "lut3d=file='" .. fixC_homepath .. "/luts/Linear_to_sRGB.cube'"
    transcode_img_mp4_lut(lut_path)
end

local function transcode_mp4_linear_709()
    mp.osd_message("Transcoding started")
    
    local file_path = mp.get_property("path")
    local versioned_file_name = get_new_name(versioned_file_name)
    local vf_extras = "zscale=transferin=bt709\\:transfer=iec61966-2-1\\:primariesin=709\\:primaries=709\\:w=0:h=0 ,"
    local lut_path = "lut3d=file='" .. fixC_homepath .. "/luts/Linear_to_Rec1886.cube'"
    local args = {ffmpeg, "-i", file_path, "-vf", lut_path, "-preset", "slow", "-g", "2", "-crf", "18", "-c:a", "aac", "-b:a", "192k", "-pix_fmt", "yuv420p", "-movflags", "write_colr+write_gama+faststart", "-color_trc", "2", "-color_primaries", "1", "-colorspace", "1", "-y", versioned_file_name}
    
    transcode_mp4_cmd(args, file_path, versioned_file_name)
end

local function transcode_img_mp4_linear_709()
    local lut_path = "lut3d=file='" .. fixC_homepath .. "/luts/Linear_to_Rec1886.cube'"
    transcode_img_mp4_lut(lut_path)
end

mp.add_key_binding("", "transcode_mp4", transcode_mp4)
mp.add_key_binding("", "transcode_img_mp4", transcode_img_mp4)
mp.add_key_binding("", "transcode_mp4_aces", transcode_mp4_aces)
mp.add_key_binding("", "transcode_img_mp4_aces", transcode_img_mp4_aces)
mp.add_key_binding("", "transcode_mp4_aces_709", transcode_mp4_aces_709)
mp.add_key_binding("", "transcode_img_mp4_aces_709", transcode_img_mp4_aces_709)
mp.add_key_binding("", "transcode_mp4_agx", transcode_mp4_agx)
mp.add_key_binding("", "transcode_img_mp4_agx", transcode_img_mp4_agx)
mp.add_key_binding("", "transcode_mp4_agx_709", transcode_mp4_agx_709)
mp.add_key_binding("", "transcode_img_mp4_agx_709", transcode_img_mp4_agx_709)
mp.add_key_binding("", "transcode_mp4_srgb", transcode_mp4_srgb)
mp.add_key_binding("", "transcode_img_mp4_srgb", transcode_img_mp4_srgb)
mp.add_key_binding("", "transcode_mp4_linear_srgb", transcode_mp4_linear_srgb)
mp.add_key_binding("", "transcode_img_mp4_linear_srgb", transcode_img_mp4_linear_srgb)
mp.add_key_binding("", "transcode_mp4_linear_709", transcode_mp4_linear_709)
mp.add_key_binding("", "transcode_img_mp4_linear_709", transcode_img_mp4_linear_709)
