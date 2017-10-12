--------------------------------------------------------------------------------
-- Includes --
local gui = require("imgui")

local cpml = require("lib/cpml")
local vec2 = cpml.vec2

local lume = require("lib/lume")

local hc = require("lib/HC")

local flux = require("lib/flux")

local class = require('lib/middleclass/middleclass')

local gamera = require('lib/gamera/gamera')

local sti = require('lib/sti')

local annoy = require('annoy')

local inspect = require('lib/inspect/inspect')

local colors = require('lib/colors')

local lovetoys = require('lib/lovetoys/lovetoys')
lovetoys.initialize()


-------------------------------------------------------------------------------
-- TODO --
-- Steering should either not use physics (try this first) or should track desired
-- velocity with controller, or rotate velocity but not effect acceleration, or
-- add a separate component to velocity somehow

-------------------------------------------------------------------------------
-- Settings --
local gravity = -9.8

-------------------------------------------------------------------------------
-- Utils --
function setColorHSL(hsl)
  local color = hsl:to_rgb()
  color = string.sub(color, 2)
  love.graphics.setColor(tonumber(color:sub(1,2), 16),
                         tonumber(color:sub(3,4), 16),
                         tonumber(color:sub(5,6), 16))
end

--------------------------------------------------------------------------------
-- Components --

-- Player Component
local Player =
    lovetoys.Component.create("Player",
                              {"grounded"},
                              {grounded = false})

-- Position Component
local Position =
    lovetoys.Component.create("Position",
                              { "pos" },
                              { pos = vec2(0.0,0.0) })

-- Steer Component
local Steer =
    lovetoys.Component.create("Steer",
                              { "heading", "vel" },
                              { heading = vec2(0.0,0.0), vel = vec2(1.0, 1.0) })

-- Flocking Component
local Flocking =
    lovetoys.Component.create("Flocking",
                              { "flock" },
                              { flock = {} })

-- Collision Component
local Collision =
    lovetoys.Component.create("Collision")

function Collision:initialize(shape, checkCollisions)
  self.shape = shape
  self.checkCollisions = checkCollisions
  self.collisions = {}
end

-- Cursor Component
local Cursor =
    lovetoys.Component.create("Cursor",
                              { "mode" },
                              { mode = "trail" })
-- Cursor Trail Component
local CursorTrail =
    lovetoys.Component.create("CursorTrail")

function CursorTrail:initialize(n, speed, radius)
  self.n = n
  self.speed = speed
  self.radius = radius
  self.trail = {}
end

-- NN Component
local NN =
    lovetoys.Component.create("NN",
                              {"neighbors"},
                              {neighbors = {}})

-- FPS Component
local FPS =
    lovetoys.Component.create("FPS",
                              {"fps"},
                              {fps = {}})

-- Spring Component
local Spring =
    lovetoys.Component.create("Spring",
                              {"k", "p", "targets", "nomDist"},
                              {k = 0.001, p = 0.001, targets = {}, nomDist = 10})

-- Separate Component
local Separate =
    lovetoys.Component.create("Separate",
                              {"coeff", "sepDist"},
                              {coeff = 0.01, sepDist = 10})

-- Cohesion Component
local Cohesion =
    lovetoys.Component.create("Cohesion",
                              {"coeff", "centroid", "vec"},
                              {coeff = 0.1, centroid = vec2(0.0,0.0), vec = vec2(0.0,0.0)})

-- Align Component
local Align =
    lovetoys.Component.create("Align",
                              {"coeff"},
                              {coeff = 1})
 
-- Physics Component
local Physics =
    lovetoys.Component.create("Physics",
                              {"acc", "vel"},
                              {acc  = vec2(0.0,0.0), vel = vec2(0.0,0.0)})

--------------------------------------------------------------------------------
-- Systems --

-- Player System
local PlayerSystem = class("PlayerSystem", lovetoys.System)

function PlayerSystem:update(dt)
  platforms = engine:getEntitiesWithComponent("Platform")

  player = self.targets[1]
end

function PlayerSystem:draw(dt)
  --love.graphics.rectangle("fill", 100, 100, 10, 20)
end

function PlayerSystem:requires()
  return {"Position", "Player"}
end

-- Collision System
local CollisionSystem = class("CollisionSystem", lovetoys.System)

function CollisionSystem:requires()
  return {"Collision"}
end

function CollisionSystem:update(dt)
  -- TODO set collision information in collision components
end

function CollisionSystem:draw(dt)
  -- TODO add debugging draw calls. put these in separate canvas
end

-- NN System
local NNSystem = class("NNSystem", lovetoys.System)

function NNSystem:initialize(numNeighbors, numTrees)
  lovetoys.System:initialize()
  self.numNeighbors = numNeighbors 
  self.numTrees = numTrees
end

function NNSystem:requires()
  return {"Position", "NN"}
end

function NNSystem:draw(dt)
  status, self.numNeighbors = imgui.SliderFloat("Number of Neighbors", self.numNeighbors, 0, 25)
  status, self.numTrees = imgui.SliderFloat("Number of Trees", self.numTrees, 0, 25)

  nnIndex = annoy.AnnoyIndex(2, "euclidean")

  for key, neighbor in pairs(self.targets) do
    neighborPosition = neighbor:get("Position")
    nnIndex:add_item(key, {neighborPosition.pos.x, neighborPosition.pos.y})
  end
  nnIndex:build(self.numTrees)

  for key, neighbor in pairs(self.targets) do
    nn = neighbor:get("NN")
    position = neighbor:get("Position")

    nearKeys = nnIndex:get_nns_by_item(key, self.numNeighbors + 1)

    neighborhood = {}
    for index, nearKey in ipairs(nearKeys) do
      nearest = self.targets[nearKey]
      if nearKey ~= key then
        table.insert(neighborhood, nearest)
        nearPos = nearest:get("Position")
        love.graphics.setColor(0xFF, 0xFF, 0xFF)
        love.graphics.line(position.pos.x, position.pos.y, nearPos.pos.x, nearPos.pos.y)
      end
    end
    nn.neighbors = neighborhood
  end
end

-- Physics System
local PhysicsSystem = class("PhysicsSystem", lovetoys.System)

function PhysicsSystem:requires()
  return {"Position", "Physics"}
end

function PhysicsSystem:update(dt)
  for key, entity in pairs(self.targets) do
    position = entity:get("Position")
    physics  = entity:get("Physics")

    physics.acc.x = cpml.utils.clamp(physics.acc.x, -10, 10)
    physics.acc.y = cpml.utils.clamp(physics.acc.y, -10, 10)

    physics.vel.x = cpml.utils.clamp(physics.vel.x, -50, 50)
    physics.vel.y = cpml.utils.clamp(physics.vel.y, -50, 50)

    physics.vel.x = physics.vel.x + physics.acc.x * dt
    physics.vel.y = physics.vel.y + physics.acc.y * dt

    position.pos.x = position.pos.x + physics.vel.x * dt + 0.5 * physics.acc.x * math.pow(dt, 2)
    position.pos.y = position.pos.y + physics.vel.y * dt + 0.5 * physics.acc.y * math.pow(dt, 2)
  end
end

function PhysicsSystem:draw(dt)
  index = 1
  love.graphics.setColor(0x00, 0xFF, 00)
  for key, entity in pairs(self.targets) do
    position = entity:get("Position")
    physics  = entity:get("Physics")
    index = index + 1
  end
end

-- Steer System
local SteerSystem = class("SteerSystem", lovetoys.System)

function SteerSystem:requires()
  return {"Steer", "Position"}
end

function SteerSystem:update(dt)
  for key, entity in pairs(self.targets) do
    steer = entity:get("Steer")
    pos   = entity:get("Position")

    pos.pos = pos.pos + vec2.normalize(steer.heading) * steer.vel
    steer.heading = vec2(0,0)
  end
end

function SteerSystem:draw(dt)
  for key, entity in pairs(self.targets) do
    pos = entity:get("Position")
    steer = entity:get("Steer")

    love.graphics.line(pos.pos.x,
                       pos.pos.y,
                       pos.pos.x + steer.heading.x * steer.vel.x,
                       pos.pos.y + steer.heading.y * steer.vel.y)
  end
end

-- Separation System
local SeparationSystem = class("SeparationSystem", lovetoys.System)

function SeparationSystem:requires()
  return {"Separate", "Position", "NN", "Steer"}
end

function SeparationSystem:update(dt)
  for key, entity in pairs(self.targets) do
    local sep   = entity:get("Separate")
    local pos   = entity:get("Position")
    local nn    = entity:get("NN")
    local steer = entity:get("Steer")

    local neighbors = nn.neighbors

    if neighbors and #neighbors > 0 then

      local seps = vec2(0.0, 0.0)
      for index, neighbor in ipairs(neighbors) do
        neighborPos = neighbor:get("Position")
        sepVec = vec2.sub(pos.pos, neighborPos.pos)
        distTo = vec2.len(sepVec)
        if  distTo > 0 and distTo < sep.sepDist then
          sepVec = vec2.normalize(sepVec) * vec2.len(sepVec)
          seps = seps + sepVec
        end
      end
      seps = vec2.normalize(seps)
      sepVel = dt * sep.coeff
      steer.heading = steer.heading + seps * sepVel
    end
  end
end

function SeparationSystem:draw(dt)
end

-- Cohesion System
local CohesionSystem = class("CohesionSystem", lovetoys.System)

function CohesionSystem:requires()
  return {"Separate", "Physics", "Position", "NN", "Steer"}
end

function CohesionSystem:update(dt)
  for key, entity in pairs(self.targets) do
    local coh  = entity:get("Cohesion")
    local pos  = entity:get("Position")
    local nn   = entity:get("NN")
    local steer = entity:get("Steer")

    neighbors = nn.neighbors

    if neighbors and #neighbors > 0 then

      localCentroid = vec2(0.0, 0.0)
      for index, neighbor in ipairs(neighbors) do
        neighborPos = neighbor:get("Position")
        localCentroid = vec2.add(localCentroid, neighborPos.pos)
      end
      localCentroid = localCentroid * (1.0 / (#neighbors))
      coh.centroid = localCentroid

      toCenter = vec2.normalize(localCentroid - pos.pos)
      cohAcc = dt * coh.coeff
      coh.vec = toCenter * cohAcc
      steer.heading = steer.heading + coh.vec
    end
  end
end

function CohesionSystem:draw(dt)
  for key, entity in pairs(self.targets) do
    coh = entity:get("Cohesion")
    pos = entity:get("Position")
    
    love.graphics.setColor(0xFF, 0xFF, 0xFF)
    love.graphics.line(pos.pos.x, pos.pos.y, pos.pos.x + coh.vec.x, pos.pos.y + coh.vec.y)
  end
end

-- Align System
local AlignSystem = class("AlignSystem", lovetoys.System)

function AlignSystem:requires()
  return {"Align", "Position", "NN", "Steer"}
end

function AlignSystem:update(dt)
  for key, entity in pairs(self.targets) do
    local align  = entity:get("Align")
    local pos    = entity:get("Position")
    local nn     = entity:get("NN")
    local steer  = entity:get("Steer")

    local otherSteer = nil

    neighbors = nn.neighbors

    if neighbors and #neighbors > 0 then

      avgAlign = vec2(0.0, 0.0)
      for index, neighbor in ipairs(neighbors) do
        otherSteer = neighbor:get("Steer")
        avgAlign = avgAlign + otherSteer.heading
      end
      avgAlign = vec2.normalize(avgAlign)

      alignAcc = dt * align.coeff
      alignVec = avgAlign * alignAcc
      steer.heading = steer.heading + alignVec
    end
  end
end

function AlignSystem:draw(dt)
  -- TODO draw alignment debugging stuff
end

-- FPS System
local FPSSystem = class("FPSSystem", lovetoys.System)

function FPSSystem:requires()
  return {"FPS"}
end

function FPSSystem:update()
  for key, entity in pairs(self.targets) do
    fpsComponent = entity:get("FPS")
    if not fpsComponent.fps then
      fpsComponent.fps = {}
    end
    table.insert(fpsComponent.fps, love.timer.getFPS())
    if #fpsComponent.fps > 100 then
      table.remove(fpsComponent.fps, 1)
    end
  end
end

function FPSSystem:draw()
  for key, entity in pairs(self.targets) do
    fpsComponent = entity:get("FPS")
    imgui.PlotLines("FPS", fpsComponent.fps, #fpsComponent.fps, 0, "FPS", 0, 100, 500, 50)
  end
end

-- Spring System
local SpringSystem = class("SpringSystem", lovetoys.System)

function SpringSystem:requires()
  return {"Spring"}
end

function spring(k, p, m, x, v, dt)
  return -1 * (m / math.pow(dt, 2))  * k * x - (m / dt) * p * v
end

function SpringSystem:draw(dt)
  for index, cursor in pairs(self.targets) do
    springComponent = cursor:get("Spring")
    t0 = springComponent.targets[1]
    t1 = springComponent.targets[2]

    t0Pos = t0:get("Position")
    t1Pos = t1:get("Position")

    love.graphics.setColor(0xFF, 0xFF, 0xFF)
    love.graphics.circle("fill", t0Pos.pos.x, t0Pos.pos.y, 10)
    love.graphics.circle("fill", t1Pos.pos.x, t1Pos.pos.y, 10)
  end
end

function SpringSystem:update(dt)
  for index, cursor in pairs(self.targets) do
    springComponent = cursor:get("Spring")

    t0 = springComponent.targets[1]
    t1 = springComponent.targets[2]

    t0Pos = t0:get("Position")
    t1Pos = t1:get("Position")

    t0Phys = t0:get("Physics")
    t1Phys = t1:get("Physics")

    vel0 = t0Phys.vel
    vel1 = t1Phys.vel

    dist  = vec2.dist2(t0Pos.pos, t1Pos.pos) - springComponent.nomDist
    angle = vec2.angle_to(t0Pos.pos, t1Pos.pos)

    acc0 = spring(springComponent.k, springComponent.p, 1, dist, vec2.len(vel0), dt)
    acc1 = spring(springComponent.k, springComponent.p, 1, dist, vec2.len(vel1), dt)

    accX0 = acc0 * cos(angle)
    accY0 = acc0 * sin(angle)

    accX1 = acc1 * cos(angle)
    accY1 = acc1 * sin(angle)

    --t0Phys.acc = vec2.add(t0Phys.acc, vec2(accX0, accY0))
    --t1Phys.acc = vec2.add(t1Phys.acc, vec2(accX1, accY1))
  end
end

-- Cursor System
local CursorSystem = class("CursorSystem", lovetoys.System)

function CursorSystem:requires()
  return {"Cursor", "CursorTrail"}
end

function CursorSystem:update(dt)
  for index, cursor in pairs(self.targets) do
    cursorComponent = cursor:get("Cursor")
    cursorTrail = cursor:get("CursorTrail")
    position = cursor:get("Position")

    mx, my = love.mouse.getPosition()
    position.pos = vec2(mx, my)

  end
end

function CursorSystem:draw(dt)
  for index, entity in pairs(self.targets) do
    cursor = entity

    cursorComponent = cursor:get("Cursor")
    cursorTrail     = cursor:get("CursorTrail")
    position        = cursor:get("Position")

    --status, cursorTrail.n      = imgui.SliderInt  ("Trail Length", cursorTrail.n,      0,   100)
    --status, cursorTrail.speed  = imgui.SliderFloat("Trail Speed",  cursorTrail.speed,  0.0, 1.0)
    --status, cursorTrail.radius = imgui.SliderFloat("Trail Radius", cursorTrail.radius, 0.0, 100.0)

    love.mouse.setVisible(cursorComponent.mode == "default")

    currentN = #cursorTrail.trail

    
    local cursorColor = colors.new("#e67e22")
    cursorTints = cursorColor:tints(currentN)

    for index, pos in ipairs(cursorTrail.trail) do
      setColorHSL(cursorTints[currentN - index + 1])
      love.graphics.circle('fill', pos.x, pos.y, cursorTrail.radius * (index / currentN));
    end

    if currentN >= cursorTrail.n then
      for index = 1, currentN do
        cursorTrail.trail[index] = cursorTrail.trail[index + 1]
      end

      -- drop last item from array
      -- TODO replace with insert, remove
      cursorTrail.trail[currentN] = nil
      currentN = #cursorTrail.trail
    end

    for index, pos in ipairs(cursorTrail.trail) do
      if index < currentN then
        cursorTrail.trail[index] = vec2.lerp(pos, cursorTrail.trail[index + 1], cursorTrail.speed)
      end
    end

    if currentN < cursorTrail.n then
      cursorTrail.trail[currentN + 1] = position.pos
    end
  end
end

--------------------------------------------------------------------------------
-- Love Callbacks --
function love.update(dt)
  imgui.NewFrame()
  --map:update()
  flux.update(dt)
  engine:update(dt)
end

function love.draw()
  -- Set up locals
  width = love.graphics.getWidth()
  height = love.graphics.getHeight()
  local winHeight = 0.2 * love.graphics.getHeight()

  -- Set up imgui for this frame
  imgui.SetNextWindowSize(width, winHeight)
  imgui.SetNextWindowPos(0, height - winHeight)
  imgui.Begin("Devel", true, { "AlwaysAutoResize", "NoTitleBar" })

  -- Draw gui

  -- Draw canvas
  love.graphics.setCanvas(canvas)
  love.graphics.clear()
  engine:draw()

  love.graphics.setCanvas()
  love.graphics.clear()
  camera:setPosition(0, 0)
  camera:draw(function(l, t, w, h)
    --map:draw()
    love.graphics.draw(canvas)
  end)
  --love.graphics.draw(charCanvas, 10, 10, 0, 2, 2)
  --love.graphics.draw(image, 40, 40)

  scale = camera:getScale()
  --status, scale  = imgui.SliderFloat("Camera Scale",  scale,  0.0, 10.0)
  camera:setScale(scale)
  --status, thickness  = imgui.SliderFloat("Thickness",  thickness,  0.0, 1.0)
  --status, characterMultiplier  = imgui.SliderFloat("characterMultiplier",  characterMultiplier,  0.0, 10.0)

  for _, pixelPos in ipairs(charPixels) do
    love.graphics.rectangle("fill", pixelPos.x*characterMultiplier + characterPos.x, pixelPos.y*characterMultiplier + characterPos.y, 1, 1)
  end

  -- Render imgui
  imgui.End()
  imgui.Render()
end

function love.textinput(t)
    imgui.TextInput(t)
    if not imgui.GetWantCaptureKeyboard() then
        -- Pass event to the game
  end
end

function love.keypressed(key)
  imgui.KeyPressed(key)
  if not imgui.GetWantCaptureKeyboard() then
      -- Pass event to the game
  end
end

function love.keyreleased(key)
  imgui.KeyReleased(key)

  if not imgui.GetWantCaptureKeyboard() then
    movePlayer()
  end
end

function drawPlayer()
  love.graphics.setCanvas(charCanvas)
  love.graphics.clear()
  love.graphics.print("@", 0, 0, 0, 1, 1)

  charData = charCanvas:newImageData()
  image = love.graphics.newImage(charData)

  if #charPixels == 0 then
    charPixels = {}
    for x = 1, charData:getWidth() do
      for y = 1, charData:getHeight() do
        r, g, b, a = charData:getPixel(x - 1, y - 1)

        if a > 0.5 then
          table.insert(charPixels, vec2(x, y))
        end
      end
    end
  end
  imgui.Text(string.format("number of pixels %d", #charPixels), 1)
  imgui.PlotLines("line", {1,2,3,4,5}, 5, 0, "Line", 0, 100, 500, 100)
end

function movePlayer()
  local changeX = 0
  local changeY = 0
  local wait = false

  if key == "space" then
    normal = not normal
  end

  if key == "up" then
    changeY = -20
  elseif key == "down" then
    changeY = 20
  elseif key == "left" then
    changeX = -20
  elseif key == "right" then
    changeX = 20
  elseif key == "5" then
    wait = true
  end

  if changeX ~= 0 or changeY ~= 0 or wait then
    characterPosTween =
    flux.to(characterPos, 1, { x = characterPos.x + changeX, y = characterPos.y + changeY }):ease('linear')
    reindex = {}
    for index = 1, #charPixels do
      reindex[index] = index
    end

    if not normal then
      reindex = lume.shuffle(reindex)
    end

    for index, pixelPos in ipairs(charPixels) do
      flux.to(pixelPos, 1, { x = charPixels[reindex[index]].x, y = charPixels[reindex[index]].y })
    end
  end
end

function love.mousemoved(x, y)
    imgui.MouseMoved(x, y)
    if not imgui.GetWantCaptureMouse() then
        -- Pass event to the game
    end
end

function love.mousepressed(x, y, button)
    imgui.MousePressed(button)
    if not imgui.GetWantCaptureMouse() then
        -- Pass event to the game
    end
end

function love.mousereleased(x, y, button)
    imgui.MouseReleased(button)
    if not imgui.GetWantCaptureMouse() then
        -- Pass event to the game
    end
end

function love.wheelmoved(x, y)
    imgui.WheelMoved(y)
    if not imgui.GetWantCaptureMouse() then
        -- Pass event to the game
    end
end

function love.load()
  height = love.window.width
  width  = love.window.height

  love.mouse.setVisible(false)

  camera = gamera.new(0, 0, 1024, 1024)
  camera:setPosition(0, 0)

  -- load tile map
  --map = sti("secondgame.lua")

  -- Set up canvas
  canvas = love.graphics.newCanvas(width, height)
  charCanvas = love.graphics.newCanvas(20, 20)
  charPixels = {}
  thickness = 1
  characterPos = vec2(60, 40)
  characterPosTween = flux.to(characterPos, 0, { x = 60, y = 4 }):ease('linear')
  characterMultiplier = 3.0
  normal = true

  -- set up lovetoys
  engine = lovetoys.Engine()

  -- Player System
  playerSystem = PlayerSystem()
  engine:addSystem(playerSystem, "update")
  engine:addSystem(playerSystem, "draw")

  -- Cursor System
  cursorSystem = CursorSystem()
  engine:addSystem(cursorSystem, "update")
  engine:addSystem(cursorSystem, "draw")

  -- NN system
  nnSystem = NNSystem(5, 10)
  engine:addSystem(nnSystem, "draw")

  -- FPS system
  fpsSystem = FPSSystem()
  engine:addSystem(fpsSystem, "draw")
  engine:addSystem(fpsSystem, "update")

  -- Spring System
  --springSystem = SpringSystem()
  --engine:addSystem(springSystem, "draw")
  --engine:addSystem(springSystem, "update")

  -- Physics system
  physicsSystem = PhysicsSystem()
  engine:addSystem(physicsSystem, "draw")
  engine:addSystem(physicsSystem, "update")

  -- Steer system
  steerSystem = SteerSystem()
  engine:addSystem(steerSystem, "draw")
  engine:addSystem(steerSystem, "update")

  -- Separation system
  separationSystem = SeparationSystem()
  engine:addSystem(separationSystem, "draw")
  engine:addSystem(separationSystem, "update")

  -- Cohesion system
  cohesionSystem = CohesionSystem()
  engine:addSystem(cohesionSystem, "draw")
  engine:addSystem(cohesionSystem, "update")

  -- Align system
  alignSystem = AlignSystem()
  engine:addSystem(alignSystem, "draw")
  engine:addSystem(alignSystem, "update")

  -- Player
  player = lovetoys.Entity()
  player:add(Position())
  player:add(Player())
  engine:addEntity(player)

  -- Cursor
  cursor = lovetoys.Entity()
  cursor:add(Cursor())
  cursor:add(CursorTrail(25, 0.5, 8))
  cursor:add(Position())
  engine:addEntity(cursor)

  -- Spring
  --dot0 = lovetoys.Entity()
  --dot0:add(Position(vec2(100, 100)))
  --dot0:add(Physics())
  -- engine:addEntity(dot0)

  --dot1 = lovetoys.Entity()
  --dot1:add(Position(vec2(100, 100)))
  --dot1:add(Physics())
  -- engine:addEntity(dot1)

  --spring = lovetoys.Entity()
  --spring:add(Spring(0.001, 0.001, {dot0, dot1}, 10))
  -- engine:addEntity(spring)

  -- FPS
  fpsList = lovetoys.Entity()
  fpsList:add(FPS())
  engine:addEntity(fpsList)

  -- NN
  for index = 1, 10 do
   startPos = vec2((love.graphics.getWidth()/2) + love.math.random(0.1 * love.graphics.getWidth()),
                        (love.graphics.getHeight()/2) + love.math.random(0.1 * love.graphics.getHeight()))
   startAcc = vec2(love.math.random(-0.1, 0.1),
                        love.math.random(-0.1, 0.1))

    neighbor = lovetoys.Entity()
    neighbor:add(NN())
    neighbor:add(Physics(startAcc, vec2(0, 0)))
    neighbor:add(Separate(0.03, 30))
    neighbor:add(Cohesion(0.03))
    neighbor:add(Position(startPos))
    neighbor:add(Align(1.0))
    neighbor:add(Steer())
    engine:addEntity(neighbor)
  end

  eventmanager = lovetoys.EventManager()
end

