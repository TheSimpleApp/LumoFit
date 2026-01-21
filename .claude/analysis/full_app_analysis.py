#!/usr/bin/env python3
"""Comprehensive FitTravel app analysis via Marionette MCP"""
import subprocess
import json
import time
import base64
import os
from datetime import datetime

VM_SERVICE_URL = "ws://127.0.0.1:52132/z7Ey8M6DvVo=/ws"
SCREENSHOT_DIR = os.path.dirname(os.path.abspath(__file__)) + "/screenshots"
REPORT_FILE = os.path.dirname(os.path.abspath(__file__)) + "/full-analysis-report.md"

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
        self.screenshots = []
        self.elements_log = []

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

    def initialize(self):
        print("Initializing Marionette MCP...")
        self.send("initialize", {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": {"name": "full-analysis", "version": "1.0"}
        })
        self.send("notifications/initialized", is_notification=True)
        time.sleep(0.5)

    def connect(self):
        print(f"Connecting to app at {VM_SERVICE_URL}...")
        resp = self.send("tools/call", {"name": "connect", "arguments": {"uri": VM_SERVICE_URL}})
        if resp:
            content = resp.get("result", {}).get("content", [])
            for c in content:
                if c.get("type") == "text":
                    print(f"  {c.get('text')}")
        time.sleep(2)

    def take_screenshot(self, name, description=""):
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
                            timestamp = datetime.now().strftime("%H%M%S")
                            filepath = f"{SCREENSHOT_DIR}/analysis_{timestamp}_{name}.png"
                            with open(filepath, "wb") as f:
                                f.write(img_bytes)
                            print(f"    Saved: {filepath} ({len(img_bytes)//1024}KB)")
                            self.screenshots.append({
                                "name": name,
                                "description": description,
                                "filepath": filepath,
                                "size_kb": len(img_bytes)//1024
                            })
                            return filepath
                        except Exception as e:
                            print(f"    Error: {e}")
        return None

    def tap(self, text_or_key, description=""):
        print(f"  Tap: {text_or_key}...")
        resp = self.send("tools/call", {
            "name": "tap",
            "arguments": {"textOrKey": text_or_key}
        })
        time.sleep(1)
        if resp:
            content = resp.get("result", {}).get("content", [])
            for c in content:
                if c.get("type") == "text":
                    result = c.get('text', '')
                    print(f"    {result}")
                    return "success" in result.lower()
        return False

    def get_elements(self, screen_name=""):
        print(f"  Getting elements for: {screen_name}...")
        resp = self.send("tools/call", {"name": "get_interactive_elements", "arguments": {}})
        if resp:
            content = resp.get("result", {}).get("content", [])
            for c in content:
                if c.get("type") == "text":
                    elements_text = c.get("text", "")
                    self.elements_log.append({
                        "screen": screen_name,
                        "elements": elements_text
                    })
                    # Count elements
                    lines = elements_text.split('\n')
                    element_count = len([l for l in lines if l.strip().startswith("Type:")])
                    print(f"    Found {element_count} interactive elements")
                    return elements_text
        return ""

    def close(self):
        self.proc.terminate()
        self.proc.wait()

    def generate_report(self):
        print("\nGenerating analysis report...")
        with open(REPORT_FILE, "w", encoding="utf-8") as f:
            f.write("# FitTravel App - Full Analysis Report (Marionette)\n\n")
            f.write(f"**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"**Platform:** Windows Desktop\n")
            f.write(f"**VM Service:** {VM_SERVICE_URL}\n\n")
            f.write("---\n\n")

            f.write("## Screenshots Captured\n\n")
            for i, ss in enumerate(self.screenshots, 1):
                f.write(f"{i}. **{ss['name']}** ({ss['size_kb']}KB)\n")
                f.write(f"   - Description: {ss['description']}\n")
                f.write(f"   - File: `{os.path.basename(ss['filepath'])}`\n\n")

            f.write("\n---\n\n")

            f.write("## Interactive Elements by Screen\n\n")
            for log in self.elements_log:
                f.write(f"### {log['screen']}\n\n")
                f.write("```\n")
                # Write first 50 lines of elements
                lines = log['elements'].split('\n')
                for line in lines[:50]:
                    safe_line = line.encode('ascii', 'replace').decode('ascii')
                    f.write(safe_line + "\n")
                if len(lines) > 50:
                    f.write(f"\n... and {len(lines) - 50} more lines\n")
                f.write("```\n\n")

        print(f"Report saved to: {REPORT_FILE}")


def main():
    print("=" * 70)
    print("FitTravel App - Full Analysis with Marionette MCP")
    print("=" * 70)

    client = MarionetteClient()

    try:
        # Initialize and connect
        client.initialize()
        client.connect()
        time.sleep(1)

        # Home Screen Analysis
        print("\n[1/5] Analyzing Home Screen...")
        client.take_screenshot("01_home", "Home screen with streak, quick actions, today's activity")
        client.get_elements("Home Screen")
        time.sleep(1)

        # Try Quick Actions
        print("\n[2/5] Testing 'Find Gym' Quick Action...")
        if client.tap("Find Gym", "Navigate to gym discovery"):
            time.sleep(2)
            client.take_screenshot("02_find_gym", "Gym discovery screen via Find Gym quick action")
            client.get_elements("Find Gym Screen")

        # Go back (might not work, but try)
        print("\n[3/5] Attempting to go back to Home...")
        time.sleep(1)
        client.tap("Home")  # Try tapping Home nav item
        time.sleep(2)

        # Try Find Food
        print("\n[4/5] Testing 'Find Food' Quick Action...")
        if client.tap("Find Food", "Navigate to food discovery"):
            time.sleep(2)
            client.take_screenshot("03_find_food", "Food discovery screen via Find Food quick action")
            client.get_elements("Find Food Screen")

        # Try Fitness Guide
        print("\n[5/5] Testing 'Fitness Guide' Card...")
        if client.tap("Fitness Guide", "Open AI-powered fitness guide"):
            time.sleep(2)
            client.take_screenshot("04_fitness_guide", "AI Fitness Guide screen")
            client.get_elements("Fitness Guide Screen")

        # Final screenshot
        time.sleep(1)
        client.take_screenshot("05_final_state", "Final app state after testing")

        # Generate report
        client.generate_report()

        print("\n" + "=" * 70)
        print("Analysis Complete!")
        print("=" * 70)
        print(f"Screenshots: {len(client.screenshots)}")
        print(f"Report: {REPORT_FILE}")
        print("=" * 70)

    except Exception as e:
        print(f"\nError during analysis: {e}")
        import traceback
        traceback.print_exc()
    finally:
        client.close()


if __name__ == "__main__":
    main()
