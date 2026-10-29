# xToys Multiplayer (Standalone FiveM)

A standalone, consent-first pairing resource. No ESX, QBCore, database, or framework dependency.

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

This starter uses private webhooks. XToys shared webhooks require an Authorization Bearer header; the NUI browser WebSocket API cannot attach custom handshake headers. Do not paste shared tokens into the server resource. Use a private webhook unless you have a trusted local bridge that handles shared-webhook authentication.

## Consent and permissions
- Either player can invite the other by server ID.
- The recipient must accept before pairing.
- Either paired player can request control.
- The toy owner must approve each control request.
- Only the approved controller can send commands; the server clamps intensity to 0-100 and duration to 1-10 seconds.
- Either player can emergency-stop or revoke pairing.
- Disconnecting either player clears the pairing and active control.
- Only the toy owner needs an XToys connection; the other player only needs to be paired and approved.

## ERP integration
An ERP adapter is not enabled because the exact ERP resource/API has not yet been identified. Once you know its resource name and documented client/server events or exports, an allow-listed adapter can be added without guessing event names.

## Testing
Test on a private server with two consenting test players. First verify invitations, acceptance, request approval/decline, revoke, emergency stop, and disconnect cleanup. Then test a low-intensity, short-duration XToys action. Ensure the XToys Script has a stop action wired to the `stop` webhook trigger.

## Notes
This is a starter resource and has not been runtime-tested against your server's artifact build or your specific XToys Script. The server authorizes pairing and commands; it cannot independently confirm physical toy connectivity. Credentials are held in NUI memory only and must be re-entered after a resource/UI restart.
