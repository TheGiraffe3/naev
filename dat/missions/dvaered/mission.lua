--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Escort to a system">
 <unique />
 <priority>1</priority>
 <chance>24</chance>
 <location>Bar</location>
</mission>
--]]
--[[

   MISSION: ESCORT TO A PLANET
   DESCRIPTION: SMALL MISSION WHERE YOU ESCORT A SHIP TO A PLANET: WIP

--]]

local fmt = require "format"
local neu = require "common.neutral"
local vntk = require "vntk"

local misplanet, missys = spob.getS("Ulios")
local credits = 30000

local reward_text = fmt.credits( credits )

function create ()
   mem.talked = false
   --if not misn.claim(missys) then misn.finish(false) end
   misn.setNPC( _("A Dvaered colonel"), "devaered/dv_military_f6.webp", _("This soldier seems to be a colonel.") )
end

function accept ()
   local text
   else
      text = fmt.f(_([[You approach the Dvaered, who seems to be a soldier, probably one of the colonel rank. Arriving at their table, you are greeted, "Hello! Could you escort my ship to {pnt} in the {sys} system? I'll give you {rwd} for it, but I can't tell you why. Well, what do you say?"]]),
         {pnt=misplanet, sys=missys, rwd=reward_text})
      mem.talked = true
   end
   if vntk.yesno( _("Escort Agreed"), text ) then
      vntk.msg( _("Escort Agreed"), _([["Perfect! I'll pay you as soon as we get there.]]) )
      misn.accept()
      misn.setTitle( _("Escort to {pnt}") )
      misn.setReward( reward_text )
      misn.setDesc( fmt.f(_("A Dvaered colonel would like you to escort their ship to {pnt} in the {sys} system. For some reason, you haven't been told why."), {pnt=misplanet, sys=missys}) )
      misn.markerAdd( misplanet, "low" )
      local osd_desc = {}
      osd_desc[1] = fmt.f(_("Fly to {pnt} in the {sys} system"), {pnt=misplanet, sys=missys} )
      misn.osdCreate( _("Escort to {pnt}"), osd_desc )
      hook.land( "land" )
   end
end

function land ()
   if spob.cur() == misplanet then
      vntk.msg( fmt.f(_([[As you land on {pnt} with the ship close behind, you receive an intercom message. "Thank you for bringing me here!" says the colonel. "Here is {reward}, as we agreed. Have safe travels!"]]), {pnt=misplanet, reward=reward_text}) )
      player.pay( credits )
      neu.addMiscLog( fmt.f(_([[You escorted a Dvaered colonel who was flying a ship to {pnt}. For some reason, they didn't tell you why.]]), {pnt=misplanet} ) )
      misn.finish( true )
   end
end
