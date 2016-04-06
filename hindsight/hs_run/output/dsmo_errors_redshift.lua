-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

local ds = require "derived_stream"

local name = read_config("table_prefix") or "download_stats_errors"
local schema = {
--   column name , field type  , length , attributes , field name
    {"timestamp" , "TIMESTAMP" , nil    , "SORTKEY"  , "Timestamp"      },
    {"request"   , "VARCHAR"   , 256    , nil        , "Fields[request]"},
}

process_message, timer_event = ds.load_schema(name, schema)
