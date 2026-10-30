# xToys Self Control

A client-only FiveM resource that detects selected local gameplay events and sends commands directly from the player's NUI to their private XToys webhook.

**Server requirement:** although gameplay logic and webhook communication run on the player's client, a FiveM server must distribute/start this resource. It is not an independent graphics-pack-style client mod.

## Install

1. Place `xtoys_self_control` in the server's resources folder.
2. Add `ensure xtoys_self_control` to `server.cfg`.
3. Restart the resource/server.
4. Join and run `/xtoys`.
5. Enter your private XToys webhook ID, then connect. Alternatively use `/xtoysconnect YOUR_PRIVATE_WEBHOOK_ID`.
6. Use `/xtoysstop` for an emergency stop. This pauses gameplay triggers; use `/xtoysdebug resume` to resume them.

The resource has no `server.lua`, framework dependency, pairing system, trusted-partner role, or QIUI adapter.

## Events

- Shooting: a short pulse on the first detected shot; sustained firing refreshes while firing.
- Damage: when the local player is the damaged entity.
- Explosions: the GTA/FiveM shocking-explosion game event.
- Vehicle collisions: significant speed loss or collision detection while in a vehicle.
- Falls/ragdoll: on entering a fall or ragdoll state.
- Melee: on entering melee combat.

Detection depends on the FiveM/GTA build and game event availability. These are best-effort client-side signals, not guaranteed coverage of every action or server-custom event.

## Local configuration

Edit `config.lua` to change intensity, duration, cooldowns and event toggles. Intensities are capped by `MaxIntensity`; pulse duration is capped by `MaxDurationSeconds`.

Commands:
- `/xtoys` — open the menu.
- `/xtoysconnect YOUR_PRIVATE_WEBHOOK_ID` — connect.
- `/xtoysstop` — emergency stop and pause triggers.
- `/xtoysdebug on|off|resume|status` — debug logging and trigger state.

## XToys

The NUI connects to `wss://webhook.xtoys.app/<webhookid>` and sends `setintensity` with `intensity` and `seconds`, or `stop`. Configure your XToys Script to handle those actions. Use a private webhook ID; anyone who obtains it may be able to control the webhook.

## Local companion

The separate [Windows Local Companion](../xtoys_self_control_companion/README.md) can run without a FiveM resource, but uses manual hotkeys and cannot automatically read gameplay events.

## Safety and testing

Start with low values and test while disconnected from other users. The stop command depends on the client, NUI, network and XToys service being available; it cannot guarantee a physical stop if any of those fail. This resource has not been runtime-tested against your particular server artifact or device.
