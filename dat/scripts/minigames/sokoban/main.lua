local love = require 'love'
local lg = require 'love.graphics'

local player            = '@'
local playerOnStorage   = '+'
local box               = '$'
local boxOnStorage      = '*'
local storage           = '.'
local wall              = '#'
local empty             = ' '
local emptyOut          = 'x'
local colours = {
--[[ original colours
   [player]          = {0.64, 0.53, 1.00},
   [playerOnStorage] = {0.62, 0.47, 1.00},
   [box]             = {1.00, 0.79, 0.49},
   [boxOnStorage]    = {0.59, 1.00, 0.50},
   [storage]         = {0.61, 0.90, 1.00},
   [wall]            = {1.00, 0.58, 0.82},
   [empty]           = {1.00, 1.00, 0.75},
--]]
   [empty]           = {0x00/0xFF, 0x00/0xFF, 0x00/0xFF}, -- darkest
   [player]          = {0x1C/0xFF, 0x30/0xFF, 0x4A/0xFF},
   [playerOnStorage] = {0x1C/0xFF, 0x30/0xFF, 0x4A/0xFF}, -- same as player
   [storage]         = {0x04/0xFF, 0x6B/0xFF, 0x99/0xFF},
   [box]             = {0x00/0xFF, 0xCF/0xFF, 0xFF/0xFF},
   [boxOnStorage]    = {0xB3/0xFF, 0xEF/0xFF, 0xFF/0xFF},
   [wall]            = {0xFF/0xFF, 0xFF/0xFF, 0xFF/0xFF}, -- lightest
}
local coloursText = {
   [empty]           = {0xFF/0xFF, 0xFF/0xFF, 0xFF/0xFF},
   [player]          = {0xFF/0xFF, 0xFF/0xFF, 0xFF/0xFF},
   [playerOnStorage] = {0xFF/0xFF, 0xFF/0xFF, 0xFF/0xFF},
   [storage]         = {0xFF/0xFF, 0xFF/0xFF, 0xFF/0xFF},
   [box]             = {0x00/0xFF, 0x00/0xFF, 0x00/0xFF},
   [boxOnStorage]    = {0x00/0xFF, 0x00/0xFF, 0x00/0xFF},
   [wall]            = {0x00/0xFF, 0x00/0xFF, 0x00/0xFF},
}
local cellSize = 30
local levels = require "levels"
local level, currentLevel
local lx, ly

local function loadLevel()
   local w = 0
   local h
   local lw, lh = love.window.getDesktopDimensions()

   local loadlev = levels[ currentLevel ]
   h = #loadlev
   for y, row in ipairs( loadlev ) do
      w = math.max( w, #row )
   end

   -- Build up empty level
   level = {}
   for y=1,h do
      level[y] = {}
      for x=1,w do
         level[y][x] = ' '
      end
   end

   -- Load level data
   for y, row in ipairs( loadlev ) do
      for x, cell in ipairs(row) do
         level[y][x] = cell
      end
   end

   -- Remove edges
   for y=1,h do
      for x=1,w do
         if level[y][x] ~= empty then
            break
         end
         level[y][x] = emptyOut
      end
      for x=w,1,-1 do
         if level[y][x] ~= empty then
            break
         end
         level[y][x] = emptyOut
      end
   end
   for x=1,w do
      for y=1,h do
         if level[y][x] ~= empty and level[y][x] ~= emptyOut then
            break
         end
         level[y][x] = emptyOut
      end
      for y=h,1,-1 do
         if level[y][x] ~= empty and level[y][x] ~= emptyOut then
            break
         end
         level[y][x] = emptyOut
      end
   end

   lx = (lw - cellSize * w)/2
   ly = (lh - cellSize * h)/2
end

function love.load()
   lg.setBackgroundColor(0, 0, 0, 0.5)
   lg.setNewFont( 16 )

   currentLevel = 1

   loadLevel()
end

function love.keypressed( key )
   if key=="q" or key=="escape" then
      love.event.quit()
   end
   if key == 'up' or key == 'down' or key == 'left' or key == 'right' then
      local playerX
      local playerY

      for testY, row in ipairs(level) do
         for testX, cell in ipairs(row) do
            if cell == player or cell == playerOnStorage then
               playerX = testX
               playerY = testY
            end
         end
      end

      local dx = 0
      local dy = 0
      if key == 'left' then
         dx = -1
      elseif key == 'right' then
         dx = 1
      elseif key == 'up' then
         dy = -1
      elseif key == 'down' then
         dy = 1
      end

      local current = level[playerY][playerX]
      local adjacent = level[playerY + dy][playerX + dx]
      local beyond
      if level[playerY + dy + dy] then
         beyond = level[playerY + dy + dy][playerX + dx + dx]
      end

      local nextAdjacent = {
         [empty] = player,
         [storage] = playerOnStorage,
      }

      local nextCurrent = {
         [player] = empty,
         [playerOnStorage] = storage,
      }

      local nextBeyond = {
         [empty] = box,
         [storage] = boxOnStorage,
      }

      local nextAdjacentPush = {
         [box] = player,
         [boxOnStorage] = playerOnStorage,
      }

      if nextAdjacent[adjacent] then
         level[playerY][playerX] = nextCurrent[current]
         level[playerY + dy][playerX + dx] = nextAdjacent[adjacent]

      elseif nextBeyond[beyond] and nextAdjacentPush[adjacent] then
         level[playerY][playerX] = nextCurrent[current]
         level[playerY + dy][playerX + dx] = nextAdjacentPush[adjacent]
         level[playerY + dy + dy][playerX + dx + dx] = nextBeyond[beyond]
      end

      local complete = true

      for y, row in ipairs(level) do
         for x, cell in ipairs(row) do
            if cell == box then
               complete = false
            end
         end
      end

      if complete then
         currentLevel = currentLevel + 1
         if currentLevel > #levels then
            currentLevel = 1
         end
         loadLevel()
      end

   elseif key == 'r' then
      loadLevel()

   end
end

function love.draw()
   for y, row in ipairs(level) do
      for x, cell in ipairs(row) do
         if cell ~= emptyOut then
            lg.setColor( colours[cell] )
            lg.rectangle(
               'fill',
               lx + (x - 1) * cellSize,
               ly + (y - 1) * cellSize,
               cellSize,
               cellSize
            )
            lg.setColor( coloursText[cell] )
            lg.print(
               level[y][x],
               lx + (x - 1) * cellSize,
               ly + (y - 1) * cellSize
            )
         end
      end
   end
end
