# Basic Hotkeys

- AHKv2
- VirtualDesktopAccessor.dll was taken from https://github.com/Ciantic/VirtualDesktopAccessor

### Run an AutoHotkey script as Administrator on startup (Task Scheduler)

1. Open **Task Scheduler**

* Press `Win + R`, type `taskschd.msc`, press Enter.

2. Create a new task

* In the right panel, click **Create Task…** (not “Create Basic Task”).

3. General tab

* **Name:** something like `AHK Hotkeys`
* Select **Run only when user is logged on**
* ✅ Check **Run with highest privileges**
* **Configure for:** Windows 10 / Windows 11

4. Triggers tab

* Click **New…**
* **Begin the task:** `At log on`
* **Settings:** choose your user (or “Any user” if you want)
* (Optional) ✅ **Delay task for:** 5–10 seconds (helps avoid race conditions on login)
* Click **OK**

5. Actions tab

* Click **New…**
* **Action:** `Start a program`
* **Program/script:**

  * For AutoHotkey v2 (common default):

    * `C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe`
  * (If you installed elsewhere, browse to the correct EXE)
* **Add arguments (optional):**

  * `"C:\Path\To\YourScript.ahk"`
* **Start in (optional but recommended):**

  * `C:\Path\To\` (the folder containing your script and `VirtualDesktopAccessor.dll`)
* Click **OK**

6. Conditions / Settings tabs (optional)

* You can uncheck power-related limits like “Start the task only if the computer is on AC power” if you’re on a laptop.

7. Save

* Click **OK**
* If Windows asks for credentials, enter them.

### Quick test

* Right-click the task → **Run**
* Then check in Task Scheduler’s **History** (or in Task Manager) that it starts properly.

If you want, tell me where your AHK v2 exe and script are located, and I’ll write the exact values for **Program/script**, **Arguments**, and **Start in** for your paths.
