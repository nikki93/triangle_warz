require 'libs'
local server = cs.server

local serpent = require 'https://raw.githubusercontent.com/pkulchenko/serpent/522a6239f25997b101c585c0daf6a15b7e37fad9/src/serpent.lua'

local W, H = 800, 600 -- Game world size

server.enabled = true
server.start('22122')

local share = server.share
local mys = server.homes

function server.load()
    share.triangles = {}
    share.bullets = {}
end

function server.connect(id)
    print('client ' .. id .. ' connected')
end

function server.disconnect(id)
    print('client ' .. id .. ' disconnected')
end

function server.update(dt)
end

function server.changed(id, diff)
--    print(serpent.block(diff))
end
