# Basic Barebones for Dota 2 Modding

Original BMDdota's Barebones can be found [here](https://github.com/bmddota/barebones).

If you have some questions for me, contact me on ModDota discord or through mail: darko1290@gmail.com.

### Version 2.1.1.

## Introduction
Barebones is meant to be a jumping off point for creating a custom game with all the basic stuff taken care of for you.
Barebones sets up the necessary files to create a basic custom game (from a scripting persective), allowing you to simply find the places to put your Lua logic in order for you custom game to operate.
Barebones currently provides limited examples for performing different tasks, and limited examples for unit/ability/item creation.
Barebones divides scripts up into several sections: Core Files, Libraries and Examples.

## Installation
Barebones can be installed by downloading this git repository and ensuring that you merge the "content" and "game" folder from this repo with your own "content" and "game" folders.  These should be located in your "<SteamLibraryDirectory>\SteamApps\common\dota 2 beta\" folder.

## Core Files
Core Files are the primary files which you should modify in order to get your basic game mode up and running. There are 4 major files:

#### settings.lua
This file contains many special settings/properties that allows you to define the high-level behavior of your game mode.
You can define things like respawn times, number of teams on the map etc.  Each property is commented to help you understand it.

#### addon_game_mode.lua
This is the entry-point to your game mode and should be used primarily to precache models/particles/sounds/etc.

#### gamemode.lua
This is the primary barebones gamemode script and should be used to assist in initializing your game mode.
This file contains helpful pseudo-event functions prepared for you for frequently needed initialization actions.

#### events.lua
This file contains a hooked version of most useful events that are fired by DotA 2 Engine.
You can drop your event functions in there to have your game mode react to events.

## Libraries
BMDdota included some libraries with barebones that may prove useful in your game mode. Some of them are outdated or obsolete.

#### timers.lua [by BMDdota](https://github.com/bmddota)
This library allow for easily delayed/timed actions without the messiness of thinkers and dealing with pauses. Most valuable library in here.
See [libraries/timers.lua](https://github.com/DarkoniusXNG/barebones/tree/source2/game/dota_addons/barebones/scripts/vscripts/libraries/timers.lua) for usage details and examples.

#### physics.lua [by BMDdota](https://github.com/bmddota)
This library can be used for advanced physics/motion/collision of units. Outdated.
See [PhysicsReadme.md](https://github.com/DarkoniusXNG/barebones/blob/source2/PhysicsReadme.md) for more information.

#### projectiles.lua [by BMDdota](https://github.com/bmddota)
This library can be used for advanced 3D projectile systems. Outdated.
See [ProjectilesReadme.md](https://github.com/DarkoniusXNG/barebones/blob/source2/ProjectilesReadme.md) for more information.

#### notifications.lua [by BMDdota](https://github.com/bmddota)
This library can be used to send panorama notifications to players/teams/everyone in your game.  
See [libraries/notifications.lua](https://github.com/DarkoniusXNG/barebones/tree/source2/game/dota_addons/barebones/scripts/vscripts/libraries/notifications.lua) for usage details and examples.

#### animations.lua [by BMDdota](https://github.com/bmddota)
This library can be used to start animations with customized animation rates, activities, and translations. Obsolete.
See [libraries/animations.lua](https://github.com/DarkoniusXNG/barebones/tree/source2/game/dota_addons/barebones/scripts/vscripts/libraries/animations.lua) for usage details and examples.

#### attachments.lua [by BMDdota](https://github.com/bmddota)
This library can be used to set up and put in place 'Frankenstein' attachments for attaching props to units. Outdated.
See [libraries/attachments.lua](https://github.com/DarkoniusXNG/barebones/tree/source2/game/dota_addons/barebones/scripts/vscripts/libraries/attachments.lua) for usage details and examples.

#### selection.lua [by Noya](https://github.com/MNoya)
This library allows for querying and managing the selection status of players from the server-side lua script.  It also allows for automatic redirection and selection event handling.
See [libraries/selection.lua](https://github.com/DarkoniusXNG/barebones/tree/source2/game/dota_addons/barebones/scripts/vscripts/libraries/selection.lua) for usage details and examples.  

#### playertables.lua [by BMDdota](https://github.com/bmddota)
This library sets up tables that are shared between server (lua) and client (javascript) between specific (but changeable) clients. Similar to nettables. Outdated.
See [libraries/playertables.lua](https://github.com/DarkoniusXNG/barebones/tree/source2/game/dota_addons/barebones/scripts/vscripts/libraries/playertables.lua) for usage details and examples.

#### playerresource.lua
This library extends CDOTA_PlayerResource. It adds methods (functions) and handles (tables) that are important for detecting disconnected/abandoned players and for assigning heroes to players. 
It may become obsolete in the future, but currently its one of the core libraries.

#### buildings.lua
Library for custom made buildings using npc_dota_creature as BaseClass. Not finished but maybe it has some useful code. Use in combination with: https://github.com/MNoya/BuildingHelper
See [libraries/buildings.lua](https://github.com/DarkoniusXNG/barebones/tree/source2/game/dota_addons/barebones/scripts/vscripts/libraries/buildings.lua) for more information.

#### custom_illusions.lua
Library for custom made illusions. Obsolete. Made when CreateIllusions method didn't exist.
See [libraries/custom_illusions.lua](https://github.com/DarkoniusXNG/barebones/tree/source2/game/dota_addons/barebones/scripts/vscripts/libraries/custom_illusions.lua) for usage details.

#### worldpanels.lua [by BMDdota](https://github.com/bmddota)
This library allows for creating panorama layout panels that track the world position of an entity (or fixed world coordinate). Outdated.
See [libraries/worldpanels.lua](https://github.com/DarkoniusXNG/barebones/tree/source2/game/dota_addons/barebones/scripts/vscripts/libraries/worldpanels.lua) for usage details and examples.

## Debugging
This version of Barebones now only prints out (spams) debugging information when told to by setting the USE_DEBUG in settings.lua to true.

## Additional Information
- Barebones also comes with a sample loading screen implementation in panorama which you can view and edit via the content panorama directory.
- You can change the name of the multiteams used at the Game Setup screen by editing addon_english.txt file.
- You can adjust the number of players allowed on each of your maps by editing both addoninfo.txt (lobby) and settings.lua (in-game).
- DOTA 2 Scripting API on Server and Client (RIP ark120202): https://moddota.com/api/#!/vscripts
- Official Dota 2 Scripting API: https://developer.valvesoftware.com/wiki/Dota_2_Workshop_Tools/Scripting/API
- ModDota Dota 2 Scripting API (maintained by Sinz) http://docs.moddota.com/
- Dota 2 custom game template made with TypeScript: https://github.com/ModDota/TypeScriptAddonTemplate

If you have any questions or concerns, contact me on ModDota discord (@Darkonius) or via mail (darko1290@gmail.com).
