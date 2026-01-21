#!/usr/bin/env python3
"""Test coordinate-based taps on navigation bar"""
import subprocess
import json
import time
import base64
import os

VM_SERVICE_URL = "ws://127.0.0.1:52132/z7Ey8M6DvVo=/ws"
SCREENSHOT_DIR = os.path.dirname(os.path.abspath(__file__)) + "/screenshots"

# Navigation bar coordinates (from element bounds)
# y=715 to y=795 (height 80), divided into 4 sections of ~104px each
NAV_COORDS = {
    "Home": (52, 755),      # Center of first nav item
    "Map": (156, 755),      # Center of second nav item
    "Discover": (260, 755), # Center of third nav item
    "Profile": (364, 755),  # Center of fourth nav item
}

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

    def read_response(self, timeout=15):
        start = time.time()
        data = b""
        while time.time() - start < timeout:
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

    def take_screenshot(self, name):
        print(f"  Screenshot: {name}...")
        resp = self.send("tools/call", {"name": "take_screenshots", "arguments": {}})
        time.sleep(1)
        if resp:
            content = resp.get("result", {}).get("content", [])
            for item in content:
                if item.get("type") == "image":
                    img_data = item.get("data", "")
                    if img_data:
                        try:
                            img_bytes = base64.b64decode(img_data)
                            filepath = f"{SCREENSHOT_DIR}/coord_{name}.png"
                            with open(filepath, "wb") as f:
                                f.write(img_bytes)
                            print(f"    Saved: {filepath} ({len(img_bytes)//1024}KB)")
                            return filepath
                        except Exception as e:
                            print(f"    Error: {e}")
        return None

    def close(self):
        self.proc.terminate()
        self.proc.wait()


def main():
    print("=" * 60)
    print("Coordinate-based Navigation Test")
    print("=" * 60)

    client = MarionetteClient()

    try:
        # Initialize
        print("\n1. Initialize...")
        client.send("initialize", {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": {"name": "coord-test", "version": "1.0"}
        })
        client.send("notifications/initialized", is_notification=True)
        time.sleep(0.5)

        # Connect
        print("\n2. Connect...")
        resp = client.send("tools/call", {"name": "connect", "arguments": {"uri": VM_SERVICE_URL}})
        if resp:
            content = resp.get("result", {}).get("content", [])
            for c in content:
                if c.get("type") == "text":
                    print(f"   {c.get('text')}")
        time.sleep(2)

        # Take initial screenshot
        print("\n3. Initial state...")
        client.take_screenshot("01_initial")
        time.sleep(1)

        # Test taps by text (what we were doing)
        print("\n4. Test text-based tap on 'Map'...")
        resp = client.send("tools/call", {
            "name": "tap",
            "arguments": {"textOrKey": "Map"}
        })
        if resp:
            content = resp.get("result", {}).get("content", [])
            for c in content:
                text = str(c.get('text', c)).encode('ascii', 'replace').decode('ascii')
                print(f"   Response: {text}")
        time.sleep(2)
        client.take_screenshot("02_after_text_tap")

        # Get elements again to see if screen changed
        print("\n5. Check current elements...")
        resp = client.send("tools/call", {"name": "get_interactive_elements", "arguments": {}})
        if resp:
            content = resp.get("result", {}).get("content", [])
            for c in content:
                if c.get("type") == "text":
                    text = c.get("text", "")
                    # Look for screen-specific elements
                    if "Map" in text[:100] or "Discover" in text[:100] or "Profile" in text[:100]:
                        safe = text[:200].encode('ascii', 'replace').decode('ascii')
                        print(f"   First 200 chars: {safe}")

        print("\n" + "=" * 60)
        print("Test complete!")
        print("=" * 60)

    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        client.close()


if __name__ == "__main__":
    main()
