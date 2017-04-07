-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

--[[
Output a Heka message for download-stats redshift analysis

*Example Heka Configuration*

.. code-block:: ini

    [FIXME]

--]]

require 'string'
require 'table'

local l = require "lpeg"
local sep = l.P"/"
local elem = l.C((1 - sep)^0)
local grammar = l.Ct(elem * (sep * elem)^0)

-- ripped from extract_telemetry_dimensions.lua
-- telemetry messages should not contain duplicate keys so this function
-- replaces/removes the first key that exists or adds a new key to the end
local function update_field(fields, name, value)
    if value ~= nil then value = {name = name, value = value} end

    for i,v in ipairs(fields) do
        if name == v.name then
            if value then
                fields[i] = value
            else
                table.remove(fields, i)
            end
            return
        end
    end

    if value then fields[#fields + 1] = value end
end

local function find_field(fields, name)
    for i,v in ipairs(fields) do
        if name == v.name then return v end
    end
end

function process_message()
    local raw = read_message("raw")
    local ok, msg = pcall(decode_message, raw)
    if not ok then return -1, msg end

    if type(msg.Fields) ~= "table" then return -1, "missing Fields" end
    local request = find_field(msg.Fields, "request")
    if type(request.value[1]) ~= "string" then return -1, "request not a string" end

    -- http://download-stats.mozilla.org stripped off by nginx decoder
    fields = grammar:match(request.value[1]:match("GET /(.*) HTTP/%d+.%d+") or "")
    if not fields or fields[1] ~= "stub" or (fields[2] ~= "v6" and fields[2] ~= "v7") then
        update_field(msg.Fields, "error", true)

        local ok, err = pcall(inject_message, msg)
        if not ok then
            return -1, err
        end

        return 0
    end

    -- [Build channel]/
    update_field(msg.Fields, "build_channel",  fields[3])
    -- [Update channel]/
    update_field(msg.Fields, "update_channel", fields[4])
    -- [Locale]/
    update_field(msg.Fields, "locale",         fields[5])
    -- [64bit build?]/
    update_field(msg.Fields, "64bit_build",    fields[6] == "1")
    -- [64bit OS?]/
    update_field(msg.Fields, "64bit_os",       fields[7] == "1")
    -- [Windows major version]/
    -- [Windows minor version]/
    -- [Windows build number]/
    local maj, min, build = fields[8], fields[9], fields[10]
    if not (maj and min and build) then return -1 end
    local v = string.format("%s.%s.%s", maj, min, build)
    update_field(msg.Fields, "os_version", v)
    -- [Windows service pack level]/
    update_field(msg.Fields, "service_pack", fields[11])
    -- [OS is Windows Server?]/
    update_field(msg.Fields, "server_os",    fields[12] == "1")
    -- [Installer exit code]/ (footnote [1])
    local exit_code = tonumber(fields[13])
    update_field(msg.Fields, "succeeded",          exit_code == 0)
    update_field(msg.Fields, "download_cancelled", exit_code == 10)
    update_field(msg.Fields, "out_of_retries",     exit_code == 11)
    update_field(msg.Fields, "file_error",         exit_code == 20)
    update_field(msg.Fields, "sig_not_trusted",    exit_code == 21 or exit_code == 23)
    update_field(msg.Fields, "sig_unexpected",     exit_code == 22 or exit_code == 23)
    update_field(msg.Fields, "install_timeout",    exit_code == 30)
    -- [Launch code]/ (footnote [2])
    local launch_code = tonumber(fields[14])
    update_field(msg.Fields, "new_launched", launch_code == 2)
    update_field(msg.Fields, "old_running", launch_code == 1)
    -- [Download retry count]/ (0 if first try succeeded)
    update_field(msg.Fields, "download_retries",    tonumber(fields[15]))
    -- [Downloaded bytes]/
    update_field(msg.Fields, "bytes_downloaded",    tonumber(fields[16]))
    -- [Download file size]/
    update_field(msg.Fields, "download_size",       tonumber(fields[17]))
    -- [Seconds spent in the intro phase]/
    update_field(msg.Fields, "intro_time",          tonumber(fields[18]))
    -- [Seconds spent in the options phase]/
    update_field(msg.Fields, "options_time",        tonumber(fields[19]))
    -- [Seconds spent in download phase]/
    update_field(msg.Fields, "download_phase_time", tonumber(fields[20]))
    -- [Seconds spent for last download attempt]/
    update_field(msg.Fields, "download_time",       tonumber(fields[21]))
    -- [Seconds to first byte for first download attempt]/
    update_field(msg.Fields, "download_latency",    tonumber(fields[22]))
    -- [Seconds spent in pre-install phase]/
    update_field(msg.Fields, "preinstall_time",     tonumber(fields[23]))
    -- [Seconds spent in install phase]/
    update_field(msg.Fields, "install_time",        tonumber(fields[24]))
    -- [Seconds spent in finish phase]/
    update_field(msg.Fields, "finish_time",         tonumber(fields[25]))
    -- [Initial install requirements code]/ (footnote [3])
    local iirc = tonumber(fields[26])
    update_field(msg.Fields, "disk_space_error", iirc == 1)
    update_field(msg.Fields, "no_write_access", iirc == 2)
    -- [Opened the download page for the full installer?]/
    update_field(msg.Fields, "manual_download",               fields[27] == "1")
    -- [Did a Firefox profile directory already exist before this installation?]/
    update_field(msg.Fields, "had_old_install",               fields[28] == "1")
    -- [Version of an existing Firefox that this install is replacing]/
    update_field(msg.Fields, "old_version",                   fields[29])
    -- [BuildID of an existing Firefox that this install is replacing]/
    update_field(msg.Fields, "old_build_id",                  fields[30])
    -- [Firefox Version being installed]/ (0 if failed install)
    update_field(msg.Fields, "version",                       fields[31])
    -- [Firefox BuildID being installed]/ (0 if failed install)
    update_field(msg.Fields, "build_id",                      fields[32])
    -- [Using default install path?]/
    update_field(msg.Fields, "default_path",                  fields[33] == "1")
    -- [Does user have admin access?]/
    update_field(msg.Fields, "admin_user",                    fields[34] == "1")
    -- [Default browser status code]/ (footnote [4])
    local status_code = tonumber(fields[35])
    update_field(msg.Fields, "new_default", status_code == 1)
    update_field(msg.Fields, "old_default", status_code == 2)
    -- [Default browser setting code]/ (footnote [5])
    local setting_code = tonumber(fields[36])
    update_field(msg.Fields, "set_default", setting_code == 2)
    -- [IP address of the download server that was used]
    update_field(msg.Fields, "download_ip",                   fields[37])

    -- [Attribution data]/ (only in v7)
    if fields[2] == "v7" then
      update_field(msg.Fields, "attribution", fields[38])
    end

    -- remove the original request
    update_field(msg.Fields, "request", nil)

    -- explicitly mark error field as false
    update_field(msg.Fields, "error", false)

    local ok, err = pcall(inject_message, msg)
    if not ok then
        return -1, err
    end

    return 0
end

function timer_event(ns)
    -- no op
end
