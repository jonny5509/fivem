# xToys Self Control (client-only FiveM resource)

A small standalone resource that connects one player's private XToys webhook and uses that player's own GTA/FiveM gameplay events to trigger their own toy.

There is no multiplayer pairing, trusted-partner system, Special Partner role, QIUI integration, server.lua, framework dependency, or server-side command relay.

## Installation

This is a **client-script-only** FiveM resource, but standard FiveM servers still distribute and start resources through the server's resource manifest:

1. Put the `xtoys_self_control` folder in the FiveM server's `resources` directory.
2. Add `ensure xtoys_self_control` to `server.cfg`.
3. Restart the resource/server.
4. In game, run `/xtoys` to open the local menu.
5. Enter your own private XToys webhook ID and press Connect, or run `/xtoysconnect YOUR_WEBHOOK_ID`.
6. Use `/xtoysstop` for an emergency stop.

Only `client.lua` runs gameplay detection. There is no `server.lua`; no player IDs, pairing data, or webhook credentials are sent to a custom server script. A player cannot independently install an arbitrary FiveM resource onto a server they do not control; the server owner/admin must add and ensure the resource so clients receive it.

## XToys setup

The NUI connects to `wss://webhook.xtoys.app/<webhookid>`. Create a private webhook in XToys and configure your XToys Script to respond to:

- `{"action":"setintensity","intensity":20,"seconds":2}`
- `{"action":"stop"}`

The actual toy response depends on your XToys Script configuration. The webhook ID is held in NUI memory only and must be entered again after a resource/UI restart. Use a private webhook; the browser WebSocket API cannot attach the custom Authorization header required by shared webhooks.

## Gameplay triggers

- Shooting: a random-duration pulse for the first shot; automatic fire is refreshed while firing and stopped when firing ends.
- Damage: pulse when the local player is the damaged entity.
- Explosions: pulse on the relevant GTA game event.
- Vehicle impacts: pulse on a significant sudden speed drop while in a vehicle.
- Falls/ragdolls: pulse while falling or ragdolling, subject to the shared event cooldown.
- Melee: pulse when entering melee combat.

Ordinary running and footsteps are intentionally excluded. Event detection and game-event argument behaviour can vary by FiveM/GTA build. Tune values and enable/disable triggers in `config.lua`.

## Safety and limitations

- Self Control can be paused in the menu; pausing sends a stop command.
- `/xtoysstop` and the menu emergency stop send an immediate stop command.
- The resource has not been runtime-tested against your server artifact or physical toy.
- The game client can only send the stop command while the resource and NUI are running and connected. It cannot guarantee physical toy state if the game, browser UI, network, phone, webhook, or toy disconnects.
