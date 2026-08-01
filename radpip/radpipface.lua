local RadioPipFace = {}
RadioPipFace.__index = RadioPipFace

function RadioPipFace.new(config)
    config = config or {}
    local self = setmetatable({}, RadioPipFace)

    self.x = config.x or 0
    self.y = config.y or 0
    self.width = config.width or 72
    self.height = config.height or 56

    -- Eye Dimensions
    self.eyeW = config.eyeWidth or 14
    self.eyeH = config.eyeHeight or 18
    self.eyeGap = config.eyeGap or 12

    -- Internal state management
    self.state = "SLEEP"
    self.currentEyeH = 2

    self.isWaking = false
    self.blinkState = 0 -- 0: open, 1: closing, 2: closed, 3: opening
    self.blinkTimer = 0

    self.isSleeping = false
    self.sleepState = 0
    self.sleepTimer = 0

    return self
end

function RadioPipFace:_drawEye(x, y, w, h, expr)
    if expr == "HAPPY" then
        -- Happy / Curved Arch eyes ^ ^
        for i = 0, 3 do
            lcd.drawLine(x - w / 2, y + i, x, y - h / 2 + i, SOLID, FORCE)
            lcd.drawLine(x, y - h / 2 + i, x + w / 2, y + i, SOLID, FORCE)
        end
        -- elseif expr == "SLEEP" then
        --     -- Closed / Sleeping eyes - -
        --     lcd.drawFilledRectangle(x - w / 2, y, w, 3, SOLID)
    elseif expr == "SURPRISE" then
        -- Round wide open eyes O O
        lcd.drawRectangle(x - w / 2, y - h / 2, w, h, SOLID)
        lcd.drawRectangle(x - w / 2 + 2, y - h / 2 + 2, w - 4, h - 4, SOLID)
    else
        -- Standard / Normal eyes
        lcd.drawFilledRectangle(x - w / 2, y - h / 2, w, h, SOLID)
        -- Eye catchlight highlight
        if h > 6 then
            lcd.drawFilledRectangle(x + w / 2 - 4, y - h / 2 + 2, 2, 2, ERASE)
        end
    end
end

function RadioPipFace:_drawMouth(x, y, w, h, expr)
    if expr == "HAPPY" then
        -- Happy / Smiling mouth
        lcd.drawLine(x - w / 2, y + h / 4, x, y + h / 2, SOLID, FORCE)
        lcd.drawLine(x, y + h / 2, x + w / 2, y + h / 4, SOLID, FORCE)
    elseif expr == "SLEEP" then
        -- Closed / Sleeping mouth
        if self.isSleeping then
            lcd.drawText(x - 4, y - 4, "O", MIDSIZE);
        else
            lcd.drawLine(x - w / 2, y + h / 4, x + w / 2, y + h / 4, SOLID, FORCE)
        end
    elseif expr == "SAD" then
        -- Sad / Frowning mouth
        lcd.drawLine(x - w / 2, y + h / 2, x, y + h / 4, SOLID, FORCE)
        lcd.drawLine(x, y + h / 4, x + w / 2, y + h / 2, SOLID, FORCE)
    else
        -- Neutral mouth
        lcd.drawLine(x - w / 2, y + h / 4, x + w / 2, y + h / 4, SOLID, FORCE)
    end
end

function RadioPipFace:_drawMisc(x, y, w, h, expr)
    if expr == "SLEEP" then
        if not self.isSleeping then
            if self.sleepState == 1 then
                lcd.drawText(x, y + 7, "Z")
            elseif self.sleepState == 2 then
                lcd.drawText(x + 7, y, "Z")
            else
                -- draw nothing
            end
        end
    end
end

function RadioPipFace:setExpression(expression)
    if self.state == "SLEEP" and expression == "NORMAL" then
        self.isWaking = true
        self.currentEyeH = 2
        self.state = expression
    elseif self.isWaking then
        expression = "NORMAL"
    elseif self.state ~= "SLEEP" and expression == "SLEEP" then
        self.isSleeping = true
        self.currentEyeH = self.eyeH
        self.state = expression
    elseif self.isSleeping then
        expression = "SLEEP"
    else
        self.state = expression
    end
end

function RadioPipFace:update()
    local now = getTime()

    -- Eye animation logic
    if self.state == "SLEEP" then
        if self.isSleeping then
            self.sleepState = 0
            self.currentEyeH = self.currentEyeH - 2
            if self.currentEyeH <= 2 then
                self.currentEyeH = 2
                self.isSleeping = false
                self.sleepTimer = now
            end
        else
            local sleepCycle = (now - self.sleepTimer) % 600
            if sleepCycle < 200 then
                self.sleepState = 0
            elseif sleepCycle < 400 then
                self.sleepState = 1
            else
                self.sleepState = 2
            end
        end
    elseif self.state == "NORMAL" then
        if self.isWaking then
            self.currentEyeH = self.currentEyeH + 2
            if self.currentEyeH >= self.eyeH then
                self.currentEyeH = self.eyeH
                self.isWaking = false
            end
        else
            if self.blinkState == 0 then
                self.currentEyeH = self.eyeH
                if now > self.blinkTimer then
                    self.blinkState = 1
                end
            elseif self.blinkState == 1 then
                self.currentEyeH = self.currentEyeH - 4
                if self.currentEyeH <= 2 then
                    self.currentEyeH = 2
                    self.blinkState = 2
                end
            elseif self.blinkState == 2 then
                self.blinkState = 3
            elseif self.blinkState == 3 then
                self.currentEyeH = self.currentEyeH + 4
                if self.currentEyeH >= self.eyeH then
                    self.currentEyeH = self.eyeH
                    self.blinkState = 0
                    self.blinkTimer = now + math.random(200, 500)
                end
            end
        end
    else
        self.currentEyeH = self.eyeH
    end
end

function RadioPipFace:draw(x, y)
    local ox = x or self.x
    local oy = y or self.y

    local centerX = ox + (self.width / 2)
    local centerY = oy + (self.height / 2)

    local leftX = centerX - (self.eyeGap / 2) - (self.eyeW / 2)
    local rightX = centerX + (self.eyeGap / 2) + (self.eyeW / 2)
    local eyeY = centerY - 4
    local mouthY = centerY + 10

    lcd.drawText(4, 4, self.state, SMLSIZE);


    if self.state == "HAPPY" then
        self:_drawEye(leftX, eyeY, self.eyeW, self.eyeH, "HAPPY")
        self:_drawEye(rightX, eyeY, self.eyeW, self.eyeH, "HAPPY")
        self:_drawMouth(centerX, mouthY, 20, 10, "HAPPY")
    elseif self.state == "SLEEP" then
        self:_drawEye(leftX, eyeY, self.eyeW, self.currentEyeH, "SLEEP")
        self:_drawEye(rightX, eyeY, self.eyeW, self.currentEyeH, "SLEEP")
        self:_drawMouth(centerX, mouthY, 20, 10, "SLEEP")
        self:_drawMisc(centerX + 22, eyeY - 16, 10, 10, "SLEEP")
    elseif self.state == "SURPRISE" then
        self:_drawEye(leftX, eyeY, self.eyeW + 2, self.eyeH + 2, "SURPRISE")
        self:_drawEye(rightX, eyeY, self.eyeW + 2, self.eyeH + 2, "SURPRISE")
        self:_drawMouth(centerX, mouthY, 20, 10, "SURPRISE")
    else
        self:_drawEye(leftX, eyeY, self.eyeW, self.currentEyeH, "NORMAL")
        self:_drawEye(rightX, eyeY, self.eyeW, self.currentEyeH, "NORMAL")
        self:_drawMouth(centerX, mouthY, 20, 10, "NORMAL")
    end
end

return RadioPipFace
