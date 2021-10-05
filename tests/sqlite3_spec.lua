local Adapter = require("migrations.sqlite3")
local Enforcer = require("casbin")
local path = os.getenv("PWD") or io.popen("cd"):read()

local function initDB()
    local a = Adapter:new("casbin")
    a.conn:execute("DELETE FROM " .. a.tableName)
    a.conn:execute("INSERT INTO " .. a.tableName .. " (ptype, v0, v1, v2) VALUES ( 'p', 'alice', 'data1', 'read')")
    a.conn:execute("INSERT INTO " .. a.tableName .. " (ptype, v0, v1, v2) VALUES ( 'p', 'bob', 'data2', 'write')")
    a.conn:execute("INSERT INTO " .. a.tableName .. " (ptype, v0, v1, v2) VALUES ( 'p', 'data2_admin', 'data2', 'read')")
    a.conn:execute("INSERT INTO " .. a.tableName .. " (ptype, v0, v1, v2) VALUES ( 'p', 'data2_admin', 'data2', 'write')")
    a.conn:execute("INSERT INTO " .. a.tableName .. " (ptype, v0, v1) VALUES ( 'g', 'alice', 'data2_admin')")
    return a
end

local function getEnforcer()
    local e = Enforcer:new(path .. "/tests/rbac_model.conf", path .. "/tests/empty_policy.csv")
    local a = initDB()
    e.adapter = a
    e:loadPolicy()
    return e
end

describe("Casbin SQLite3 Adapter tests", function ()
    it("Load Policy test", function ()
        local e = getEnforcer()
        assert.is.True(e:enforce("alice", "data1", "read"))
        assert.is.False(e:enforce("bob", "data1", "read"))
        assert.is.True(e:enforce("bob", "data2", "write"))
        assert.is.True(e:enforce("alice", "data2", "read"))
        assert.is.True(e:enforce("alice", "data2", "write"))
    end)

    it("Load Filtered Policy test", function ()
        local e = getEnforcer()
        e:clearPolicy()
        assert.is.Same({}, e:GetPolicy())

        assert.has.error(function ()
            local filter = {"alice", "data1"}
            e:loadFilteredPolicy(filter)
        end)

        local filter = {
            ["v0"] = "bob"
        }
        e:loadFilteredPolicy(filter)
        assert.is.Same({{"bob", "data2", "write"}}, e:GetPolicy())
        e:clearPolicy()

        filter = {
            ["v2"] = "read"
        }
        e:loadFilteredPolicy(filter)
        assert.is.Same({
            {"alice", "data1", "read"},
            {"data2_admin", "data2", "read"}
        }, e:GetPolicy())
        e:clearPolicy()

        filter = {
            ["v0"] = "data2_admin",
            ["v2"] = "write"
        }
        e:loadFilteredPolicy(filter)
        assert.is.Same({{"data2_admin", "data2", "write"}}, e:GetPolicy())
    end)

    it("Add Policy test", function ()
        local e = getEnforcer()
        assert.is.False(e:enforce("eve", "data3", "read"))
        e:AddPolicy("eve", "data3", "read")
        assert.is.True(e:enforce("eve", "data3", "read"))
    end)

    it("Add Policies test", function ()
        local e = getEnforcer()
        local policies = {
            {"u1", "d1", "read"},
            {"u2", "d2", "read"},
            {"u3", "d3", "read"}
        }
        e:clearPolicy()
        e.adapter:savePolicy(e.model)
        assert.is.Same({}, e:GetPolicy())

        e:AddPolicies(policies)
        e:clearPolicy()
        e:loadPolicy()
        assert.is.Same(policies, e:GetPolicy())
    end)

    it("Save Policy test", function ()
        local e = getEnforcer()
        assert.is.False(e:enforce("alice", "data4", "read"))

        e.model:clearPolicy()
        e.model:addPolicy("p", "p", {"alice", "data4", "read"})
        e.adapter:savePolicy(e.model)
        e:loadPolicy()

        assert.is.True(e:enforce("alice", "data4", "read"))
    end)

    it("Remove Policy test", function ()
        local e = getEnforcer()
        assert.is.True(e:HasPolicy("alice", "data1", "read"))
        e:RemovePolicy("alice", "data1", "read")
        assert.is.False(e:HasPolicy("alice", "data1", "read"))
    end)

    it("Remove Policies test", function ()
        local e = getEnforcer()
        local policies = {
            {"alice", "data1", "read"},
            {"bob", "data2", "write"},
            {"data2_admin", "data2", "read"},
            {"data2_admin", "data2", "write"}
        }
        assert.is.Same(policies, e:GetPolicy())
        e:RemovePolicies({
            {"data2_admin", "data2", "read"},
            {"data2_admin", "data2", "write"}
        })

        policies = {
            {"alice", "data1", "read"},
            {"bob", "data2", "write"}
        }
        assert.is.Same(policies, e:GetPolicy())
    end)

    it("Update Policy test", function ()
        local e = getEnforcer()
        local policies = {
            {"alice", "data1", "read"},
            {"bob", "data2", "write"},
            {"data2_admin", "data2", "read"},
            {"data2_admin", "data2", "write"}
        }
        assert.is.Same(policies, e:GetPolicy())

        e:UpdatePolicy(
            {"bob", "data2", "write"},
            {"bob", "data2", "read"}
        )
        policies = {
            {"alice", "data1", "read"},
            {"bob", "data2", "read"},
            {"data2_admin", "data2", "read"},
            {"data2_admin", "data2", "write"}
        }

        assert.is.Same(policies, e:GetPolicy())
    end)

    it("Update Policies test", function ()
        local e = getEnforcer()
        local policies = {
            {"alice", "data1", "read"},
            {"bob", "data2", "write"},
            {"data2_admin", "data2", "read"},
            {"data2_admin", "data2", "write"}
        }
        assert.is.Same(policies, e:GetPolicy())

        e:UpdatePolicies(
                {{"alice", "data1", "read"},{"bob", "data2", "write"}},
                {{"alice", "data1", "write"},{"bob", "data2", "read"}}
        )
        policies = {
            {"alice", "data1", "write"},
            {"bob", "data2", "read"},
            {"data2_admin", "data2", "read"},
            {"data2_admin", "data2", "write"}
        }

        assert.is.Same(policies, e:GetPolicy())
    end)

    it("Remove Filtered Policy test", function ()
        local e = getEnforcer()
        assert.is.True(e:enforce("alice", "data1", "read"))
        e:RemoveFilteredPolicy(1, "data1")
        assert.is.False(e:enforce("alice", "data1", "read"))

        assert.is.True(e:enforce("bob", "data2", "write"))
        assert.is.True(e:enforce("alice", "data2", "read"))
        assert.is.True(e:enforce("alice", "data2", "write"))

        e:RemoveFilteredPolicy(1, "data2", "read")

        assert.is.True(e:enforce("bob", "data2", "write"))
        assert.is.False(e:enforce("alice", "data2", "read"))
        assert.is.True(e:enforce("alice", "data2", "write"))

        e:RemoveFilteredPolicy(1, "data2")

        assert.is.False(e:enforce("bob", "data2", "write"))
        assert.is.False(e:enforce("alice", "data2", "read"))
        assert.is.False(e:enforce("alice", "data2", "write"))
    end)
end)