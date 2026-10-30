# xToys Multiplayer (Standalone FiveM)

A standalone, consent-first xToys multiplayer resource. No ESX, QBCore, framework, or external database dependency.

## Install
1. Put this folder in your server's resources directory.
2. Add `ensure xtoys_multiplayer` to server.cfg.
3. Restart the resource/server.
4. Use `/xtoys` in game to open the menu and print the command list in chat.
5. Use `/xtoyshelp` to print the command list again.
6. Use `/xtoysid YOUR_WEBHOOK_ID` to set your private webhook ID and connect from chat.
7. Use `/xtoysstop` for an emergency stop.
8. Use `/xtoysdebug on` to enable diagnostics, `/xtoysdebug status` to check, and `/xtoysdebug off` to disable.

## XToys setup
Each toy owner creates a **Private Webhook** in XToys and enters its ID in their own menu. Only the device owner's local NUI opens the XToys WebSocket; the ID is never sent to the FiveM server or partner.

XToys documents the WebSocket endpoint as `wss://webhook.xtoys.app/<webhookid>`. Configure an XToys Webhook trigger and a connected XToys Script to respond to:
- `{"action":"setintensity","intensity":20,"seconds":2}`
- `{"action":"stop"}`

The trigger action names are configurable in config.lua. The actual toy behavior must be defined in the XToys Script.

This starter uses private webhooks. XToys shared webhooks require an Authorization Bearer header; the NUI browser WebSocket API cannot attach custom handshake headers. Use a private webhook unless a trusted local bridge handles shared-webhook authentication.

## Trusted partners
- The menu lists nearby players within `Config.NearbyDistanceMeters` (10 metres by default), showing their in-game name, server ID, and distance.
- You can add a nearby player using the list or by entering their server ID. The server checks that they are actually within range.
- The recipient must confirm the first trusted-partner invitation. Both players' consent is required.
- Confirmed trusted partnerships are saved using the players' FiveM `license:` identifiers in server resource KVP storage, so they survive disconnects and server/resource restarts.
- Online trusted partners have a **Control** action in the list. It starts a control session without another approval prompt, provided neither player is paired with someone else.
- Either player can remove the trusted partnership. Removing it also stops an active session between those players.
- Offline trusted partners remain listed and can be removed.

## Standard pairing and control
- Either player can invite another by server ID; the recipient must accept.
- Non-trusted partners must approve every control request.
- Trusted partners are granted control automatically after the first mutual confirmation.
- Only one control direction is active at a time.
- The server clamps intensity to 0-100 and duration to 1-10 seconds.
- Either paired player can emergency-stop or revoke the active pairing.
- Disconnecting either player clears the active pairing and stops the session.
- Only the toy owner needs an XToys connection; the other player only needs to be paired and authorized.

## Debugging and fault reports
- Debug logging is off by default. Enable it in-game with `/xtoysdebug on`; this enables client F8 logs and server-console logs for that player's activity.
- Use `/xtoysdebug status` to check the client setting and `/xtoysdebug off` to disable it.
- Set `Config.Debug = true` in `config.lua` to enable server debug logging globally.
- Logs use the prefixes `[xToys:CLIENT:DEBUG]` and `[xToys:SERVER:DEBUG]`. They include useful event/flow details but deliberately do not print webhook IDs.
- If reporting a fault, send me the exact in-game error/message, the matching F8 and server-console lines, what you were doing immediately before it happened, and whether it happens every time. You can copy the relevant lines; redact player identifiers and any private credentials.

## ERP integration
No ERP integration is included. This resource is focused on xToys only.

## Testing
Test on a private server with two consenting test players. Verify nearby detection, trusted invitation and acceptance, persistence after reconnect/restart, trusted control, removal, ordinary pairing, control approval, emergency stop, and disconnect cleanup. Then test a low-intensity, short-duration XToys action. Ensure the XToys Script has a stop action wired to the `stop` webhook trigger.

## Notes
This resource has not been runtime-tested against your server's artifact build or your specific XToys Script. The server authorizes pairing and commands; it cannot independently confirm physical toy connectivity. Webhook credentials are held in NUI memory only and must be re-entered after a resource/UI restart.


## Advanced control modes
- The menu provides Self Control, Trusted Partner, and One-Time Partner modes. The server enforces the owner-selected mode; switching modes stops active remote control.
- Self Control sends commands only to the local player's own webhook. Shooting is refreshed while firing at the configured intensity (100 by default) and stopped when firing ends. Damage, falls/ragdolls, sudden vehicle deceleration, and explosion game events can produce short pulses.
- Ordinary running and footsteps are intentionally excluded. Gameplay event detection can vary by FiveM/GTA build and must be tested on your server.

## QIUI integration status and required lock policy
- QIUI is OFF by default. The UI only permits enabling if a configured adapter resource is running.
- The exact QIUI model and its documented API/BLE protocol are not yet known. This commit does not guess a protocol and does not send physical lock/unlock commands. The adapter must be implemented for the exact model before device control is available.
- Required future behaviour: no countdown, no scheduled release, and no automatic unlock on disconnect or restart. Unlock only after an explicit authenticated owner or authorised Special Partner action.
- No physical QIUI lock state is currently controlled or persisted by this resource. The QIUI UI is a guarded placeholder, not a working device integration.

## Special Partner
- One exclusive Special Partner per owner, chosen from already trusted partners.
- Owner sends offer; recipient accepts or declines; an accepted offer only takes effect after the owner confirms it.
- Offer expiry is configurable (48 hours by default). Declines and expiry leave the existing assignment unchanged.
- If the assigned partner is offline for 72 consecutive hours, their role expires and control returns to the owner. The owner is notified and may offer the role to someone else or leave it disabled.
- Owner can revoke the role at any time. Ordinary trusted partners do not gain Special Partner status.
- This role workflow is permission bookkeeping only. It does not yet send Cellmate 2 lock/unlock commands.


## QIUI Cellmate 2 hardware boundary
- The Cellmate 2 setup guide documents control through the QIUI app and describes locking on app disconnection. No official public developer API/SDK or protocol was located for direct FiveM control.
- The resource therefore does not attempt reverse-engineered BLE/cloud commands. QIUI stays disabled by default; the current panel is a guarded placeholder and does not operate the physical lock.
- A future adapter needs a documented/authorised interface, device-state confirmation, authenticated owner/Special Partner checks, and an independently tested emergency-release path. Do not use indefinite lock behaviour without a reliable physical way to remove the device if the electronics, app, phone, battery, or server fail.
- There is no automatic unlock timer implemented, but this resource also cannot guarantee a physical locked state or enforce the lock policy without that verified adapter.
