# vim:set ft= ts=4 sw=4 et:

use Test::Nginx::Socket;
use Cwd qw(cwd);

repeat_each(1);

plan tests => repeat_each() * (4 * blocks());

my $pwd = cwd();

our $HttpConfig = qq{
    lua_package_path "$pwd/lib/?/init.lua;;";
};

$ENV{TEST_NGINX_RESOLVER} = '8.8.8.8';
$ENV{TEST_NGINX_MONGO_PORT} ||= 27017;
$ENV{TEST_NGINX_TIMEOUT} = 10000;

no_long_string();
#no_diff();

run_tests();

__DATA__


=== TEST 1: write chunk < 1, offset = 0
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local mongo = require "resty.mongol"
            conn = mongo:new()
            conn:set_timeout(10000) 
            local ok, err = conn:connect("10.6.2.51")

            if not ok then
                ngx.say("connect failed: "..err)
            end

            local db = conn:new_db_handle("test")
            local r = db:auth("admin", "admin")
            if not r then ngx.say("auth failed") end
            local fs = db:get_gridfs("fs")

            r, err = fs:remove({}, nil, true)
            if not r then ngx.say("delete failed: "..err) end

            local f,err = io.open("t/servroot/html/test.txt", "rb")
            if not f then ngx.say("fs open failed: "..err) ngx.exit(ngx.HTTP_OK) end

            r, err = fs:insert(f, {chunkSize = 6, filename="testfile"}, true)
            if not r then ngx.say("fs insert failed: "..err) end
            ngx.say(r)
            io.close(f)

            local gf = fs:find_one({filename="testfile"})
            gf:write("abc", 0)

            f = io.open("/tmp/testfile", "wb")
            r = fs:get(f, {filename="testfile"})
            if not r then ngx.say("get file failed: "..err) end
            io.close(f)

        ';
    }
--- user_files
>>> test.txt
12345678901234567890
--- request
GET /t
--- response_body
0
--- no_error_log
--- output_files
>>> /tmp/testfile 
abc45678901234567890
--- no_error_log
[error]

=== TEST 2: write chunk < 1, offset > 0
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local mongo = require "resty.mongol"
            conn = mongo:new()
            conn:set_timeout(10000) 
            local ok, err = conn:connect("10.6.2.51")

            if not ok then
                ngx.say("connect failed: "..err)
            end

            local db = conn:new_db_handle("test")
            local r = db:auth("admin", "admin")
            if not r then ngx.say("auth failed") end
            local fs = db:get_gridfs("fs")

            r, err = fs:remove({}, nil, true)
            if not r then ngx.say("delete failed: "..err) end

            local f,err = io.open("t/servroot/html/test.txt", "rb")
            if not f then ngx.say("fs open failed: "..err) ngx.exit(ngx.HTTP_OK) end

            r, err = fs:insert(f, {chunkSize = 6, filename="testfile"}, true)
            if not r then ngx.say("fs insert failed: "..err) end
            ngx.say(r)
            io.close(f)

            local gf = fs:find_one({filename="testfile"})
            gf:write("abc", 2)

            f = io.open("/tmp/testfile", "wb")
            r = fs:get(f, {filename="testfile"})
            if not r then ngx.say("get file failed: "..err) end
            io.close(f)

        ';
    }
--- user_files
>>> test.txt
12345678901234567890
--- request
GET /t
--- response_body
0
--- no_error_log
--- output_files
>>> /tmp/testfile 
12abc678901234567890
--- no_error_log
[error]

=== TEST 4: write chunk = 2, offset = 0
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local mongo = require "resty.mongol"
            conn = mongo:new()
            conn:set_timeout(10000) 
            local ok, err = conn:connect("10.6.2.51")

            if not ok then
                ngx.say("connect failed: "..err)
            end

            local db = conn:new_db_handle("test")
            local r = db:auth("admin", "admin")
            if not r then ngx.say("auth failed") end
            local fs = db:get_gridfs("fs")

            r, err = fs:remove({}, nil, true)
            if not r then ngx.say("delete failed: "..err) end

            local f,err = io.open("t/servroot/html/test.txt", "rb")
            if not f then ngx.say("fs open failed: "..err) ngx.exit(ngx.HTTP_OK) end

            r, err = fs:insert(f, {chunkSize = 6, filename="testfile"}, true)
            if not r then ngx.say("fs insert failed: "..err) end
            ngx.say(r)
            io.close(f)

            local gf = fs:find_one({filename="testfile"})
            gf:write("abcabcdefdef", 0)

            f = io.open("/tmp/testfile", "wb")
            r = fs:get(f, {filename="testfile"})
            if not r then ngx.say("get file failed: "..err) end
            io.close(f)

        ';
    }
--- user_files
>>> test.txt
12345678901234567890
--- request
GET /t
--- response_body
0
--- no_error_log
--- output_files
>>> /tmp/testfile 
abcabcdefdef34567890
--- no_error_log
[error]

=== TEST 5: write chunk > 1, offset = 0
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local mongo = require "resty.mongol"
            conn = mongo:new()
            conn:set_timeout(10000) 
            local ok, err = conn:connect("10.6.2.51")

            if not ok then
                ngx.say("connect failed: "..err)
            end

            local db = conn:new_db_handle("test")
            local r = db:auth("admin", "admin")
            if not r then ngx.say("auth failed") end
            local fs = db:get_gridfs("fs")

            r, err = fs:remove({}, nil, true)
            if not r then ngx.say("delete failed: "..err) end

            local f,err = io.open("t/servroot/html/test.txt", "rb")
            if not f then ngx.say("fs open failed: "..err) ngx.exit(ngx.HTTP_OK) end

            r, err = fs:insert(f, {chunkSize = 6, filename="testfile"}, true)
            if not r then ngx.say("fs insert failed: "..err) end
            ngx.say(r)
            io.close(f)

            local gf = fs:find_one({filename="testfile"})
            gf:write("abcabcdef", 0)

            f = io.open("/tmp/testfile", "wb")
            r = fs:get(f, {filename="testfile"})
            if not r then ngx.say("get file failed: "..err) end
            io.close(f)

        ';
    }
--- user_files
>>> test.txt
12345678901234567890
--- request
GET /t
--- response_body
0
--- no_error_log
--- output_files
>>> /tmp/testfile 
abcabcdef01234567890
--- no_error_log
[error]

=== TEST 6: write chunk > 1, offset > 0
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local mongo = require "resty.mongol"
            conn = mongo:new()
            conn:set_timeout(10000) 
            local ok, err = conn:connect("10.6.2.51")

            if not ok then
                ngx.say("connect failed: "..err)
            end

            local db = conn:new_db_handle("test")
            local r = db:auth("admin", "admin")
            if not r then ngx.say("auth failed") end
            local fs = db:get_gridfs("fs")

            r, err = fs:remove({}, nil, true)
            if not r then ngx.say("delete failed: "..err) end

            local f,err = io.open("t/servroot/html/test.txt", "rb")
            if not f then ngx.say("fs open failed: "..err) ngx.exit(ngx.HTTP_OK) end

            r, err = fs:insert(f, {chunkSize = 6, filename="testfile"}, true)
            if not r then ngx.say("fs insert failed: "..err) end
            ngx.say(r)
            io.close(f)

            local gf = fs:find_one({filename="testfile"})
            gf:write("abcabcdef", 3)

            f = io.open("/tmp/testfile", "wb")
            r = fs:get(f, {filename="testfile"})
            if not r then ngx.say("get file failed: "..err) end
            io.close(f)

        ';
    }
--- user_files
>>> test.txt
12345678901234567890
--- request
GET /t
--- response_body
0
--- no_error_log
--- output_files
>>> /tmp/testfile 
123abcabcdef34567890
--- no_error_log
[error]

=== TEST 7: write chunk > 2, offset > 0
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local mongo = require "resty.mongol"
            conn = mongo:new()
            conn:set_timeout(10000) 
            local ok, err = conn:connect("10.6.2.51")

            if not ok then
                ngx.say("connect failed: "..err)
            end

            local db = conn:new_db_handle("test")
            local r = db:auth("admin", "admin")
            if not r then ngx.say("auth failed") end
            local fs = db:get_gridfs("fs")

            r, err = fs:remove({}, nil, true)
            if not r then ngx.say("delete failed: "..err) end

            local f,err = io.open("t/servroot/html/test.txt", "rb")
            if not f then ngx.say("fs open failed: "..err) ngx.exit(ngx.HTTP_OK) end

            r, err = fs:insert(f, {chunkSize = 6, filename="testfile"}, true)
            if not r then ngx.say("fs insert failed: "..err) end
            ngx.say(r)
            io.close(f)

            local gf = fs:find_one({filename="testfile"})
            gf:write("abcdefghijkl", 5)

            f = io.open("/tmp/testfile", "wb")
            r = fs:get(f, {filename="testfile"})
            if not r then ngx.say("get file failed: "..err) end
            io.close(f)

        ';
    }
--- user_files
>>> test.txt
12345678901234567890
--- request
GET /t
--- response_body
0
--- no_error_log
--- output_files
>>> /tmp/testfile 
12345abcdefghijkl890
--- no_error_log
[error]

=== TEST 8: write chunk > 2, offset > 0, size > file_size
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local mongo = require "resty.mongol"
            conn = mongo:new()
            conn:set_timeout(10000) 
            local ok, err = conn:connect("10.6.2.51")

            if not ok then
                ngx.say("connect failed: "..err)
            end

            local db = conn:new_db_handle("test")
            local r = db:auth("admin", "admin")
            if not r then ngx.say("auth failed") end
            local fs = db:get_gridfs("fs")

            r, err = fs:remove({}, nil, true)
            if not r then ngx.say("delete failed: "..err) end

            local f,err = io.open("t/servroot/html/test.txt", "rb")
            if not f then ngx.say("fs open failed: "..err) ngx.exit(ngx.HTTP_OK) end

            r, err = fs:insert(f, {chunkSize = 6, filename="testfile"}, true)
            if not r then ngx.say("fs insert failed: "..err) end
            ngx.say(r)
            io.close(f)

            local gf = fs:find_one({filename="testfile"})
            gf:write("abcdefghijklmnopq", 5)

            f = io.open("/tmp/testfile", "wb")
            r = fs:get(f, {filename="testfile"})
            if not r then ngx.say("get file failed: "..err) end
            io.close(f)

        ';
    }
--- user_files
>>> test.txt
12345678901234567890
--- request
GET /t
--- response_body
0
--- no_error_log
--- output_files
>>> /tmp/testfile chop
12345abcdefghijklmnopq
--- no_error_log
[error]

=== TEST 9: write chunk > 2, offset = 0, size > file_size
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local mongo = require "resty.mongol"
            conn = mongo:new()
            conn:set_timeout(10000) 
            local ok, err = conn:connect("10.6.2.51")

            if not ok then
                ngx.say("connect failed: "..err)
            end

            local db = conn:new_db_handle("test")
            local r = db:auth("admin", "admin")
            if not r then ngx.say("auth failed") end
            local fs = db:get_gridfs("fs")

            r, err = fs:remove({}, nil, true)
            if not r then ngx.say("delete failed: "..err) end

            local f,err = io.open("t/servroot/html/test.txt", "rb")
            if not f then ngx.say("fs open failed: "..err) ngx.exit(ngx.HTTP_OK) end

            r, err = fs:insert(f, {chunkSize = 6, filename="testfile"}, true)
            if not r then ngx.say("fs insert failed: "..err) end
            ngx.say(r)
            io.close(f)

            local gf = fs:find_one({filename="testfile"})
            gf:write("abcdefghijklmnopqrstuvw", 0)

            f = io.open("/tmp/testfile", "wb")
            r = fs:get(f, {filename="testfile"})
            if not r then ngx.say("get file failed: "..err) end
            io.close(f)

        ';
    }
--- user_files
>>> test.txt
12345678901234567890
--- request
GET /t
--- response_body
0
--- no_error_log
--- output_files
>>> /tmp/testfile chop
abcdefghijklmnopqrstuvw
--- no_error_log
[error]

=== TEST 10: write chunk > old chunk, offset = 0
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local mongo = require "resty.mongol"
            conn = mongo:new()
            conn:set_timeout(10000) 
            local ok, err = conn:connect("10.6.2.51")

            if not ok then
                ngx.say("connect failed: "..err)
            end

            local db = conn:new_db_handle("test")
            local r = db:auth("admin", "admin")
            if not r then ngx.say("auth failed") end
            local fs = db:get_gridfs("fs")

            r, err = fs:remove({}, nil, true)
            if not r then ngx.say("delete failed: "..err) end

            local f,err = io.open("t/servroot/html/test.txt", "rb")
            if not f then ngx.say("fs open failed: "..err) ngx.exit(ngx.HTTP_OK) end

            r, err = fs:insert(f, {chunkSize = 6, filename="testfile"}, true)
            if not r then ngx.say("fs insert failed: "..err) end
            ngx.say(r)
            io.close(f)

            local gf = fs:find_one({filename="testfile"})
            gf:write("abcdefghijklmnopqrstuvw", 0)

            f = io.open("/tmp/testfile", "wb")
            r = fs:get(f, {filename="testfile"})
            if not r then ngx.say("get file failed: "..err) end
            io.close(f)

        ';
    }
--- user_files
>>> test.txt
1234567890
--- request
GET /t
--- response_body
0
--- no_error_log
--- output_files
>>> /tmp/testfile chop
abcdefghijklmnopqrstuvw
--- no_error_log
[error]

=== TEST 11: write chunk > old chunk, offset > 0
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local mongo = require "resty.mongol"
            conn = mongo:new()
            conn:set_timeout(10000) 
            local ok, err = conn:connect("10.6.2.51")

            if not ok then
                ngx.say("connect failed: "..err)
            end

            local db = conn:new_db_handle("test")
            local r = db:auth("admin", "admin")
            if not r then ngx.say("auth failed") end
            local fs = db:get_gridfs("fs")

            r, err = fs:remove({}, nil, true)
            if not r then ngx.say("delete failed: "..err) end

            local f,err = io.open("t/servroot/html/test.txt", "rb")
            if not f then ngx.say("fs open failed: "..err) ngx.exit(ngx.HTTP_OK) end

            r, err = fs:insert(f, {chunkSize = 6, filename="testfile"}, true)
            if not r then ngx.say("fs insert failed: "..err) end
            ngx.say(r)
            io.close(f)

            local gf = fs:find_one({filename="testfile"})
            gf:write("abcdefghijklmnopqrstuvw", 8)

            f = io.open("/tmp/testfile", "wb")
            r = fs:get(f, {filename="testfile"})
            if not r then ngx.say("get file failed: "..err) end
            io.close(f)

        ';
    }
--- user_files
>>> test.txt
1234567890
--- request
GET /t
--- response_body
0
--- no_error_log
--- output_files
>>> /tmp/testfile chop
12345678abcdefghijklmnopqrstuvw
--- no_error_log
[error]

=== TEST 12: write chunk = 1, offset > 0, size > file size
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local mongo = require "resty.mongol"
            conn = mongo:new()
            conn:set_timeout(10000) 
            local ok, err = conn:connect("10.6.2.51")

            if not ok then
                ngx.say("connect failed: "..err)
            end

            local db = conn:new_db_handle("test")
            local r = db:auth("admin", "admin")
            if not r then ngx.say("auth failed") end
            local fs = db:get_gridfs("fs")

            r, err = fs:remove({}, nil, true)
            if not r then ngx.say("delete failed: "..err) end

            local f,err = io.open("t/servroot/html/test.txt", "rb")
            if not f then ngx.say("fs open failed: "..err) ngx.exit(ngx.HTTP_OK) end

            r, err = fs:insert(f, {chunkSize = 6, filename="testfile"}, true)
            if not r then ngx.say("fs insert failed: "..err) end
            ngx.say(r)
            io.close(f)

            local gf = fs:find_one({filename="testfile"})
            gf:write("abcdef", 2)

            f = io.open("/tmp/testfile", "wb")
            r = fs:get(f, {filename="testfile"})
            if not r then ngx.say("get file failed: "..err) end
            io.close(f)

        ';
    }
--- user_files
>>> test.txt
123
--- request
GET /t
--- response_body
0
--- no_error_log
--- output_files
>>> /tmp/testfile chop
12abcdef
--- no_error_log
[error]

=== TEST 13: write and update md5
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local mongo = require "resty.mongol"
            conn = mongo:new()
            conn:set_timeout(10000) 
            local ok, err = conn:connect("10.6.2.51")

            if not ok then
                ngx.say("connect failed: "..err)
            end

            local db = conn:new_db_handle("test")
            local r = db:auth("admin", "admin")
            if not r then ngx.say("auth failed") end
            local fs = db:get_gridfs("fs")

            r, err = fs:remove({}, nil, true)
            if not r then ngx.say("delete failed: "..err) end

            local f,err = io.open("t/servroot/html/test.txt", "rb")
            if not f then ngx.say("fs open failed: "..err) ngx.exit(ngx.HTTP_OK) end

            r, err = fs:insert(f, {chunkSize = 6, filename="testfile"}, true)
            if not r then ngx.say("fs insert failed: "..err) end
            ngx.say(r)
            io.close(f)

            local gf = fs:find_one({filename="testfile"})
            gf:write("abc", 2)

            f = io.open("/tmp/testfile", "wb")
            r = fs:get(f, {filename="testfile"})
            if not r then ngx.say("get file failed: "..err) end
            io.close(f)

            r, err = gf:update_md5()
            if not r then ngx.say("update md5 failed: "..err) end
            ngx.say(gf.file_md5)
        ';
    }
--- user_files
>>> test.txt
123
--- request
GET /t
--- response_body
0
42c56c61ee49c16375960c809c6a3eb0
--- no_error_log
--- output_files
>>> /tmp/testfile chop
12abc
--- no_error_log
[error]
