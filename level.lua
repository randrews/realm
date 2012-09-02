module(..., package.seeall)

local SIZE = 32

local Map = require('map')
local EntityManager = require('entity_manager')
local EffectManager = require('effect_manager')

function mixin(mod, mix)
   for k, v in pairs(mix) do
      if mod[k] then error("Name collision in mixin: " .. k)
      else mod[k] = v end
   end
end

methods = setmetatable({}, {__index=Map.methods})

local CreateEntities = require('create_entities')
mixin(methods, CreateEntities.methods)

local Drawing = require('drawing')
mixin(methods, Drawing.methods)

local Physics = require('physics')
mixin(methods, Physics.methods)

function new(strs)
   local tbl = Map.new_from_strings(strs)
   getmetatable(tbl).__index = methods
   tbl:init()
   return tbl
end

function methods:init()
   self.world = love.physics.newWorld(0, 0)
   self.manager = EntityManager.new(self.world)
   self.effect_manager = EffectManager.new()
   self.gem_count = 0

   self:makeEdges()
   self:makeWalls()
   self:makeCrates()
   self:makeGems()
   self.goal = self:makeGoal()
   self.player = self:makePlayer()

   self.manager:handler('gem', 'player',
                        function(gem, player)
                           self.player.gem_count = self.player.gem_count + 1
                           self.manager:remove(gem)
                           self.effect_manager:add(EffectManager.puff(gem.body:getX(), gem.body:getY(), gem.body:getAngle()))
                        end)

   self.manager:handler('gem', 'crate',
                        function(gem, crate)
                           local f = SIZE * 15
                           local dx = crate.body:getX() - gem.body:getX()
                           local dy = crate.body:getY() - gem.body:getY()
                           crate.body:applyForce(f*dx, f*dy)
                        end)
end
