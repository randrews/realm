module(..., package.seeall)

methods = {}

function new(world)
   assert(world)
   local tbl = {world=world, needs_cull=false}
   setmetatable(tbl, {__index=methods})
   tbl:init()
   return tbl
end

function methods:init()
   self.entities = {} -- Map from type to array of entities
   -- An entity is a table with a body, a shape, and a type.

   self.handlers = {} -- map from type to {type->function}
   self:applyCollisionHandler()
end

function methods:applyCollisionHandler()
   self.world:setCallbacks(function(...) self.contact(self, ...) end)
end

function methods:add(body, shape, type)
   assert(body and shape and type)
   local f = love.physics.newFixture(body, shape)
   local t = {body=body, shape=shape, type=type}
   f:setUserData(t)

   if not self.entities[type] then self.entities[type] = {} end
   table.insert(self.entities[type], t)
   return f, t
end

function methods:remove(entity)
   entity.remove = true
   self.needs_cull = true
end

function methods:cull()
   if self.needs_cull then
      self.needs_cull = false

      for _, grp in pairs(self.entities) do
         local n = 1
         while n <= #grp do
            if grp[n].remove then
               grp[n].body:destroy()
               table.remove(grp, n)
            else
               n = n + 1
            end
         end
      end
   end
end

function methods:find(type)
   return self.entities[type] or {}
end

function methods:exists(type_a, type_b)
   local handlers = self.handlers
   if handlers[type_a] and handlers[type_a][type_b] then
      return handlers[type_a][type_b]
   elseif handlers[type_b] and handlers[type_b][type_a] then
      return handlers[type_b][type_a], 'reverse'
   end
end

function methods:handler(type_a, type_b, fn)
   if self:exists(type_b, type_a) then self:removeHandler(type_b, type_a) end
   self.handlers[type_a] = self.handlers[type_a] or {}
   self.handlers[type_a][type_b] = fn
end

function methods:removeHandler(type_a, type_b)
   if self.handlers[type_a] then self.handlers[type_a][type_b] = nil end
   if self.handlers[type_b] then self.handlers[type_b][type_a] = nil end
end

function methods:type(fixture)
   assert(fixture)
   local u = fixture:getUserData()
   if u then return u.type end
   return 'unknown'
end

function methods:contact(fix_a, fix_b)
   local type_a = self:type(fix_a)
   local type_b = self:type(fix_b)

   local handler, rev = self:exists(type_a, type_b)
   if handler then
      if rev then fix_a, fix_b = fix_b, fix_a end
      handler(fix_a:getUserData(), fix_b:getUserData())
   end
end
