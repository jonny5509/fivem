# xToys Self Control

A client-side FiveM resource that detects selected local gameplay events and sends commands directly from the player's NUI to their private xToys webhook.

## Important installation limitation

This is a **FiveM resource**, not a standalone GTA V ASI/plugin. FiveM servers control which resources are started and distributed. The server must load this resource for its client script and NUI to run. Copying this folder into your personal FiveM cache or GTA V mods folder will not make it automatically run on arbitrary servers.

This project deliberately does not inject into or patch the FiveM process, bypass anti-cheat, or hide itself from server protections. It is intended for servers that permit the resource.

## Install (server administrator)

1. Copy the `xtoys_self_control` folder into the server's `resources` directory.
2. Add `ensure xtoys_self_control` to `server.cfg`.
3. Restart the resource/server.
4. Join the server and press **F7** or run `/xtoys`.
5. Enter your private xToys webhook ID and press **Connect**.
6. Press **F8** or run `/xtoysstop` for an emergency stop. This pauses gameplay triggers.

## Controls

- **F7** or `/xtoys` — open the in-game menu.
- **F8** or `/xtoysstop` — emergency stop and pause gameplay triggers.
- `/xtoysconnect YOUR_PRIVATE_WEBHOOK_ID` — connect from chat.
- `/xtoysdebug on|off|resume|status` — debug logging and trigger state.
- The menu toggle can pause or resume gameplay feedback.
- `/xtoyspartner SERVER_ID` — invite a nearby player to share events.
- `/xtoyspartneraccept SERVER_ID` or `/xtoyspartnerdecline SERVER_ID` — accept or decline an invitation.
- `/xtoyspartnerstop` — end the pairing.

Key bindings can be changed in FiveM's Key Bindings settings.

## Detected events

- Shooting: a pulse when firing starts; sustained fire refreshes while firing.
- Damage: when the local player is the damaged entity.
- Explosions: the GTA/FiveM shocking-explosion game event.
- Vehicle impacts: significant speed loss or collision detection while in a vehicle.
- Falls/ragdoll: when the local ped enters a fall or ragdoll state.
- Melee: when the local ped enters melee combat.

Detection is best-effort and depends on FiveM/GTA event availability and the server/build. Some server-custom events or gameplay situations may not be exposed to this client resource. It is not guaranteed to detect every shot, hit, explosion, crash or fall.

## Partner sharing

Partner sharing is opt-in. One player invites another with their FiveM server ID; the recipient must accept. Paired players share gameplay pulses and bollard impacts only while they remain within the configured range (15 metres by default). Either player can end sharing with `/xtoyspartnerstop`. The server checks distance when relaying events and ends the pairing when players move out of range or disconnect. Both players need this resource running and gameplay triggers enabled to receive effects.

## xToys connection

The NUI opens a WebSocket to `wss://webhook.xtoys.app/<webhookid>` and sends `setintensity` with `intensity` and `seconds`, or `stop`. Configure your xToys Script to handle those actions. Keep the webhook ID private: anyone who obtains it may be able to send commands to that webhook.

## Configuration

Edit `config.lua` to change intensities, durations, cooldowns, polling frequency and event toggles. Values are clamped to the configured maximum intensity and duration.

## Safety and testing

- Test with low intensity first.
- The emergency stop requires the client, NUI, network connection and xToys service to be functioning; it cannot guarantee a physical stop if one of those components fails.
- This repository change has not been runtime-tested against your server artifact or xToys device.
- Partner sharing and bollard relay have not been runtime-tested on your server; test with two consenting players at low intensity.
