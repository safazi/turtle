local escape
escape = function(s)
  local escaped = s:gsub('\n', '\\n'):gsub('\"', '\\\"')
  return '\"' .. escaped .. '\"'
end
local stringify
stringify = function(t, state)
  if state == nil then
    state = { }
  end
  local s = ''
  local keys
  do
    local _accum_0 = { }
    local _len_0 = 1
    for i, v in pairs(t) do
      if 'table' ~= type(v) then
        _accum_0[_len_0] = i
        _len_0 = _len_0 + 1
      end
    end
    keys = _accum_0
  end
  for i, v in pairs(t) do
    if 'table' == type(v) then
      table.insert(keys, i)
    end
  end
  if #keys == 0 then
    return s
  end
  local push
  push = function(c)
    s = s .. c
  end
  local idx = 1
  local len = #keys
  for i, k in pairs(keys) do
    local _continue_0 = false
    repeat
      local v = t[k]
      local _exp_0 = type(v)
      if 'function' == _exp_0 then
        _continue_0 = true
        break
      end
      local last = i == len
      local match = false
      local _exp_1 = type(k)
      if 'number' == _exp_1 then
        if idx == k then
          idx = idx + 1
          match = true
        else
          error('mixed tables are not supported!')
        end
      elseif 'table' == _exp_1 or 'function' == _exp_1 or 'boolean' == _exp_1 then
        error('tables/funcs/bools cannot be keys')
      elseif 'string' == _exp_1 then
        push(escape(k))
      else
        error('unsupported key:' .. type(k))
      end
      if not (match) then
        if not (type(v) == 'table') then
          push(':')
        end
      end
      local _exp_2 = type(v)
      if 'table' == _exp_2 then
        push('v' .. stringify(v))
      elseif 'number' == _exp_2 then
        push(tostring(v))
      elseif 'string' == _exp_2 then
        push(escape(v))
      end
      if not (last) then
        push(',')
      end
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
  s = s .. '^'
  return s
end
local unescape
unescape = function(s)
  return s:gsub('\\n', '\n'):gsub('\\"', '\"')
end
local parse
parse = function(s, r)
  if r == nil then
    r = { }
  end
  local chars = s
  if 'string' == type(s) then
    do
      local _accum_0 = { }
      local _len_0 = 1
      for i = 1, #s do
        _accum_0[_len_0] = s:sub(i, i)
        _len_0 = _len_0 + 1
      end
      chars = _accum_0
    end
  end
  local tok = ''
  local shift
  shift = function()
    return table.remove(chars, 1)
  end
  local peek
  peek = function()
    return chars[1]
  end
  local push
  push = function(s)
    tok = tok .. s
  end
  local done
  done = function(s)
    if s == nil then
      s = ''
    end
    local a = tok
    tok = s
    return a
  end
  local escaped = false
  local inQuote = false
  local key = nil
  local isObject = false
  while #chars > 0 do
    local c = shift()
    if inQuote then
      if c == '"' then
        if escaped then
          escaped = false
          push(c)
        else
          inQuote = false
          local val = unescape(done())
          if isObject then
            if key then
              r[key] = val
              key = nil
            else
              key = val
            end
          else
            if key == nil then
              key = val
            end
          end
        end
      elseif c == '\\' then
        escaped = true
        push(c)
      else
        escaped = false
        push(c)
      end
    elseif c == '"' then
      inQuote = true
    elseif c == 'v' then
      local x = { }
      parse(chars, x)
      if key then
        r[key] = x
        if isObject then
          key = nil
        end
      else
        if isObject then
          error('no key')
        else
          key = 1
          r[key] = x
        end
      end
    elseif c == '^' then
      return r
    elseif c == ':' then
      isObject = true
    elseif c == ',' then
      if tonumber(key) then
        key = key + 1
      elseif isObject == false then
        key = 1
      end
    elseif tonumber(c) then
      done(c)
      while true do
        local n = peek()
        if n == '.' or tonumber(n) then
          push(shift())
        else
          break
        end
      end
      s = done()
      do
        c = tonumber(s)
        if c then
          if key == nil then
            if isObject then
              error('no key for ' .. s .. ' ' .. table.concat(chars, ''))
            else
              key = 1
            end
          end
          if key then
            r[key] = c
            if isObject then
              key = nil
            end
          end
        else
          error('invalid number: ' .. s .. ' ' .. table.concat(chars, ''))
        end
      end
    end
  end
  return r
end
local T = {
  test = 123,
  hey = 'sup',
  ['helo world'] = {
    tbl = 1,
    bah = {
      {
        1
      },
      {
        2
      }
    },
    z = {
      2,
      3,
      {
        a = 15
      }
    },
    hey = 'test'
  }
}
local s = stringify(T)
local O = parse(s)
