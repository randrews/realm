module(..., package.seeall)

local EffectManager = require('effect_manager')

local SIZE = 32
local methods = _M

local entity_manager = nil
local effect_manager = nil
local level = nil

function methods:addHandlers()
   entity_manager = self.manager
   effect_manager = self.effect_manager
   level = self

   self.manager:handler('gem', 'player', take_gem)
   self.manager:handler('gem', 'crate', pushback_crate)
   self.manager:handler('player', 'enemy', kill_player)
   self.manager:handler('player', 'goal', end_level)
end

------------------------------------------------------------

function pushback_crate(gem, crate)
   local f = 5
   local dx = crate.body:getX() - gem.body:getX()
   local dy = crate.body:getY() - gem.body:getY()
   crate.body:applyLinearImpulse(f*dx, f*dy)
end

function take_gem(gem, player)
   player.gem_count = player.gem_count + 1
   entity_manager:remove(gem)
   effect_manager:add(EffectManager.puff(gem.body:getX(), gem.body:getY(), gem.body:getAngle()))

   if player.gem_count == level.gem_count then open_goal() end
end

function open_goal()
   local goal = entity_manager:find('goal_blocker')[1]

   if goal then
      entity_manager:remove(goal)
      effect_manager:add(EffectManager.fade(goal.body:getX(), goal.body:getY()))
   end
end

function kill_player(player, enemy)
   print("Player died")
end

function end_level(player, goal)
   print("Next level")
end