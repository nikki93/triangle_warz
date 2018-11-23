require 'libs'
local client = cs.client

local W, H = 800, 600 -- Game world size
local DISPLAY_SCALE = 1 -- Scale to draw graphics at w.r.t game world units

client.enabled = true
client.start('127.0.0.1:22122')

local share = client.share
local my = client.home

function client.draw()
end

function client.mousemoved(x, y)
    local w, h = DISPLAY_SCALE * W, DISPLAY_SCALE * H
    local ox, oy = 0.5 * (love.graphics.getWidth() - w), 0.5 * (love.graphics.getHeight() - h)
    my.target = {
        x = (x - ox) / DISPLAY_SCALE,
        y = (y - oy) / DISPLAY_SCALE,
    }
end

function client.mousepressed(x, y, button)
    if button == 1 then
        my.wantShoot = true
    end
end

function client.mousereleased(x, y, button)
    if button == 1 then
        my.wantShoot = false
    end
end
