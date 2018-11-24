require 'libs'
local client = cs.client

local common = require 'common'

local MOBILE = love.system.getOS() == 'iOS' or love.system.getOS() == 'Android'
local W, H = 800, 600 -- Game world size
local DISPLAY_SCALE = 1 -- Scale to draw graphics at w.r.t game world units

local bulletSound = love.audio.newSource('assets/laser.wav', 'static')
local smallExplosionSound = love.audio.newSource('assets/hurt.wav', 'static')
local bigExplosionSound = love.audio.newSource('assets/explosion.wav', 'static')

client.enabled = true
client.start('207.254.45.246:22122') -- A remote server I test on
--client.start('127.0.0.1:22122') -- Local server

local share = client.share
local home = client.home

function client.load()
    -- Use `home` to store control info so the server can see it
    home.targetX, home.targetY = 0, 0
    home.wantShoot = false
    home.move = { up = false, down = false, left = false, right = false }
end

function client.mousemoved(x, y)
    -- Transform mouse coordinates according to display centering and scaling (see `.draw` below)
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

function client.receive(message)
    if message == 'bulletSound' then
        bulletSound:setPitch(1.4 + 0.3 * math.random())
        bulletSound:stop()
        bulletSound:play()
    elseif message == 'smallExplosionSound' then
        smallExplosionSound:setPitch(1.4 + 0.3 * math.random())
        smallExplosionSound:stop()
        smallExplosionSound:play()
    elseif message == 'bigExplosionSound' then
        bigExplosionSound:setPitch(0.7 + 0.3 * math.random())
        bigExplosionSound:stop()
        bigExplosionSound:play()
    end
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
        -- Triangles
        for clientId, tri in pairs(share.triangles) do
            love.graphics.push('all')
            love.graphics.translate(tri.x, tri.y)

            love.graphics.push() -- Push for rotation
            local targetX, targetY
            if clientId == client.id then -- If it's us, use `home` data directly
                targetX, targetY = home.targetX, home.targetY
            else
                targetX, targetY = tri.targetX, tri.targetY
            end
            love.graphics.rotate(math.atan2(targetY - tri.y, targetX -  tri.x))

            love.graphics.setColor(tri.r, tri.g, tri.b) -- Fill
            love.graphics.polygon('fill', -20, 20, 30, 0, -20, -20)

            love.graphics.setColor(1, 1, 1, 0.8) -- Outline (thicker if it's us)
            love.graphics.setLineWidth(clientId == client.id and 3 or 1)
            love.graphics.polygon('line', -20, 20, 30, 0, -20, -20)

            love.graphics.pop() -- Pop rotation (don't rotate health bar)

            love.graphics.setColor(0, 0, 0, 0.5) -- Health bar
            love.graphics.rectangle('fill', -20, -35, 40, 4)
            love.graphics.setColor(0.933, 0.961, 0.859, 0.5)
            love.graphics.rectangle('fill', -20, -35, tri.health / 100 * 40, 4)

            love.graphics.pop()
        end

        -- Bullets
        for _, bul in pairs(share.bullets) do
            love.graphics.push('all')
            love.graphics.translate(bul.x, bul.y)
            love.graphics.rotate(math.atan2(bul.dirY, bul.dirX))

            love.graphics.setColor(bul.r, bul.g, bul.b) -- Fill
            love.graphics.ellipse('fill', 0, 0, 24, 1)
            love.graphics.setColor(1, 1, 1, 0.38)

            love.graphics.setLineWidth(0.3) -- Outline
            love.graphics.ellipse('line', 0, 0, 24, 1)

            love.graphics.pop()
        end

        -- FPS, ping
        love.graphics.print('fps:  ' .. love.timer.getFPS(), 20, H - 36)
        love.graphics.print('ping: ' .. client.getPing(), 78, H - 36)
    else
        love.graphics.print('not connected', 20, 20)
    end

    love.graphics.pop()
end

function client.update(dt)
    -- Do some client-side prediction
    if client.connected then
        -- Predictively move triangles
        for id, tri in pairs(share.triangles) do
            -- We can use our `home` to apply controls predictively if it's our triangle
            common.move_triangle(tri, dt, id == client.id and home or nil)
        end

        -- Predictively move bullets
        for bulId, bul in pairs(share.bullets) do
            common.move_bullet(bul, dt)
        end
    end

    -- Fake key events sent from a mobile app I'm testing this in -- you can ignore this part
    if MOBILE then
        local pressed = love.thread.getChannel('KEY_PRESSED')
        local released = love.thread.getChannel('KEY_RELEASED')
        while pressed:getCount() > 0 do
            local k = pressed:pop()
            function love.keyboard.isDown(e) return e == k end
            love.keypressed(k)
        end
        while released:getCount() > 0 do
            local k = released:pop()
            function love.keyboard.isDown(e) return false end
            love.keyreleased(k)
        end
    end

    -- Scale down display if window is too small
    local w, h = love.graphics.getDimensions()
    DISPLAY_SCALE = math.min(1, w / W, h / H)
end

-- Quick hack to try local overrides for player input -- will test this more
--function client.changing(diff)
--    if diff.triangles then
--        local myTri = diff.triangles[client.id]
--        if myTri then
--            if myTri.x and share.triangles[client.id].x then
--                myTri.x = 0.98 * share.triangles[client.id].x + 0.02 * myTri.x
--            end
--            if myTri.y and share.triangles[client.id].y then
--                myTri.y = 0.98 * share.triangles[client.id].y + 0.02 * myTri.y
--            end
--        end
--    end
--end
