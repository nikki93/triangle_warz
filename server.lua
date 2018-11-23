require 'libs'
local server = cs.server

local serpent = require 'https://raw.githubusercontent.com/pkulchenko/serpent/522a6239f25997b101c585c0daf6a15b7e37fad9/src/serpent.lua'

local W, H = 800, 600 -- Game world size

server.enabled = true
server.start('22122')

local share = server.share
local homes = server.homes

function server.load()
    share.triangles = {}
    share.bullets = {}
end

function server.connect(id)
    share.triangles[id] = {
        x = math.random(0, W),
        y = math.random(0, H),
        r = math.random(),
        g = math.random(),
        b = math.random(),
        targetX = 0,
        targetY = 0,
    }
end

function server.disconnect(id)
end

function server.update(dt)
    for id, home in pairs(homes) do
        local tri = share.triangles[id]
        tri.targetX, tri.targetY = home.targetX, home.targetY
    end
end
