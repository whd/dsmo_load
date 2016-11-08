-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

local ds = require "heka.derived_stream"

local name = read_config("table_prefix") or "download_stats"
local schema = {
--   column name           , field type  , length , attributes , field name
    {"timestamp"           , "TIMESTAMP" , nil    , "SORTKEY",   "Timestamp"                  },
    {"build_channel"       , "VARCHAR"   , 32     , nil,         "Fields[build_channel]"      },
    {"update_channel"      , "VARCHAR"   , 32     , nil,         "Fields[update_channel]"     },
    {"version"             , "VARCHAR"   , 32     , nil,         "Fields[version]"            },
    {"build_id"            , "VARCHAR"   , 32     , nil,         "Fields[build_id]"           },
    {"locale"              , "VARCHAR"   , 5      , nil,         "Fields[locale]"             },
    {"amd64_bit_build"     , "BOOLEAN"   , nil    , nil,         "Fields[64bit_build]"        },
    {"amd64bit_os"         , "BOOLEAN"   , nil    , nil,         "Fields[64bit_os]"           },
    {"os_version"          , "VARCHAR"   , 32     , nil,         "Fields[os_version]"         },
    {"service_pack"        , "VARCHAR"   , 16     , nil,         "Fields[service_pack]"       },
    {"server_os"           , "BOOLEAN"   , nil    , nil,         "Fields[server_os]"          },
    {"admin_user"          , "BOOLEAN"   , nil    , nil,         "Fields[admin_user]"         },
    {"default_path"        , "BOOLEAN"   , nil    , nil,         "Fields[default_path]"       },
    {"set_default"         , "BOOLEAN"   , nil    , nil,         "Fields[set_default]"        },
    {"new_default"         , "BOOLEAN"   , nil    , nil,         "Fields[new_default]"        },
    {"old_default"         , "BOOLEAN"   , nil    , nil,         "Fields[old_default]"        },
    {"had_old_install"     , "BOOLEAN"   , nil    , nil,         "Fields[had_old_install]"    },
    {"old_version"         , "VARCHAR"   , 32     , nil,         "Fields[old_version]"        },
    {"old_build_id"        , "VARCHAR"   , 32     , nil,         "Fields[old_build_id]"       },
    {"bytes_downloaded"    , "INTEGER"   , nil    , nil,         "Fields[bytes_downloaded]"   },
    {"download_size"       , "INTEGER"   , nil    , nil,         "Fields[download_size]"      },
    {"download_retries"    , "INTEGER"   , nil    , nil,         "Fields[download_retries]"   },
    {"download_time"       , "INTEGER"   , nil    , nil,         "Fields[download_time]"      },
    {"download_latency"    , "INTEGER"   , nil    , nil,         "Fields[download_latency]"   },
    {"download_ip"         , "VARCHAR"   , 40     , nil,         "Fields[download_ip]"        },
    {"manual_download"     , "BOOLEAN"   , nil    , nil,         "Fields[manual_download]"    },
    {"intro_time"          , "INTEGER"   , nil    , nil,         "Fields[intro_time]"         },
    {"options_time"        , "INTEGER"   , nil    , nil,         "Fields[options_time]"       },
    {"download_phase_time" , "INTEGER"   , nil    , nil,         "Fields[download_phase_time]"},
    {"preinstall_time"     , "INTEGER"   , nil    , nil,         "Fields[preinstall_time]"    },
    {"install_time"        , "INTEGER"   , nil    , nil,         "Fields[install_time]"       },
    {"finish_time"         , "INTEGER"   , nil    , nil,         "Fields[finish_time]"        },
    {"succeeded"           , "BOOLEAN"   , nil    , nil,         "Fields[succeeded]"          },
    {"disk_space_error"    , "BOOLEAN"   , nil    , nil,         "Fields[disk_space_error]"   },
    {"no_write_access"     , "BOOLEAN"   , nil    , nil,         "Fields[no_write_access]"    },
    {"download_cancelled"  , "BOOLEAN"   , nil    , nil,         "Fields[download_cancelled]" },
    {"out_of_retries"      , "BOOLEAN"   , nil    , nil,         "Fields[out_of_retries]"     },
    {"file_error"          , "BOOLEAN"   , nil    , nil,         "Fields[file_error]"         },
    {"sig_not_trusted"     , "BOOLEAN"   , nil    , nil,         "Fields[sig_not_trusted]"    },
    {"sig_unexpected"      , "BOOLEAN"   , nil    , nil,         "Fields[sig_unexpected]"     },
    {"install_timeout"     , "BOOLEAN"   , nil    , nil,         "Fields[install_timeout]"    },
    {"new_launched"        , "BOOLEAN"   , nil    , nil,         "Fields[new_launched]"       },
    {"old_running"         , "BOOLEAN"   , nil    , nil,         "Fields[old_running]"        },
}

process_message, timer_event = ds.load_schema(name, schema)
