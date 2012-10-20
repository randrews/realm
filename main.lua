assert(love, "Run this inside Love")

inspect = dofile 'inspect.lua'
local Level = require('level')
local point = require('point')

love.physics.setMeter(32)

local level = Level.new{
   "..........######.........",
   "....1.....#..............",
   "..........#.#............",
   ".....######.#......o.....",
   "............#......o.....",
   ".....##..##.#............",
   "......#..##.#........&...",
   "......#..#....*...#......",
   "...@.........*.*..#.##...",
   "..............*..........",
   ".....#...#.......##.#....",
   "...#...#...#........#....",
   ".....#...#...............",
   "...A................2....",
   ".*********...............",
   ".........................",

   ["1"]={"This\nis a message",
      dx=50, dy=0}, -- Delta from center of marker to top-left of box.

   ["2"]={"This is also a message",
      dx=-200, dy=0},

   A={
      6, 13, -- Waypoint coords
      3, 13
   }
}

function love.load()
   local font = love.graphics.newFont(12)
   love.graphics.setFont(font)
   math.randomseed(os.time())
end

function love.draw()
   level:draw()
end

function love.update(dt)
   level:update(dt)
end
