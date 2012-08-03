module(..., package.seeall)

local Map = require('map')

methods = setmetatable({}, {__index=Map.methods})
local SIZE = 32

function new(strs)
   local tbl = Map.new_from_strings(strs)
   getmetatable(tbl).__index = methods
   tbl:init()
   return tbl
end

function methods:init()
end

function methods:makeEdges(world)
   assert(world)

   local w = SIZE * self.width
   local h = SIZE * self.height

   local edge = {}
   edge.body = love.physics.newBody(world, 0, 0, 'static')
   edge.shapes = {}
   table.insert(edge.shapes, love.physics.newEdgeShape(0, 0, w, 0))
   table.insert(edge.shapes, love.physics.newEdgeShape(0, 0, 0, h))
   table.insert(edge.shapes, love.physics.newEdgeShape(w, h, w, 0))
   table.insert(edge.shapes, love.physics.newEdgeShape(w, h, 0, h))
   for _, s in ipairs(edge.shapes) do love.physics.newFixture(edge.body, s) end
   return edge
end

function methods:makeWalls(world)
   local ph = love.physics
   local walls = ph.newBody(world, 0, 0, 'static')

   for p in self:each() do
      if self(p) == '#' then
         local s = ph.newRectangleShape(p.x*SIZE + SIZE/2, p.y*SIZE + SIZE/2,
                                        SIZE, SIZE)
         ph.newFixture(walls, s)
      end
   end
end

function methods:makePlayer(world)
   local player = {}
   local ph = love.physics

   player.body = ph.newBody(world, SIZE*1.5, SIZE*1.5, 'dynamic')
   player.shape = ph.newCircleShape(10)
   ph.newFixture(player.body, player.shape)

   player.body:setMass(0.01)
   return player
end
