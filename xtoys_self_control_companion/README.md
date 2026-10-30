# xToys Self Control — Local Windows Companion

This is the local-PC version of xToys Self Control. It runs as a normal Windows desktop app, connects directly to your private XToys webhook, and does not require a FiveM server resource, server.cfg change, server-owner permission, or a FiveM script.

## Important limitation

FiveM does not provide a supported graphics-pack-style mechanism for a local desktop app to receive internal gameplay events such as damage, shooting, falls, or explosions without a client resource being loaded by the server. This companion therefore uses **manual global hotkeys**. It does not read FiveM memory, inject code, hook the game, evade anti-cheat, or automatically detect gameplay.

The existing `xtoys_self_control/` folder is a separate FiveM client resource. It can automatically detect the configured game events, but a FiveM server must distribute/start it. Use this companion when you need a local-PC app that does not require server involvement.

## Requirements

- Windows 10/11
- Python 3.10 or newer
- A private XToys webhook ID and an XToys Script configured to handle `setintensity` and `stop`

## Run

Open PowerShell in this folder:

```powershell
py -m pip install -r requirements.txt
py main.py
```

Enter your private webhook ID and select **Connect**. The app keeps the ID in the entry field only; it does not save it to disk or send it to a FiveM server.

## Hotkeys

| Key | Action |
|---|---|
| F6 | Send a short pulse (intensity 35, 2 seconds) |
| F7 | Toggle continuous pulses (intensity 35, refreshed every second) |
| F8 | Emergency stop and turn continuous mode off |

The Emergency Stop button does the same as F8. Press F7 again to turn continuous mode off; the app sends a stop command.

## Build a Windows executable (optional)

```powershell
py -m pip install pyinstaller
py -m PyInstaller --onefile --windowed --name xToysSelfControl main.py
```

The executable is created in `dist\xToysSelfControl.exe`.

## Safety and limitations

- Use a private webhook ID. Anyone who obtains it may be able to send commands to your XToys webhook.
- The app sends only the documented XToys WebSocket messages; actual output depends on your XToys Script setup.
- Stop commands cannot be guaranteed if Windows, the app, the network, XToys, or the toy disconnects or crashes.
- Global hotkeys may be intercepted by another application or blocked by Windows permissions.
- This companion has not been runtime-tested on your PC or with your physical device.
