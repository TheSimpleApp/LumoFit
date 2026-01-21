#!/usr/bin/env python3
"""Navigate through FitTravel app and take screenshots via Marionette MCP"""
import subprocess
import json
import time
import base64
import os
from datetime import datetime

VM_SERVICE_URL = "ws://127.0.0.1:52132/z7Ey8M6DvVo=/ws"
SCREENSHOT_DIR = os.path.dirname(os.path.abspath(__file__)) + "/screenshots"

class MarionetteClient:
    def __init__(self):
        self.msg_id = 0
        self.proc = subprocess.Popen(
            ["cmd", "/c", "marionette_mcp"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            bufsize=0
        )
        os.makedirs(SCREENSHOT_DIR, exist_ok=True)

    def next_id(self):
        self.msg_id += 1
        return self.msg_id

    def send(self, method, params=None, is_notification=False):
        msg = {"jsonrpc": "2.0", "method": method}
        if params:
            msg["params"] = params
        if not is_notification:
            msg["id"] = self.next_id()

        json_bytes = (json.dumps(msg) + "\n").encode('utf-8')
        self.proc.stdin.write(json_bytes)
        self.proc.stdin.flush()

        if not is_notification:
            return self.read_response()
        return None

    def read_response(self, timeout=10):
        """Read response with timeout"""
        import select
        start = time.time()
        data = b""
        while time.time() - start < timeout:
            # Read bytes until we get a complete JSON line
            byte = self.proc.stdout.read(1)
            if byte:
                data += byte
                if byte == b'\n':
                    try:
                        return json.loads(data.decode('utf-8', errors='replace'))
                    except:
                        data = b""
            else:
                time.sleep(0.01)
        return None

    def initialize(self):
        print("Initializing MCP server...")
        resp = self.send("initialize", {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": {"name": "screenshot-tool", "version": "1.0"}
        })
        if resp and "result" in resp:
            print(f"  Server: {resp['result'].get('serverInfo', {})}")
        self.send("notifications/initialized", is_notification=True)
        time.sleep(0.3)
        return resp

    def connect(self, uri):
        print(f"Connecting to app at {uri}...")
        resp = self.send("tools/call", {
            "name": "connect",
            "arguments": {"uri": uri}
        })
        if resp:
            if "error" in resp:
                print(f"  Error: {resp['error']}")
            else:
                content = resp.get("result", {}).get("content", [])
                for c in content:
                    if c.get("type") == "text":
                        print(f"  {c.get('text')}")
        return resp

    def take_screenshot(self, name):
        print(f"Taking screenshot: {name}...")
        resp = self.send("tools/call", {
            "name": "take_screenshots",
            "arguments": {}
        })
        time.sleep(1)  # Give time for screenshot

        if resp:
            content = resp.get("result", {}).get("content", [])
            for item in content:
                if item.get("type") == "image":
                    img_data = item.get("data", "")
                    if img_data:
                        try:
                            img_bytes = base64.b64decode(img_data)
                            timestamp = datetime.now().strftime("%H%M%S")
                            filepath = f"{SCREENSHOT_DIR}/{timestamp}_{name}.png"
                            with open(filepath, "wb") as f:
                                f.write(img_bytes)
                            print(f"  Saved: {filepath} ({len(img_bytes)//1024}KB)")
                            return filepath
                        except Exception as e:
                            print(f"  Error saving: {e}")
        return None

    def tap(self, text_or_key):
        print(f"Tapping: {text_or_key}...")
        resp = self.send("tools/call", {
            "name": "tap",
            "arguments": {"textOrKey": text_or_key}
        })
        time.sleep(0.5)  # Wait for UI to update
        if resp:
            content = resp.get("result", {}).get("content", [])
            for c in content:
                if c.get("type") == "text":
                    print(f"  {c.get('text')}")
        return resp

    def get_elements(self):
        print("Getting interactive elements...")
        resp = self.send("tools/call", {
            "name": "get_interactive_elements",
            "arguments": {}
        })
        if resp:
            content = resp.get("result", {}).get("content", [])
            for c in content:
                if c.get("type") == "text":
                    text = c.get("text", "")
                    # Print first 2000 chars
                    print(f"  Elements: {text[:2000]}...")
        return resp

    def close(self):
        self.proc.terminate()
        self.proc.wait()


def main():
    print("=" * 60)
    print("FitTravel App Navigation Test")
    print("=" * 60)

    client = MarionetteClient()

    try:
        # Initialize and connect
        client.initialize()
        client.connect(VM_SERVICE_URL)
        time.sleep(1)

        # Screenshot 1: Current screen (should be Home or Login)
        client.take_screenshot("01_initial_screen")
        time.sleep(1)

        # Try to navigate to different tabs
        tabs = ["Map", "Discover", "Profile"]

        for i, tab in enumerate(tabs):
            print(f"\n--- Navigating to {tab} tab ---")
            client.tap(tab)
            time.sleep(3)  # Wait longer for screen to load
            client.take_screenshot(f"0{i+2}_{tab.lower()}_tab")
            time.sleep(1)

        # Go back to Home
        print("\n--- Navigating back to Home ---")
        client.tap("Home")
        time.sleep(1)
        client.take_screenshot("05_home_final")

        print("\n" + "=" * 60)
        print("Test complete! Screenshots saved to:")
        print(SCREENSHOT_DIR)
        print("=" * 60)

    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        client.close()


if __name__ == "__main__":
    main()
