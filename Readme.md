Name
======
lua-resty-mongol - Lua Mongodb driver for ngx_lua base on the cosocket API

Thanks to project Mongol by daurnimator

Dependancies
======

luajit(or `attempt to yield across metamethod/C-call boundary error` will be produced.)

lua-md5

[ngx_lua 0.5.0rc5](https://github.com/chaoslawful/lua-nginx-module/tags) or [ngx_openresty 1.0.11.7](http://openresty.org/#Download) is required.


Installation
======

		make install

Usage
======

Add package path into nginx.conf.

        lua_package_path '/usr/local/openresty/lualib/?/init.lua;;';

or into lua files before requiring.

        local p = "/usr/local/openresty/lualib/"
        local m_package_path = package.path
        package.path = string.format("%s?.lua;%s?/init.lua;%s",
            p, p, m_package_path)

Requring the module will return a function that connects to mongod:
it takes a host (default localhost) and a port (default 27017);
it returns a connection object.

		mongol = require "resty.mongol"
		conn = mongol:new() -- return a conntion object

###Connection objects have server wide methods.
------------

####ok,err = conn:connect(host, port)
Default host and port is: `localhost` and `27017`.

####ok,err = conn:settimeout(msec)
Sets socket connecting, reading, writing timeout value, unit is milliseconds.

In case of success, returns 1. In case of errors, returns nil with a string describing the error.

####ok,err = conn:set_keepalive(msec, pool_size)
Keeps the socket alive for `msec` by ngx_lua cosocket.

In case of success, returns 1. In case of errors, returns nil with a string describing the error.

####times,err = conn:get_reused_times()
Returns the socket reused times.

In case of success, returns times. In case of errors, returns nil with a string describing the error.

####ok,err = conn:close()
Closes the connection.

In case of success, returns 1. In case of errors, returns nil with a string describing the error.

####conn:cmd(database_name, query, [collection])
Returns the document
or `nil , errmsg , return_document , responseFlags` on failure;
where `responseFlags` is a table containing the fields `CursorNotFound, QueryFailure, ShardConfigStale, AwaitCapable`.

####bool, hosts = conn:ismaster()
Returns a boolean indicating if this is the master server and a table of other hosts this server is replicating with
or `nil, err` on failure.

####newconn = conn:getprimary ( [already_checked] )
Returns a new connection object that is connected to the primary server
or `nil , errmsg` on failure.

The returned connection object may be this connection object itself.


####databases = conn:databases ( )
Returns a table describing databases on the server.

		databases.name: string
		databases.empty: boolean
		databases.sizeOnDisk: number

####conn:shutdown()
Shutsdown the server. Returns nothing.

####db = conn:new_db_handle(database_name)
Returns a database object, or nil.

###Database objects perform actions on a database
------------

####db:list()

####db:dropDatabase()

####db:add_user(username, password)

####ok, err = db:auth(username, password)
Returns 1 in case of success, or nil with error message.

####col = db:get_col(collection_name)
Returns a collection object for more operations.


###Collection objects
------------

####n = col:count(query)

####ok, err = col:drop()
Returns 1 in case of success, or nil with error message.

####n, err = col:update(selector, update, upsert, multiupdate, safe)

 - upsert, if set to `1`, the database will insert the supplied object into the collection if no matching document is found, default to `0`.
 - multiupdate, if set to `1`, the database will update all matching objects in the collection. Otherwise only updates first matching doc, default to `0`. Multi update only works with $ operators.
 - safe can be a boolean or integer, defaults to `0`. If `1`, the program will issue a cmd `getlasterror` to server to query the result. If `false`, return value `n` would always be `-1`

####n, err = col:insert(docs, continue_on_error, safe)
Returns 0 for success, or nil with error message.

 - continue_on_error, if set, the database will not stop processing a bulk insert if one fails (eg due to duplicate IDs).
 - safe can be a boolean or integer, defaults to `0`. If `1`, the program will issue a cmd `getlasterror` to server to query the result. If `false`, return value `n` would always be `-1`

####n, err = col:delete(selector, singleRemove, safe)
Returns number of rows been deleted, or nil with error message.

 - singleRemove if set to 1, the database will remove only the first matching document in the collection. Otherwise all matching documents will be removed. Default to `0`
 - safe can be a boolean or integer, defaults to `0`. If `1`, the program will issue a cmd `getlasterror` to server to query the result. If `false`, return value `n` would always be `-1`

####r = col:find_one(query, returnfields)
Returns a single element array, or nil.

 - returnfields is the fields to return, eg: `{n=0}` or `{n=1}`

####cursor = col:find(query, returnfields, num_each_query)
Returns a cursor object for excuting query.

 - returnfields is the fields to return, eg: `{n=0}` or `{n=1}`
 - num_each_query is the max result number for each query of the cursor to avoid fetch a large result in memory, must larger than `1`, `0` for no limit, default to `100`.

####col:getmore(cursorID, [numberToReturn], [offset_i])
 - cursorID is an 8 byte string representing the cursor to getmore on
 - numberToReturn is the number of results to return, defaults to -1
 - offset_i is the number to start numbering the returned table from, defaults to 1

####col:kill_cursors(cursorIDs)

###Cursor objects
--------------------

####index, item = cursor:next()
Returns the next item and advances the cursor.

####cursor:pairs()
A handy wrapper around cursor:next() that works in a generic for loop:

		for index, item in cursor:pairs() do

####cursor:limit(n)
Limits the number of results returned.

####result = cursor:sort(field, size)
Returns an array with size `size` sorted by given field. 

 - field is an array by which to sort, and this array size _MUST be 1_. The element in the array has as key the field name, and as value either `1` for ascending sort, or `-1` for descending sort. 
 - num is the temp array size for sorting, default to `10000`.

###Object id
-------------------

####objid:tostring()
####objid:get_ts()
####objid:get_pid()
####objid:get_hostname()
####objid:get_inc()

Notes
---------------------------
 - collections are string containing any value except "\0"
 - database_name are strings containing any character except "." and "\0"

Known Issues
---------------------------
1. Auth bson message has reduntant value.

Example
---------------------------
            local mongo = require "resty.mongol"
            conn = mongo:new()
            conn:set_timeout(1000)
            ok, err = conn:connect()
            if not ok then
                ngx.say("connect failed: "..err)
            end

            local db = conn:new_db_handle ( "test" )
            col = db:get_col("test")

            r = col:find({name="dog"})

            for i , v in r:pairs() do
                if v["name"] then
                    ngx.say(v["name"])
                end
            end


For Test Case
--------------------
#####mongo config:
        config = {_id: 'testset', members: [
                          {_id: 0, host: '10.6.2.51:27017'},
                          {_id: 1, host: '10.6.2.51:27018'},
                          {_id: 2, host: '10.6.2.51:27019'}]
                }

#####start-mongo.sh:
        nohup bin/mongod --dbpath=/data/57cbd36d-5b70-4888-8537-bea71119363e/mongodb --oplogSize 10 --rest --replSet testset --port 27017 --keyFile key.file &
        nohup bin/mongod --dbpath=/data/0a9419ae-4ec3-48c2-ad8d-df68a09aed13/mongodb --oplogSize 10 --rest --replSet testset --port 27018 --keyFile key.file &
        nohup bin/mongod --dbpath=/data/8ee9efc0-a854-4c45-8893-7b4cb9ed0e5f/mongodb --oplogSize 10 --rest --replSet testset --port 27019 --keyFile key.file &

#####mongo user:
        > db.addUser("admin","admin")
