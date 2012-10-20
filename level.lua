module(..., package.seeall)

local SIZE = 32

local Map = require('map')
local EntityManager = require('entity_manager')
local EffectManager = require('effect_manager')

function mixin(mod, mix_name)
   local mix = require(mix_name)

   for k, v in pairs(mix) do
      if mod[k] and type(v) == 'function' then
         error("Name collision mixing in " .. mix_name .. ": " .. k)
      else mod[k] = v end
   end
end

methods = setmetatable({}, {__index=Map.methods})

mixin(methods, 'create_entities')
mixin(methods, 'drawing')
mixin(methods, 'physics')
mixin(methods, 'handlers')

function new(strs)
   -- All the numeric indices, to map
   local m = {}
   for _,r in ipairs(strs) do m[#m+1] = r end

   -- All str indices, to specials
   local specials = {}
   for k,v in pairs(strs) do
      if type(k) ~= 'number' then specials[k]=v end
   end

   local tbl = Map.new_from_strings(m)
   getmetatable(tbl).__index = methods
   tbl:init(specials)
   return tbl
end

function methods:init(specials)
   self.world = love.physics.newWorld(0, 0)
   self.manager = EntityManager.new(self.world)
   self.effect_manager = EffectManager.new()
   self.gem_count = 0

   self.messages = {} -- Map from point to msg structure
   -- A message looks like: {"text", dx=1, dy=2}

   self.enemies = {} -- Array of Enemies

   self:makeEdges()
   self:makeWalls()
   self:makeCrates()
   self:makeGems()
   self:makeSpecials(specials)
   self.goal = self:makeGoal()
   self.player = self:makePlayer()

   self:addHandlers()
end
