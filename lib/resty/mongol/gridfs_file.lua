local mod_name = (...):match ( "^(.*)%..-$" )

local md5 = require "resty.md5"
local str = require "resty.string"
local bson = require ( mod_name .. ".bson" )
local object_id = require ( mod_name .. ".object_id" )

local gridfs_file_mt = { }
local gridfs_file = { __index = gridfs_file_mt }
local get_bin_data = bson.get_bin_data
local get_utc_date = bson.get_utc_date

-- write size bytes from the buf string into mongo, by the offset 
function gridfs_file_mt:write(buf, offset, size)
    size = size or string.len(buf)

    local i
    local cn -- number of chunks to be updated
    local nv = {}
    local of = offset % self.chunk_size
    local n = math.floor(offset/self.chunk_size)

    if of == 0 and size % self.chunk_size == 0 then
        --               chunk1 chunk2 chunk3
        -- old data      ====== ====== ======
        -- write buf            ====== ======
        cn = size/self.chunk_size
        for i = 1, cn do
            nv["$set"] = {data = get_bin_data(string.sub(buf, 
                            self.chunk_size*(i-1) + 1, 
                            self.chunk_size*(i-1) + self.chunk_size))}
            self.chunk_col:update({files_id = self.files_id, n = n+i-1}, nv,
                    0, 0, true)
        end
        return
    end


    local af  -- number of bytes to be updated in first chunk
    if of + size > self.chunk_size then
        --               chunk1 chunk2 chunk3
        -- old data      ====== ====== ======
        -- write buf        =======
        --               ...     -> of
        --                  ...  -> af
        af = self.chunk_size - of
    else
        af = size
    end

    cn = math.ceil((size + offset)/self.chunk_size) - n
    local bn = 0 --  bytes number of buf already updated
    local od, t
    for i = 1, cn do
        if i == 1 then
            od = self.chunk_col:find_one(
                            {files_id = self.files_id, n = n+i-1})
            if of ~= 0 then
                if size + of >= self.chunk_size then
                    --               chunk1 chunk2 chunk3
                    -- old data      ====== ====== ======
                    -- write buf        =====
                    t = string.sub(od.data, 1, of) .. string.sub(buf, 1, af)
                else
                    --               chunk1 chunk2 chunk3
                    -- old data      ====== ====== ======
                    -- write buf        ==
                    t = string.sub(od.data, 1, of) .. string.sub(buf, 1, af)
                            .. string.sub(od.data, size + of + 1)
                end
                bn = bn + self.chunk_size
            elseif of == 0 then
                if size < self.chunk_size then
                    --               chunk1 chunk2 chunk3
                    -- old data      ====== ====== ======
                    -- write buf     ===
                    t = string.sub(buf, 1) .. string.sub(od.data, size + 1)
                    bn = bn + size
                else
                    --               chunk1 chunk2 chunk3
                    -- old data      ====== ====== ======
                    -- write buf     =========
                    t = string.sub(buf, 1, self.chunk_size)
                    bn = bn + self.chunk_size
                end
            end
            nv["$set"] = {data = get_bin_data(t)}
            self.chunk_col:update({files_id = self.files_id, n = n+i-1}, nv,
                                0, 0, true)
        elseif i == cn then
            local od = self.chunk_col:find_one(
                            {files_id = self.files_id, n = n + i}
                        )
            t = string.sub(buf, bn + 1, size) 
                            .. string.sub(od.data, size - bn + 1)
            nv["$set"] = {data = get_bin_data(t)}
            self.chunk_col:update({files_id = self.files_id, n = n+i-1}, nv,
                                0, 0, true)
            bn = size
        else
            nv["$set"] = {data = get_bin_data(string.sub(buf, 
                                    af + 1, af + self.chunk_size))}
            self.chunk_col:update({files_id = self.files_id, n = n+i-1},nv, 
                        0, 0, true)
            bn = bn + self.chunk_size
        end
    end
    return bn
end

-- read size bytes from mongo by the offset
function gridfs_file_mt:read(size, offset)
    size = size or self.file_size
    if size < 0 then
        return nil, "invalid size"
    end
    offset = offset or 0
    if offset < 0 or offset >= self.file_size then
        return nil, "invalid offset"
    end

    local n = math.floor(offset / self.chunk_size)
    local r
    local bytes = ""
    local rn = 0
    while true do
        r = self.chunk_col:find_one({files_id = self.files_id, n = n})
        if not r then return nil, "read chunk failed" end
        if size - rn < self.chunk_size then
            bytes = bytes .. string.sub(r.data, 1, size - rn)
            rn = size
        else
            bytes = bytes .. r.data
            rn = rn + self.chunk_size
        end
        n = n + 1
        if rn >= size then break end
    end
    return bytes
end

return gridfs_file
