--Copyright 2021 The casbin Authors. All Rights Reserved.
--
--Licensed under the Apache License, Version 2.0 (the "License");
--you may not use this file except in compliance with the License.
--You may obtain a copy of the License at
--
--    http://www.apache.org/licenses/LICENSE-2.0
--
--Unless required by applicable law or agreed to in writing, software
--distributed under the License is distributed on an "AS IS" BASIS,
--WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--See the License for the specific language governing permissions and
--limitations under the License.

local Adapter = require("Adapter")
local sqlite3 = require("luasql.sqlite3")
local env  = sqlite3.sqlite3()

local sqlite3Adapter = {}
Adapter.__index = Adapter
setmetatable(sqlite3Adapter, Adapter)

local sql = [[
CREATE TABLE IF NOT EXISTS table_name (
    `id` INTEGER PRIMARY KEY AUTOINCREMENT ,
    `ptype` varchar(255) NOT NULL,
    `v0` varchar(255) DEFAULT NULL,
    `v1` varchar(255) DEFAULT NULL,
    `v2` varchar(255) DEFAULT NULL,
    `v3` varchar(255) DEFAULT NULL,
    `v4` varchar(255) DEFAULT NULL,
    `v5` varchar(255) DEFAULT NULL
    )
]]

function sqlite3Adapter:new(database, user, password)
    local o = {}
    self.__index = self
    setmetatable(o, self)
    o.tableName = "casbin_rule"
    local conn, err = env:connect(database, user, password)
    if err then
        error("Could not create connection to database, error:" .. err)
    end
    o.conn = conn
    sql = string.gsub(sql, "table_name", "casbin_rule")
    o.conn:execute(sql)
    return o
end

return sqlite3Adapter