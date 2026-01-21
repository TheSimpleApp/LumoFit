#!/usr/bin/env python3
"""Test Marionette MCP server with FitTravel app"""
import subprocess
import json
import sys
import time
import base64
import os

VM_SERVICE_URL = "ws://127.0.0.1:52132/z7Ey8M6DvVo=/ws"
SCREENSHOT_DIR = os.path.dirname(os.path.abspath(__file__)) + "/screenshots"

def send_mcp_message(proc, message):
    """Send a JSON-RPC message to the MCP server"""
    json_str = json.dumps(message)
    proc.stdin.write(json_str + "\n")
    proc.stdin.flush()

def read_mcp_response(proc, timeout=10):
    """Read a JSON-RPC response from the MCP server"""
    import select
    # Simple line read
    line = proc.stdout.readline()
    if line:
        try:
            return json.loads(line.strip())
        except json.JSONDecodeError:
            return {"raw": line.strip()}
    return None

def main():
    print(f"Starting Marionette MCP test...")
    print(f"VM Service URL: {VM_SERVICE_URL}")
    print(f"Screenshot dir: {SCREENSHOT_DIR}")

    # Ensure screenshot directory exists
    os.makedirs(SCREENSHOT_DIR, exist_ok=True)

    # Start marionette_mcp process
    proc = subprocess.Popen(
        ["cmd", "/c", "marionette_mcp"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        bufsize=1
    )

    msg_id = 0

    def next_id():
        nonlocal msg_id
        msg_id += 1
        return msg_id

    try:
        # 1. Initialize
        print("\n1. Initializing MCP server...")
        send_mcp_message(proc, {
            "jsonrpc": "2.0",
            "id": next_id(),
            "method": "initialize",
            "params": {
                "protocolVersion": "2024-11-05",
                "capabilities": {},
                "clientInfo": {"name": "test", "version": "1.0"}
            }
        })
        time.sleep(0.5)
        resp = read_mcp_response(proc)
        if resp:
            print(f"   Server: {resp.get('result', {}).get('serverInfo', {})}")

        # 2. Send initialized notification
        print("\n2. Sending initialized notification...")
        send_mcp_message(proc, {
            "jsonrpc": "2.0",
            "method": "notifications/initialized"
        })
        time.sleep(0.3)

        # 3. List tools
        print("\n3. Listing available tools...")
        send_mcp_message(proc, {
            "jsonrpc": "2.0",
            "id": next_id(),
            "method": "tools/list"
        })
        time.sleep(0.5)
        resp = read_mcp_response(proc)
        if resp and "result" in resp:
            tools = resp["result"].get("tools", [])
            print(f"   Available tools ({len(tools)}):")
            for tool in tools:
                print(f"   - {tool.get('name')}: {tool.get('description', '')[:60]}...")

        # 4. Connect to app
        print(f"\n4. Connecting to Flutter app at {VM_SERVICE_URL}...")
        send_mcp_message(proc, {
            "jsonrpc": "2.0",
            "id": next_id(),
            "method": "tools/call",
            "params": {
                "name": "connect",
                "arguments": {
                    "uri": VM_SERVICE_URL
                }
            }
        })
        time.sleep(2)
        resp = read_mcp_response(proc)
        if resp:
            print(f"   Response: {json.dumps(resp, indent=2)[:500]}")

        # 5. Take screenshot
        print("\n5. Taking screenshot of current screen...")
        send_mcp_message(proc, {
            "jsonrpc": "2.0",
            "id": next_id(),
            "method": "tools/call",
            "params": {
                "name": "take_screenshots",
                "arguments": {}
            }
        })
        time.sleep(3)
        resp = read_mcp_response(proc)
        if resp:
            print(f"   Screenshot response received")
            # Try to save screenshot if it's base64 encoded
            try:
                content = resp.get("result", {}).get("content", [])
                for item in content:
                    if item.get("type") == "image":
                        img_data = item.get("data", "")
                        if img_data:
                            img_bytes = base64.b64decode(img_data)
                            screenshot_path = f"{SCREENSHOT_DIR}/screenshot_1.png"
                            with open(screenshot_path, "wb") as f:
                                f.write(img_bytes)
                            print(f"   Saved to: {screenshot_path}")
            except Exception as e:
                print(f"   Error saving screenshot: {e}")
                print(f"   Raw response: {json.dumps(resp, indent=2)[:1000]}")

        # 6. Get interactive elements
        print("\n6. Getting interactive elements...")
        send_mcp_message(proc, {
            "jsonrpc": "2.0",
            "id": next_id(),
            "method": "tools/call",
            "params": {
                "name": "get_interactive_elements",
                "arguments": {}
            }
        })
        time.sleep(2)
        resp = read_mcp_response(proc)
        if resp:
            print(f"   Elements response: {json.dumps(resp, indent=2)[:800]}...")

        print("\n[OK] Test complete!")

    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        proc.terminate()
        proc.wait()

if __name__ == "__main__":
    main()
