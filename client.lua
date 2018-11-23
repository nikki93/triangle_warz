require 'libs'
local client = cs.client

local W, H = 800, 600 -- Game world size
local DISPLAY_SCALE = 1 -- Scale to draw graphics at w.r.t game world units

client.enabled = true
client.start('127.0.0.1:22122')

local share = client.share
local home = client.home

function client.load()
    -- We use `home` to send control info
    home.targetX, home.targetY = 0, 0
    home.wantShoot = false
    home.move = { up = false, down = false, left = false, right = false }
end

function client.mousemoved(x, y)
    -- We center and scale the display (see `.draw` below), transform mouse coordinates accordingly
    local w, h = DISPLAY_SCALE * W, DISPLAY_SCALE * H
    local ox, oy = 0.5 * (love.graphics.getWidth() - w), 0.5 * (love.graphics.getHeight() - h)
    home.targetX, home.targetY = (x - ox) / DISPLAY_SCALE, (y - oy) / DISPLAY_SCALE
end

function client.mousepressed(x, y, button)
    if button == 1 then
        home.wantShoot = true
    end
end

function client.mousereleased(x, y, button)
    if button == 1 then
        home.wantShoot = false
    end
end

function client.keypressed(k)
    if k == 'w' then home.move.up = true end
    if k == 's' then home.move.down = true end
    if k == 'a' then home.move.left = true end
    if k == 'd' then home.move.right = true end
end

function client.keyreleased(k)
    if k == 'w' then home.move.up = false end
    if k == 's' then home.move.down = false end
    if k == 'a' then home.move.left = false end
    if k == 'd' then home.move.right = false end
end

function client.draw()
    love.graphics.push('all')

    -- Center and scale display
    local w, h = DISPLAY_SCALE * W, DISPLAY_SCALE * H
    local ox, oy = 0.5 * (love.graphics.getWidth() - w), 0.5 * (love.graphics.getHeight() - h)
    love.graphics.setScissor(ox, oy, w, h)
    love.graphics.translate(ox, oy)
    love.graphics.scale(DISPLAY_SCALE)

    -- Background color
    love.graphics.clear(0.2, 0.216, 0.271)

    if client.connected then
        -- Draw triangles
        for id, tri in pairs(share.triangles) do
            love.graphics.push('all')

            -- Position and rotation
            love.graphics.translate(tri.x, tri.y)
            local targetX, targetY
            if id == client.id then -- If it's us, use `home` data directly
                targetX, targetY = home.targetX, home.targetY
            else
                targetX, targetY = tri.targetX, tri.targetY
            end
            love.graphics.rotate(math.atan2(targetY - tri.y, targetX -  tri.x))

            -- Fill
            love.graphics.setColor(tri.r, tri.g, tri.b)
            love.graphics.polygon('fill', -20, 20, 30, 0, -20, -20)

            -- Outline, thicker if it's us
            love.graphics.setColor(1, 1, 1, 0.8)
            love.graphics.setLineWidth(id == client.id and 3 or 1)
            love.graphics.polygon('line', -20, 20, 30, 0, -20, -20)

            love.graphics.pop()
        end
    else
        love.graphics.print('not connected', 20, 20)
    end

    love.graphics.pop()
end

