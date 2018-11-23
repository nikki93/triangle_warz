cs = require 'https://raw.githubusercontent.com/expo/share.lua/master/cs.lua'

-- TODO(nikki): Make this work with direct library import...

local oldPairs = pairs
function pairs(t)
    local __table = t.__table
    if __table then
        return oldPairs(__table(t))
    end
    return oldPairs(t)
end

local oldIPairs = ipairs
function ipairs(t)
    local __table = t.__table
    if __table then
        return oldIPairs(__table(t))
    end
    return oldIPairs(t)
end
