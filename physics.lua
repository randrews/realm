module(..., package.seeall)

local SIZE = 32
local methods = _M

function methods:update(dt) 
   local k = love.keyboard.isDown
   local kd = 0 -- num of keys down
   local dir = point(0, 0)

   local p = self.player

   if k('up') then dir = dir + point.up ; kd = kd + 1 end
   if k('down') then dir = dir + point.down ; kd = kd + 1 end
   if k('left') then dir = dir + point.left ; kd = kd + 1 end
   if k('right') then dir = dir + point.right ; kd = kd + 1 end

   if kd > 0 then
      p.body:setLinearDamping(0)
   else
      p.body:setLinearDamping(8)
   end

   local f = dir * SIZE * 15
   self.player.body:applyForce(f())

   p.location = point(
      math.floor(p.body:getX() / SIZE),
      math.floor(p.body:getY() / SIZE))

   if kd == 1 then
      p.direction = dir
      dampenSidewaysVelocity(p.body, p.direction, dt)
   end

   if kd > 0 then
      p.target = p.location + dir
   end

   for _, c in ipairs(self.manager:find('crate')) do
      local sq = point(
         math.floor(c.body:getX() / SIZE),
         math.floor(c.body:getY() / SIZE))
      nudgeToSquare(c.body, sq, SIZE)
   end

   max_speed(p.body, SIZE * 10)
   self.manager:cull()
   self.world:update(dt)
   self.effect_manager:update(dt)
end

------------------------------------------------------------

function nudgeToSquare(body, sq, acc)
   local y = body:getY() - SIZE/2
   local ty = sq.y * SIZE
   local f = acc * (ty - y)
   body:applyForce(0, f)

   local x = body:getX() - SIZE/2
   local tx = sq.x * SIZE
   local f = acc * (tx - x)
   body:applyForce(f, 0)
end

function dampenSidewaysVelocity(body, dir, dt)
   local v = point(body:getLinearVelocity())
   local a = 1 - 8 * dt
   if a > 1.0 then a = 1.0 elseif a < 0 then a = 0 end

   if dir.y == 0 then v.y = v.y * a end
   if dir.x == 0 then v.x = v.x * a end

   body:setLinearVelocity(v())
end

function max_speed(body, spd)
   local x, y = body:getLinearVelocity()
   if x*x + y*y > spd*spd then
      local a = math.atan2(y,x)
      body:setLinearVelocity(spd * math.cos(a),
                             spd * math.sin(a))
   end
end
