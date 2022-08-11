# luasql-adapter

[![GitHub Action](https://github.com/casbin-lua/luasql-adapter/workflows/test/badge.svg?branch=master)](https://github.com/casbin-lua/luasql-adapter/actions)
[![Coverage Status](https://coveralls.io/repos/github/casbin-lua/luasql-adapter/badge.svg?branch=master)](https://coveralls.io/github/casbin-lua/luasql-adapter?branch=master)
[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/casbin/lobby)

casbin-adapter is a LuaSQL based adapter for Casbin that supports policies from SQL-based databases (MySQL, PostgreSQL, SQLite3).

## Installation

First, install the corresponding driver of LuaSQL from LuaRocks based on the database you use:
- For MySQL, install luasql-mysql.
- For PostgreSQL, install luasql-postgres.
- For SQLite3, install luasql-sqlite3.

Take installing luasql-mysql for example, others are similar: 
- If there is no mysql locally, please install it locally.
- Run `whereis mysql` to find your mysql path, then cd into th path to find include path and lib path.
  ```shell
  [root@master ~]# whereis mysql
  mysql: /usr/bin/mysql /usr/local/mysql
  ```
- Use mysql include path and lib path to install luasql-mysql. Run `luarocks install luasql-mysql MYSQL_INCDIR=/usr/local/mysql/include MYSQL_LIBDIR=/usr/local/mysql/lib`

Then install the casbin-adapter from LuaRocks by
```bash
sudo luarocks install https://raw.githubusercontent.com/casbin-lua/luasql-adapter/master/casbin-adapter-1.0.0-1.rockspec
```

## Usage

To create a new Casbin Enforcer using a MySQL adapter, use:

```lua
local Enforcer = require("casbin")
local Adapter = require("casbin.mysql")

local a = Adapter:new(database, user, password, hostname, port) -- hostname, port are optional
local e = Enforcer:new("/path/to/model.conf", a) -- creates a new Casbin enforcer with the model.conf file and the database
```

For other adapters, replace `local Adapter = require("casbin.mysql")` with:
- `local Adapter = require("casbin.postgres")` for PostgreSQL adapter.
- `local Adapter = require("casbin.sqlite3")` for SQLite3 adapter. In SQLite3 adapter, only database field is required and others are optional.

## Getting Help

- [Lua Casbin](https://github.com/casbin/lua-casbin)

## License

This project is under Apache 2.0 License. See the [LICENSE](https://github.com/casbin-lua/luasql-adapter/blob/master/LICENSE) file for the full license text.