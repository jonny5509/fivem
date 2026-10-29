# xToys Multiplayer (Standalone FiveM)

A standalone, consent-first xToys multiplayer resource. No ESX, QBCore, framework, or external database dependency.

## Install
1. Put this folder in your server's resources directory.
2. Add `ensure xtoys_multiplayer` to server.cfg.
3. Restart the resource/server.
4. Use `/xtoys` in game. Use `/xtoysstop` for an emergency stop.

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

## ERP integration
No ERP integration is included. This resource is focused on xToys only.

## Testing
Test on a private server with two consenting test players. Verify nearby detection, trusted invitation and acceptance, persistence after reconnect/restart, trusted control, removal, ordinary pairing, control approval, emergency stop, and disconnect cleanup. Then test a low-intensity, short-duration XToys action. Ensure the XToys Script has a stop action wired to the `stop` webhook trigger.

## Notes
This resource has not been runtime-tested against your server's artifact build or your specific XToys Script. The server authorizes pairing and commands; it cannot independently confirm physical toy connectivity. Webhook credentials are held in NUI memory only and must be re-entered after a resource/UI restart.
