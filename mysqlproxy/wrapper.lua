assert(package.loadlib(os.getenv("EDBDIR").."/obj/libexecute.so",
                       "lua_cryptdb_init"))()
local proto = assert(require("mysql.proto"))

local g_want_interim    = nil
local skip              = false
local client            = nil
--
-- Interception points provided by mysqlproxy
--

-- nessesary for data analysis
freq = {}
database = ""
total_fake = 0

function load_meta()
    local file = io.open('mysqlproxy/freqs.txt', 'r')
    local line_key = ""    
    for line in file:lines() do
        if string.sub(line, 1, 2) == "  " then
            -- print('adding values')
            local index = 1
            local val_key = ""
            for w in string.gmatch(line, "[%w']+") do
                if index == 1 then
                    val_key = w
                else
                    print(line_key, freq[line_key], val_key)                    
                    freq[line_key][val_key] = tonumber(w)
                end
                print(w)                
                index = index + 1
            end
        elseif string.sub(line, 1, 10) == "total_fake" then
            for w in string.gmatch(line, "(%w+)") do
                total_fake = tonumber(w)
            end
        else
            -- print('adding key', line)
            line_key = line
            freq[line_key] = {}
        end

    end
    file:close()
end

print('loading meta')
load_meta()
print('finished loading meta')

function read_auth()
    client = proxy.connection.client.src.name 
    -- Use this instead of connect_server(), to get server name
    dprint("Connected " .. proxy.connection.client.src.name)
    CryptDB.connect(proxy.connection.client.src.name,
                    proxy.connection.server.dst.address,
                    proxy.connection.server.dst.port,
                    os.getenv("CRYPTDB_USER") or "root",
                    os.getenv("CRYPTDB_PASS") or "letmein",
            os.getenv("CRYPTDB_SHADOW") or os.getenv("EDBDIR").."/shadow")
    -- EDBClient uses its own connection to the SQL server to set up UDFs
    -- and to manipulate multi-principal state.  (And, in the future, to
    -- store its schema state for single- and multi-principal operation.)
end

function disconnect_client()
    dprint("Disconnected " .. proxy.connection.client.src.name)
    CryptDB.disconnect(proxy.connection.client.src.name)
end

function read_query(packet)
    local status, err = pcall(read_query_real, packet)
    if status then
        return err
    else
        print("read_query: " .. err)
        return proxy.PROXY_SEND_QUERY
    end
end

function smooth(query)
    local cols = {} 
    local vals = {}
    local lower = string.lower(query)
    local to_insert = 0
    local new_query = query
    
    -- print_val(proxy)

    if string.sub(lower, 1, 3) == 'use' then
        for w in string.gmatch(query, "(%w+)") do
            database = string.gsub(w, "%s+", "")
        end
    end

    if string.sub(lower, 1, 6) == 'insert' then
        local file = io.open('mysqlproxy/freqs.txt', 'w')    
        local tablename = string.gsub(string.match(query, "(%w-%()"), "(%()", "")
        local index = 0
        for w in string.gmatch(query, "(%(.-%))") do
            -- print(w)
            if index == 0 then
                -- print("parsing fields")
                for col in string.gmatch(w, "([,%(%s]%w-[%s,%)])") do
                    local cleaned = string.gsub(col, "([,%(%)%s])", "")
                    table.insert(cols, cleaned)
                end
            end
            
            if index > 0 then
                -- print("parsing values")              
                for val in string.gmatch(w, "([,%(%s][%w%x']+[%s,%)])") do
                    -- print(val)                                        
                    local cleaned = string.gsub(val, "([,%(%)%s])", "")
                    table.insert(vals, cleaned)
                end
            end
            index = index + 1
        end

        
        for k, col in pairs(cols) do

            local count = 1
            local val = vals[k]
            local key = database.."_"..tablename.."_"..col

            if col == 'illness' then
            
                if freq[key] == nil then
                    freq[key] = {}
                    freq[key]["max"] = count
                    freq[key][val] = count
                else 
                    max = freq[key]["max"]
                
                    if freq[key][val] == nil then
                        freq[key][val] = count
                    else
                        count = freq[key][val]
                        count = count + 1
                        freq[key][val] = count
                    end

                    print(val, 'max' ,max, 'current count' , freq[key][val])                

                    if max < freq[key][val] then
                        freq[key]["max"] = freq[key][val]
                    end

                    to_insert = max - count

                    if to_insert > 0 then
                        freq[key][val] = count + to_insert
                    end
                
                end

            end
        end
        
        -- print('file created')
        
        for i, v in pairs(freq) do
            file:write(i..'\n')
            for j, count in pairs(v) do
                file:write("  "..j..' '..count..'\n')
                print(j, count)
            end
        end

        print("to fake insert", to_insert)   
        
        total_fake = total_fake + to_insert

        value_query = "("
        col_query = "("
        for k, val in pairs(vals) do
            col_query = col_query..cols[k]..","
            value_query = value_query..val..","
        end

        col_query = col_query.."type) "
        -- value_query = string.sub(value_query, 1, string.len(value_query) - 0)
        new_query = "INSERT INTO "..tablename..col_query.."VALUES "..value_query.."'r')"
        for i = 1, to_insert, 1 do
            new_query = new_query..","..value_query.."null)"
            -- freq[key][val] = count + to_insert            
        end
        file:write('total_fake'..' '..total_fake..'\n')
        file:close()    
    end

    print("final query", new_query)
    print("total fake inserted", total_fake)    

    return new_query
end

function print_val(tab) 
    if type(tab) == 'table' then
        for k, val in pairs(tab) do
            print(k, val)
        end
    end
end

function read_query_result(inj)
    local status, err = pcall(read_query_result_real, inj)
    if status then
        return err
    else
        print("read_query_result: " .. err)
        return proxy.PROXY_SEND_RESULT
    end
end


--
-- Pretty printing
--

DEMO = true

COLOR_END = '\027[00m'

function redtext(x)
    return '\027[1;31m' .. x .. COLOR_END
end

function greentext(x)
    return '\027[1;92m'.. x .. COLOR_END
end

function orangetext(x)
    return '\027[01;33m'.. x .. COLOR_END
end

function printred(x)
     print(redtext(x), COLOR_END)
end

function printline(n)
    -- pretty printing
    if (n) then
       io.write("+")
    end
    for i = 1, n do
        io.write("--------------------+")
    end
    print()
end

function makePrintable(s)
    -- replace nonprintable characters with ?
    if s == nil then
       return s
    end
    local news = ""
    for i = 1, #s do
        local c = s:sub(i,i)
        local b = string.byte(c)
        if (b >= 32) and (b <= 126) then
           news = news .. c
        else
           news = news .. '?'
        end
    end

    return news

end

function prettyNewQuery(q)
    if DEMO then
        if string.find(q, "remote_db") then
            -- don't print maintenance queries
            return
        end
    end
 
    print(greentext("NEW QUERY: ")..makePrintable(q))
end

--
-- Helper functions
--

function dprint(x)
    if os.getenv("CRYPTDB_PROXY_DEBUG") then
        print(x)
    end
end

function read_query_real(packet)
    local query = string.sub(packet, 2)
    print("================================================")
    printred("QUERY: ".. query)
    if string.byte(packet) == proxy.COM_INIT_DB then
        query = "USE `" .. query .. "`"
    end

    query = smooth(query)
    
    if string.byte(packet) == proxy.COM_INIT_DB or
       string.byte(packet) == proxy.COM_QUERY then
        status, error_msg =
            CryptDB.rewrite(client, query, proxy.connection.server.thread_id)

        if false == status then
            proxy.response.type = proxy.MYSQLD_PACKET_ERR
            proxy.response.errmsg = error_msg
            return proxy.PROXY_SEND_RESULT
        end

        return next_handler("query", true, client, {}, {}, nil, nil)
    elseif string.byte(packet) == proxy.COM_QUIT then
        -- do nothing
    else
        print("unexpected packet type " .. string.byte(packet))
    end
end

function read_query_result_real(inj)
    local query = inj.query:sub(2)
    prettyNewQuery(query)
    
    if skip == true then
        skip = false
        return
    end
    skip = false

    local resultset = inj.resultset

    if resultset.query_status == proxy.MYSQLD_PACKET_ERR then
        return next_handler("results", false, client, {}, {}, 0, 0)
    end

    local client = proxy.connection.client.src.name
    local interim_fields = {}
    local interim_rows = {}

    if true == g_want_interim then
        -- build up interim result for next(...) calls
        print(greentext("ENCRYPTED RESULTS:"))

        -- mysqlproxy doesn't return real lua arrays, so re-package
        local resfields = resultset.fields

        printline(#resfields)
        if (#resfields) then
           io.write("|")
        end
        for i = 1, #resfields do
            rfi = resfields[i]
            interim_fields[i] =
                { type = resfields[i].type,
                  name = resfields[i].name }
            io.write(string.format("%-20s|",rfi.name))
        end

        print()
        printline(#resfields)

        local resrows = resultset.rows
        if resrows then
            for row in resrows do
                table.insert(interim_rows, row)
                io.write("|")
                for key,value in pairs(row) do
                    io.write(string.format("%-20s|", makePrintable(value)))
                end
                print()
            end
        end

        printline(#resfields)
    end

    return next_handler("results", true, client, interim_fields, interim_rows,
                        resultset.affected_rows, resultset.insert_id)
end

local q_index = 0
function get_index()
    i = q_index
    q_index = q_index + 1
    return i
end

function handle_from(from)
    if "query" == from then
        return proxy.PROXY_SEND_QUERY
    elseif "results" == from then
        return proxy.PROXY_IGNORE_RESULT
    end

    assert(nil)
end

function next_handler(from, status, client, fields, rows, affected_rows,
                      insert_id)
    local control, param0, param1, param2, param3 =
        CryptDB.next(client, fields, rows, affected_rows, insert_id, status)
    if "again" == control then
        g_want_interim      = param0
        local query         = param1

        proxy.queries:append(get_index(), string.char(proxy.COM_QUERY) .. query,
                             { resultset_is_needed = true } )
        return handle_from(from)
    elseif "query-results" == control then
        local query = param0

        proxy.queries:append(get_index(), string.char(proxy.COM_QUERY) .. query,
                             { resultset_is_needed = true } )
        skip = true
        return handle_from(from)
    elseif "results" == control then
        local raffected_rows    = param0
        local rinsert_id        = param1
        local rfields           = param2
        local rrows             = param3

        if #rfields > 0 then
            proxy.response.resultset = { fields = rfields, rows = rrows }
        end

        proxy.response.type             = proxy.MYSQLD_PACKET_OK
        proxy.response.affected_rows    = raffected_rows
        proxy.response.insert_id        = rinsert_id

        return proxy.PROXY_SEND_RESULT
    elseif "error" == control then
        proxy.response.type     = proxy.MYSQLD_PACKET_ERR
        proxy.response.errmsg   = param0
        proxy.response.errcode  = param1
        proxy.response.sqlstate = param2

        return proxy.PROXY_SEND_RESULT
    end

    assert(nil)
end
