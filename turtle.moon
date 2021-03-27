-- turtle.moon
-- SFZILabs 2021

escape = (s) ->
    escaped = s\gsub('\n','\\n')\gsub('\"','\\\"')
    '\"' .. escaped .. '\"'

stringify = (t, state = {}) ->
    s = ''
    keys = [i for i, v in pairs t when 'table' != type v]
    table.insert keys, i for i, v in pairs t when 'table' == type v
    return s if #keys == 0

    push = (c) -> s ..= c

    idx = 1
    len = #keys
    for i, k in pairs keys
        v = t[k]

        switch type v
            when 'function'
                continue

        last = i == len
        match = false

        switch type k
            when 'number'
                if idx == k
                    idx += 1
                    match = true
                else error 'mixed tables are not supported!'
            when 'table', 'function', 'boolean'
                error 'tables/funcs/bools cannot be keys'
            when 'string'
                push escape k
            else error 'unsupported key:' .. type k

        unless match
            unless type(v) == 'table' 
                push ':'

        switch type v
            when 'table'
                push 'v' .. stringify v
            when 'number'
                push tostring v
            when 'string'
                push escape v

        unless last
            push ','

    s ..= '^'
    s

unescape = (s) -> s\gsub('\\n','\n')\gsub('\\"','\"')

parse = (s, r = {}) ->
    chars = s

    if 'string' == type s
        chars = [s\sub i, i for i = 1, #s]

    tok = ''

    shift = -> table.remove chars, 1 
    peek = -> chars[1]
    push = (s) -> tok ..= s
    done = (s = '') ->
        a = tok
        tok = s
        a

    escaped = false
    inQuote = false
    
    key = nil
    isObject = false

    while #chars > 0
        c = shift!
        if inQuote
            if c == '"'
                if escaped
                    escaped = false
                    push c
                else
                    inQuote = false
                    val = unescape done!
                    -- print 
                    if isObject
                        if key
                            r[key] = val
                            -- print key,'->',val
                            key = nil
                        else
                            -- print 'k =',val
                            key = val
                    else
                        if key == nil
                            key = val
                            -- print 'key[array?]:',val

            elseif c == '\\'
                escaped = true
                push c
            else
                escaped = false
                push c
        elseif c == '"' -- start quote
            inQuote = true
        elseif c == 'v' -- go down
            x = {}
            parse chars, x
            if key
                r[key] = x
                if isObject
                    key = nil
            else
                if isObject
                    error 'no key'
                else
                    key = 1
                    r[key] = x
        elseif c == '^' -- breakout
            return r
        elseif c == ':'
            isObject = true
        elseif c == ',' -- next
            if tonumber key
                key += 1
            elseif isObject == false
                key = 1

        elseif tonumber c
            done c
            while true
                n = peek!
                if n == '.' or tonumber n
                    push shift!
                else break

            s = done!
            if c = tonumber s
                
                if key == nil
                    if isObject
                        error 'no key for '..s..' '..table.concat chars, ''
                    else key = 1
                -- assert key, 'no key for '..s..' '..table.concat chars, ''
                -- print c, key
                if key
                    r[key] = c
                    if isObject
                        key = nil
            else error 'invalid number: '..s..' '..table.concat chars, ''

    r

T =
    test: 123
    hey: 'sup'
    ['helo world']:
        tbl: 1
        bah: {{1},{2}}
        z: {2, 3, {a: 15}}
        hey: 'test'

s = stringify T
O = parse s
