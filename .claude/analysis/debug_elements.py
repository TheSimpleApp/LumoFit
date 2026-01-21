#!/usr/bin/env python3
"""Debug Marionette - see what elements it can find"""
import subprocess
import json
import time
import os

VM_SERVICE_URL = "ws://127.0.0.1:52132/z7Ey8M6DvVo=/ws"

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

    def close(self):
        self.proc.terminate()
        self.proc.wait()


def main():
    print("Starting debug session...")
    client = MarionetteClient()

    try:
        # Initialize
        print("\n1. Initialize...")
        resp = client.send("initialize", {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": {"name": "debug", "version": "1.0"}
        })
        print(f"   OK: {resp.get('result', {}).get('serverInfo', {})}")

        client.send("notifications/initialized", is_notification=True)
        time.sleep(0.5)

        # Connect
        print("\n2. Connect to app...")
        resp = client.send("tools/call", {
            "name": "connect",
            "arguments": {"uri": VM_SERVICE_URL}
        })
        print(f"   {resp}")
        time.sleep(2)  # Wait for connection to stabilize

        # Get interactive elements
        print("\n3. Get interactive elements...")
        resp = client.send("tools/call", {
            "name": "get_interactive_elements",
            "arguments": {}
        })

        if resp:
            content = resp.get("result", {}).get("content", [])
            for c in content:
                if c.get("type") == "text":
                    elements_text = c.get("text", "")
                    print("\n   ELEMENTS FOUND:")
                    print("   " + "-" * 60)
                    # Print nicely - encode to ASCII replacing special chars
                    lines = elements_text.split('\n')
                    for line in lines:  # All lines
                        safe_line = line.encode('ascii', 'replace').decode('ascii')
                        print(f"   {safe_line}")

        # Try tapping with exact navigation text
        print("\n4. Testing tap on navigation items...")

        # Get current view first
        nav_items = ["Home", "Map", "Discover", "Profile"]
        for item in nav_items:
            print(f"\n   Trying to tap '{item}'...")
            resp = client.send("tools/call", {
                "name": "tap",
                "arguments": {"textOrKey": item}
            })
            if resp:
                content = resp.get("result", {}).get("content", [])
                for c in content:
                    text = c.get('text', str(c))
                    safe_text = text.encode('ascii', 'replace').decode('ascii')
                    print(f"   -> {safe_text}")
            time.sleep(0.5)

    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        client.close()


if __name__ == "__main__":
    main()
