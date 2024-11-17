--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Dvaered Colonel Escort">
 <unique />
 <priority>4</priority>
 <chance>86</chance>
 <location>Bar</location>
 <faction>Dvaered</faction>
</mission>
--]]
--[[

   Mission: Escort a Dvaered colonel
   Description: Small mission where you escort a Dvaered Arsenal.
                This is a one-off that's not part of any major
                storyline; the in-game purpose will remain a mystery.

--]]

local escort = require "escort"
local fleet = require "fleet"
local fmt = require "format"
local neu = require "neutral"
local vn = require "vn"
local vni = require "vnimage"

local reward = 0

local dest_planet = spob.getS("Adham")

local ffriendly, fhostile -- codespell:ignore ffriendly

local npc_name = _("Dvaered Colonel")
local npc_portrait = nil
local npc_image = nil
function create()
   mem.npc_image, mem.npc_portrait = vni.dvaeredMilitary()
   misn.setNPC(npc_name, npc_portrait, _("A Dvaered, very professional-looking, is sitting with an excellant posture at the bar.") )
end

function accept()
   local accepted = false
   vn.clear()
   vn.scene()
   local m = vn.newCharacter( npc_name {image=npc_image} )
   vn.transition()
   m(fmt.f([[As you approach, the Dvaered soldier stands. "Hello, captain {playername}!" they say. "Nice to see you around here. How's it going?"]]))
     {playername=player.name()}
   vn.menu{
      {_([["Quite well, thank you!"]]), "well"},
      {_([["I guess it's going alright."]]), "fine"},
   }

   vn.label("well")
   m(_([["Wonderful! Glad you're having a good time."]]))
   vn.jump("mission description")

   vn.label("fine")
   m(_([["As long as there's no trouble..."]]))
   vn.jump("mission description")

   vn.label("mission description")
   m(fmt.f([["Well, to the point. I need somebody to escort me and my Arsenal to {pnt}. Would you be willing to do that? I can't tell you why."]]))
     {pnt=mem.dest_planet}
   vn.menu{
      {_([["Remind me what system that's in?"]]), "what system"},
      {_([["I'd be happy to do that!"]]), "sure"},
      {_([["What is your name?"]]), "what is your name"},
   }

   vn.label("what system")
   m(fmt.f([["Umm..." the Dvaered says. They consult a watch. "Alright, {pnt} is in {sys}."]]))
     {pnt=mem.dest_planet, sys=mem.dest_sys}
   vn.jump("choice")

   vn.label("what is your name")
   m(_([[The Dvaered seems slightly taken aback. "Well... that may be classified information... call me Radver."]]))
   vn.jump("choice")

   vn.label("sure")
   m(_([["Wonderful! I'll be on your ship when you leave."]]))
   vn.func( function ()
      accepted = true
   end )

   vn.run()

   vn.label("choice")
   m(_([["Well? Will you do this?"]]))
   vn.menu{
      {_([["Yep, I'd be glad to!"]]), "sure"},
      {_([["Not going to happen, sorry."]]), "never"},
   }

   vn.label("never")
   m(_([["That's sad. Oh well, I'll ask someone else." The Dvaered leaves.]]))
   vn.done()

   if not accepted then return end

   misn.accept()

   misn.setReward(750000)
   misn.setDesc(fmt.f(_("Escort a Dvaered colonel, who is flying an Arsenal, to {pnt} in the {sys} system. You haven't been told why, but there may be a large payment."), {pnt=mem.dest_planet, sys=mem.dest_sys}))
   misn.osdCreate(_("Dvaered colonel escort"), {
      fmt.f(_("Escort a Dvaered colonel to {pnt} in the {sys} system.")), {pnt=mem.dest_planet, sys=mem.dest_sys},
   })
   misn.markerAdd( mem.dest_planet )
   hook.land( "land" )
   local colonel_ship = ship.get("Dvaered Arsenal")
   escort.init ( colonel_ship, {
         pilot.add( "Dvaered Arsenal", "ffriendly", source_system, name )
   })

   hook.enter( "ambush" )
end

function ambush ()
   if not naev.claimTest( system.cur(), true ) then return end
   local dvaered_factions = faction.get("Dvaered")

   fhostile = faction.dynAdd( dvaered_factions, "warlords_hostile", _("Warlords") )
   ffriendly = faction.dynAdd( dvaered_factions, "warlords_friendly", _("Warlords") ) -- codespell:ignore ffriendly
   faction.dynEnemy( ffriendly, fhostile ) -- codespell:ignore ffriendly

   pilot.add( "Dvaered Phalanx", "fhostile", source_system, name )
end

function land ()
   if spob.cur() == dest_planet then
      vn.msg( fmt.f(_([[As you land on {pnt} with the Arsenal close behind, you receive an intercom message. "Thank you for bringing me here!" says the colonel. "Here is {reward}, as we agreed. Have safe travels!"]]), {pnt=dest_planet, reward=reward}) )
      player.pay( reward )
      neu.addMiscLog( fmt.f(_([[You escorted a Dvaered colonel who was flying an Arsenal to {pnt}. For some reason, they didn't tell you why.]]), {pnt=dest_planet} ) )
      misn.finish( true )
   end
end
