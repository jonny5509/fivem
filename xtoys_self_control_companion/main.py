import json
import queue
import threading
import tkinter as tk
from tkinter import messagebox
from websocket import create_connection, WebSocketConnectionClosedException
from pynput import keyboard

APP_TITLE = "xToys Self Control — Local Companion"

class Companion:
    def __init__(self, root):
        self.root = root
        self.root.title(APP_TITLE)
        self.root.geometry("430x360")
        self.root.resizable(False, False)
        self.events = queue.Queue()
        self.ws = None
        self.ws_lock = threading.Lock()
        self.connected = False
        self.continuous = False
        self.closing = False

        tk.Label(root, text="xToys Self Control", font=("Segoe UI", 18, "bold")).pack(pady=(18, 4))
        tk.Label(root, text="Local PC companion • no FiveM resource required", fg="#666").pack()

        tk.Label(root, text="Private XToys webhook ID").pack(anchor="w", padx=24, pady=(20, 4))
        self.webhook = tk.Entry(root, show="•", width=48)
        self.webhook.pack(padx=24)
        row = tk.Frame(root)
        row.pack(pady=10)
        self.connect_button = tk.Button(row, text="Connect", width=14, command=self.connect)
        self.connect_button.pack(side="left", padx=5)
        tk.Button(row, text="Disconnect", width=14, command=self.disconnect).pack(side="left", padx=5)

        self.status = tk.Label(root, text="Not connected", fg="#a33")
        self.status.pack(pady=4)

        tk.Label(root, text="Local hotkeys", font=("Segoe UI", 11, "bold")).pack(pady=(14, 4))
        tk.Label(root, text="F6  •  Short pulse\nF7  •  Toggle continuous pulse\nF8  •  Emergency stop",
                 justify="left", font=("Segoe UI", 10)).pack()
        self.continuous_status = tk.Label(root, text="Continuous mode: OFF")
        self.continuous_status.pack(pady=8)
        tk.Button(root, text="EMERGENCY STOP", bg="#9d2424", fg="white",
                  command=self.emergency_stop, width=22).pack(pady=8)
        tk.Label(root, text="Hotkeys are manual. This app does not inspect or inject into FiveM.",
                 fg="#666", wraplength=380).pack(pady=(8, 0))

        self.listener = keyboard.Listener(on_press=self.on_key)
        self.listener.start()
        self.root.protocol("WM_DELETE_WINDOW", self.close)
        self.root.after(100, self.process_events)
        self.root.after(1000, self.refresh_continuous)

    def on_key(self, key):
        if key == keyboard.Key.f6:
            self.events.put("pulse")
        elif key == keyboard.Key.f7:
            self.events.put("toggle")
        elif key == keyboard.Key.f8:
            self.events.put("stop")

    def connect(self):
        webhook_id = self.webhook.get().strip()
        if not webhook_id:
            messagebox.showwarning(APP_TITLE, "Enter your private XToys webhook ID.")
            return
        self.connect_button.config(state="disabled")
        self.status.config(text="Connecting…", fg="#986b00")
        threading.Thread(target=self.connect_worker, args=(webhook_id,), daemon=True).start()

    def connect_worker(self, webhook_id):
        try:
            ws = create_connection("wss://webhook.xtoys.app/" + webhook_id, timeout=10)
            with self.ws_lock:
                old, self.ws = self.ws, ws
                self.connected = True
            if old:
                old.close()
            self.events.put("connected")
        except Exception as exc:
            self.events.put(("connect_error", str(exc)))

    def send(self, payload):
        try:
            with self.ws_lock:
                if not self.connected or self.ws is None:
                    return False
                self.ws.send(json.dumps(payload))
            return True
        except (Exception, WebSocketConnectionClosedException):
            self.events.put("connection_lost")
            return False

    def pulse(self):
        if not self.send({"action": "setintensity", "intensity": 35, "seconds": 2}):
            self.status.config(text="Not connected — pulse not sent", fg="#a33")

    def emergency_stop(self):
        self.continuous = False
        self.continuous_status.config(text="Continuous mode: OFF")
        if self.send({"action": "stop"}):
            self.status.config(text="Emergency stop sent", fg="#176b35")
        else:
            self.status.config(text="Not connected — stop could not be sent", fg="#a33")

    def disconnect(self):
        self.emergency_stop()
        with self.ws_lock:
            ws, self.ws = self.ws, None
            self.connected = False
        if ws:
            try:
                ws.close()
            except Exception:
                pass
        self.status.config(text="Disconnected", fg="#a33")
        self.connect_button.config(state="normal")

    def process_events(self):
        while True:
            try:
                event = self.events.get_nowait()
            except queue.Empty:
                break
            if event == "pulse":
                self.pulse()
            elif event == "toggle":
                self.continuous = not self.continuous
                self.continuous_status.config(
                    text="Continuous mode: " + ("ON" if self.continuous else "OFF"))
                if not self.continuous:
                    self.send({"action": "stop"})
            elif event == "stop":
                self.emergency_stop()
            elif event == "connected":
                self.status.config(text="Connected to XToys", fg="#176b35")
                self.connect_button.config(state="normal")
            elif event == "connection_lost":
                self.connected = False
                self.status.config(text="Connection lost", fg="#a33")
                self.connect_button.config(state="normal")
            elif isinstance(event, tuple) and event[0] == "connect_error":
                self.status.config(text="Connection failed", fg="#a33")
                self.connect_button.config(state="normal")
                messagebox.showerror(APP_TITLE, event[1])
        self.root.after(100, self.process_events)

    def refresh_continuous(self):
        if self.continuous:
            if not self.send({"action": "setintensity", "intensity": 35, "seconds": 2}):
                self.continuous = False
                self.continuous_status.config(text="Continuous mode: OFF")
        if not self.closing:
            self.root.after(1000, self.refresh_continuous)

    def close(self):
        self.closing = True
        self.emergency_stop()
        self.disconnect()
        self.listener.stop()
        self.root.destroy()

if __name__ == "__main__":
    window = tk.Tk()
    Companion(window)
    window.mainloop()
