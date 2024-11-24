--[[
   Some sort of Ionic storm-type background.
--]]
local graphics = require "love.graphics"
local bgshaders = require "bkg.lib.bgshaders"
local love_shaders = require 'love_shaders'
local lf = require 'love.filesystem'
-- We use the default background too!
require "bkg.default"

local shader, sf, sstorm

local background_default = background
function background ()
   -- Scale factor that controls computation cost. As this shader is really
   -- really expensive, we can't compute it at full resolution
   sf = bgshaders.scale_factor_default()

   -- Initialize shader
   local pixelcode = lf.read( "bkg/shaders/ionicstorm.frag" )
   shader = graphics.newShader( pixelcode, love_shaders.vertexcode )
   shader._dt = -1000 * rnd.rnd()
   shader.update = function( self, dt )
      self._dt = self._dt + dt
      self:send( "u_time", self._dt )
   end
   sstorm = bgshaders.init( shader, sf )

   -- Default nebula background
   background_default()

   -- Ambient light is coloured now
   gfx.lightAmbient( 0.9, 0.475, 0.95, 0.2, 1.5 )
   gfx.lightIntensity( 0.6 * gfx.lightIntensityGet() )
end

function renderfg( dt )
   -- Get camera properties
   local x, y, z = camera.get()
   local m = 0.5
   shader:send( "u_camera", x*m/sf, -y*m/sf, (1-m)+m*z )

   sstorm:render( dt )
end
