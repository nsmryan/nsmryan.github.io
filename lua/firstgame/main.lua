Timer  = require "hump.timer"
Rot    = require "rotLove.src.rot"
vector = require "hump.vector"

function love.load()
  height = 640
  width = 820

  startingDots = 10
  maxVel = 40
  maxRot = 0.01
  maxDots = 10000

  canvas = love.graphics.newCanvas(width, height)

  white = Rot.Color.fromString("white")
  black = Rot.Color.fromString("black")

  clearColor = black
  polyColor  = white

  love.mouse.setVisible(false)

  cursorTimer = Timer.new()
  cursorEffectTime = 0.15
  cursorSizeIncrements = 5
  cursorSizeMax = 5
  cursorSize = cursorSizeMax
  cursorSizeHandle = nil

  dotTimer = Timer.new()
  dotTimer:every(1.0, splitDots)

  points = {}
  points.numItems = 0

  polygons = {}
  polygons.numItems = 0

  dots = {}
  numDots = 0
  for ix = 1,startingDots do
    dotX = love.math.random(0, width)
    dotY = love.math.random(0, height)
    dots[{dotX, dotY}] = {["vel"] = randomNormalized()}
    numDots = numDots + 1
  end

end

function randomNormalized()
    return vector(love.math.random(), love.math.random()):normalized()
end

function splitDots()
  local newDots = {}

  for pos,dot in pairs(dots) do
    newDots[pos] = dot
    if numDots < maxDots then
      newDots[{pos[1] + 1, pos[2]}] = { ["vel"] = vector(dot.vel.x, dot.vel.y)}
      numDots = numDots + 1
    end
  end

  dots = newDots
end

function toLine(ps)
  local result = {}

  for ix=1,ps.numItems do
    result[2*ix - 1]   = ps[ix][1]
    result[2*ix] = ps[ix][2]
  end

  return result
end

function cursorSizeFunc(wait)
  for sizeIx = 1,cursorSizeIncrements do
    cursorSize = 1 + cursorSizeMax * ((cursorSizeIncrements - sizeIx) / cursorSizeIncrements)
    wait(cursorEffectTime / cursorSizeIncrements)
  end
end

function love.mousepressed(x, y, button, isTouch)
  if button == 1 then
    if cursorSizeHandle ~= nil then
      cursorTimer:cancel(cursorSizeHandle)
    end
    cursorSizeHandle = cursorTimer:script(cursorSizeFunc)

  elseif button == 2 then
    points.numItems = points.numItems + 1
    points[points.numItems] = {x,y}

    polygons.numItems = polygons.numItems + 1
    polygons[polygons.numItems] = points
    points = {}
    points.numItems = 0

  end
end

function love.mousereleased(x, y, button, isTouch)
  if button == 1 then
    points.numItems = points.numItems + 1
    points[points.numItems] = {x,y}
    cursorSize = cursorSizeMax
  end
end

function love.update(dt)
  local newDots = {}
  local rot
  local dot
  local newPos
  local numItems = 0

  cursorTimer:update(dt)
  dotTimer:update(dt)

  for pos, dot in pairs(dots) do
    rot = love.math.random(-maxRot, maxRot)
    dot.vel:rotateInplace(rot)
  end

  numDots = 0
  for pos, dot in pairs(dots) do
    newPos = {pos[1] + dot.vel.x*dt * maxVel, pos[2] + dot.vel.y*dt * maxVel}
    if newPos[1] > 0 and newPos[2] > 0 and newPos[1] < width and newPos[2] < height then
      newDots[newPos] = dot
      numDots = numDots + 1
    end
  end
  dots = newDots

end

function love.draw()
  mX, mY = love.mouse.getPosition()

  love.graphics.setCanvas(canvas)
  love.graphics.clear(clearColor)

  -- draw line to mouse
  love.graphics.setColor(polyColor)
  if points.numItems > 0 then
    love.graphics.line(points[points.numItems][1], points[points.numItems][2], mX, mY)
  end

  -- draw lines
  if points.numItems > 1 then
    lineCoords = toLine(points)
    love.graphics.line(lineCoords)
  end

  -- draw polygons
  if polygons.numItems > 0 then
    for ix, poly in ipairs(polygons) do
      love.graphics.polygon("fill", toLine(poly))
    end
  end

  -- draw dots
  for pos, dot in pairs(dots) do
    love.graphics.points(pos[1], pos[2])
  end

  love.graphics.setCanvas()

  love.graphics.clear(clearColor)
  love.graphics.draw(canvas)
  love.graphics.setColor(polyColor)
  love.graphics.circle("line", mX, mY, cursorSize, 100)
end
