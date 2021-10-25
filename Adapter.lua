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

local Adapter = require("src.persist.Adapter")
local Util = require("src.util.Util")

local _M = {}

-- Filter for filtered policies
local Filter = {
    ptype = "",
    v0 = "",
    v1 = "",
    v2 = "",
    v3 = "",
    v4 = "",
    v5 = ""
}

--[[
    * loadPolicy loads all policy rules from the storage.
]]
function _M:loadPolicy(model)
    local cursor, err = self.conn:execute("SELECT ptype, v0, v1, v2, v3, v4, v5 FROM " .. self.tableName)
    if err then
        return false, err
    end
    local row = cursor:fetch ({}, "n")

    while row do
        local line = Util.trim(table.concat(row, ", "))
        Adapter.loadPolicyLine(line, model)

        row = cursor:fetch ({}, "n")
    end
    cursor:close()
end

function _M:savePolicyLine(ptype, rule)
    local row = "'" .. ptype .. "'"
    for _, v in pairs(rule) do
        row = row .. ", '" .. v .. "'"
    end

    local cols = "ptype"
    for k = 0, #rule-1 do
        cols = cols .. ", " .. "v" .. tostring(k)
    end
    self.conn:execute("INSERT INTO " .. self.tableName .. "(" .. cols .. ") VALUES (" .. row .. ")")
end

--[[
    * savePolicy saves all policy rules to the storage.
]]
function _M:savePolicy(model)
    self.conn:execute("DELETE FROM " .. self.tableName)

    if model.model["p"] then
        for ptype, ast in pairs(model.model["p"]) do
            for _, rule in pairs(ast.policy) do
                self:savePolicyLine(ptype, rule)
            end
        end
    end

    if model.model["g"] then
        for ptype, ast in pairs(model.model["g"]) do
            for _, rule in pairs(ast.policy) do
                self:savePolicyLine(ptype, rule)
            end
        end
    end
end

--[[
    * addPolicy adds a policy rule to the storage.
]]
function _M:addPolicy(_, ptype, rule)
    return self:savePolicyLine(ptype, rule)
end

--[[
    * addPolicies adds policy rules to the storage.
]]
function _M:addPolicies(_, ptype, rules)
    local rows = ""
    local cols = "ptype"
    for k = 0, 5 do
        cols = cols .. ", " .. "v" .. tostring(k)
    end

    for _, rule in pairs(rules) do
        rows = rows .. "("
        local row = "'" .. ptype .. "'"
        for _, v in pairs(rule) do
            row = row .. ", '" .. v .. "'"
        end
        for k = #rule, 5 do
            row = row .. ", NULL"
        end

        rows = rows .. row .. "), "
    end

    if rules == "" then return true end

    rows = string.sub(rows, 1, -3)

    return self.conn:execute("INSERT INTO " .. self.tableName .. "(" .. cols .. ") VALUES " .. rows .. "")
end

--[[
    * removePolicy removes a policy rule from the storage.
]]
function _M:removePolicy(_, ptype, rule)
    local condition = {"ptype = '" .. ptype .. "'"}

    for k=0, #rule-1 do
        local c = "v" .. tostring(k) .. " = '" .. rule[k+1] .. "'"
        table.insert(condition, c)
    end

    return self.conn:execute("DELETE FROM " .. self.tableName .. " WHERE " .. Util.trim(table.concat(condition, " AND ")))
end

--[[
    * removePolicies removes policy rules from the storage.
]]
function _M:removePolicies(_, ptype, rules)
    for _, rule in pairs(rules) do
        local _, err = self:removePolicy(_, ptype, rule)
        if err then
            return false, err
        end
    end

    return true
end

--[[
    * updatePolicy updates a policy rule from the storage
]]
function _M:updatePolicy(_, ptype, oldRule, newRule)
    local update = {"ptype = '" .. ptype .. "'"}

    for k=0, #newRule-1 do
        local c = "v" .. tostring(k) .. " = '" .. newRule[k+1] .. "'"
        table.insert(update, c)
    end

    local condition = {"ptype = '" .. ptype .. "'"}

    for k=0, #oldRule-1 do
        local c = "v" .. tostring(k) .. " = '" .. oldRule[k+1] .. "'"
        table.insert(condition, c)
    end

    return self.conn:execute("UPDATE " .. self.tableName .. " SET " .. Util.trim(table.concat(update, ", "))
    .. " WHERE " .. Util.trim(table.concat(condition, " AND ")))
end

--[[
    * updatePolicies updates policy rules from the storage
]]
function _M:updatePolicies(_, ptype, oldRules, newRules)
    if #oldRules == #newRules then
        for i = 1, #oldRules do
            local _, err = self:updatePolicy(_, ptype, oldRules[i], newRules[i])
            if err then
                return false, err
            end
        end
        return true
    end
    return false
end

function _M:updateFilteredPolicies(_, ptype, newRules, fieldIndex, fieldValues)
    return self:removeFilteredPolicy(_, ptype, fieldIndex, fieldValues) and self:addPolicies(_, ptype, newRules)

end


--[[
    * loadFilteredPolicy loads the policy rules that match the filter from the storage.
]]
function _M:loadFilteredPolicy(model, filter)
    local values = {}

    for col, val in pairs(filter) do
        if not Filter[col] then
            error("Invalid filter column " .. col)
        end
        if Util.trim(val) ~= "" then
            table.insert(values, col .. " = '" .. Util.trim(val) .. "'")
        end
    end

    local cursor, err = self.conn:execute("SELECT ptype, v0, v1, v2, v3, v4, v5 FROM " .. self.tableName
    .. " WHERE " .. table.concat(values, " AND "))

    if err then
        return false, err
    end
    local row = cursor:fetch ({}, "n")

    while row do
        local line = Util.trim(table.concat(row, ", "))
        Adapter.loadPolicyLine(line, model)

        row = cursor:fetch ({}, "n")
    end

    cursor:close()
    self.isFiltered = true
end

--[[
    * removeFilteredPolicy removes the policy rules that match the filter from the storage.
]]
function _M:removeFilteredPolicy(_, ptype, fieldIndex, fieldValues)
    local values = {}
    table.insert(values, "ptype = '" .. ptype .. "'")
    for i = fieldIndex + 1, #fieldValues do
        if Util.trim(fieldValues[i]) ~= "" then
            table.insert(values, "v" .. tostring(i-1) .. " = '" .. Util.trim(fieldValues[i]) .. "'")
        end
    end

    return self.conn:execute("DELETE FROM " .. self.tableName .. " WHERE " .. table.concat(values, " AND "))
end

return _M
