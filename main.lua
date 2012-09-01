assert(love, "Run this inside Love")

local Level = require('level')
local point = require('point')

love.physics.setMeter(32)

local level = Level.new{
   "..........######.........",
   "..........#..............",
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
   ".........................",
   ".*********...............",
   "........................."
}

function love.load()
   math.randomseed(os.time())
end

function love.draw()
   level:draw()
end

function love.update(dt)
   level:update(dt)
end
