# ThinkPad T580 test plan

This is the procedure for the first real-hardware validation of InnyGrOS. Until it has been carried out and the results recorded below, **no hardware compatibility is claimed**.

The T580 has several factory configurations (Intel UHD 620 only, or UHD 620 + NVIDIA GeForce MX150; different Wi-Fi cards, displays, and an optional second battery). Record what the test unit actually has in step 1 instead of assuming it.

## 0. Before touching the laptop

- [ ] Back up anything on the laptop that matters.
- [ ] If Windows is installed and BitLocker / device encryption is on, save the recovery key somewhere other than the laptop.
- [ ] Update the BIOS/UEFI from Lenovo while Windows is still there, if possible (Linux can also use `fwupdmgr`).
- [ ] Write the Kubuntu ISO to a USB stick (official image from https://kubuntu.org/download/).

## 1. Live USB check (no install)

Boot the Kubuntu live session, open a terminal, get the repository (`git clone https://github.com/Innygr/InnyGrOS` or copy it on a second USB stick), then:

```bash
bash scripts/hardware-check.sh --text --save
```

Copy the saved report from `~/.local/share/innygros/reports/` to the second USB stick; the live session is not kept. Then go through the "Still needs a person to test" list printed at the end of the report.

| Item | Detected (report) | Works (manual) | Notes |
| --- | --- | --- | --- |
| Model / BIOS version | | n/a | |
| GPU(s) | | | |
| Wi-Fi (driver) | | | |
| Bluetooth | | | |
| Audio: speakers / jack / mic | | | |
| Brightness keys | | | |
| Touchpad / TrackPoint | | | |
| Webcam | | | |
| Batteries (count, health) | | n/a | |
| Suspend mode (s2idle/deep) | | lid close/open ×3 | |
| External display | | | |

Only continue to installing if Wi-Fi, display, keyboard and touchpad work in the live session.

## 2. Install baseline Kubuntu

Install Kubuntu normally (no InnyGrOS yet). Apply updates through Discover, reboot.

## 3. Baseline measurements (before InnyGrOS)

Do each measurement the same way every time so the before/after numbers are comparable:

1. Fully charge, then unplug (for battery numbers) or stay on AC (for boot/CPU numbers). Write down which.
2. Set screen brightness to the same level (e.g. 50 %) and leave Wi-Fi on.
3. Reboot, log in, wait **2 minutes** without touching anything.
4. Run:

   ```bash
   bash scripts/performance-benchmark.sh --text --save
   bash scripts/hardware-check.sh --text --save
   ```

5. Repeat steps 3–4 **three times** and use the median.

| Measurement | Run 1 | Run 2 | Run 3 | Median |
| --- | --- | --- | --- | --- |
| Boot time (systemd-analyze total) | | | | |
| Idle RAM used | | | | |
| 1-min load average after 2 min idle | | | | |
| Battery draw (W) on idle desktop | | | | |
| CPU timing median (ms) | | | | |

Optional: battery run-down time with a fixed workload (for example a looping local video at 50 % brightness), recorded start and end percentage over 60 minutes.

## 4. Apply InnyGrOS

```bash
./install.sh --check
./install.sh
```

Record each prompt's answer and the final summary. Then, from the Welcome Center, test **every** menu action and write down the result:

| Welcome Center action | Result | Notes |
| --- | --- | --- |
| Open System Settings / Discover / File Manager / Terminal | | |
| Apply InnyGrOS desktop profile | | |
| Restore previous desktop settings | | |
| Apply InnyGrOS colors | | |
| Install / apply wallpaper | | |
| Install terminal theme | | |
| Game readiness | | |
| System diagnostics | | |
| Performance snapshot | | |
| Laptop hardware check | | |
| Open project page / About / Exit | | |

## 5. After measurements

Repeat section 3 exactly (same power state, brightness, waiting time, three runs). Compare with `bash scripts/compare-reports.sh BEFORE.txt AFTER.txt` (key numbers side by side), and with `diff` or Kompare on the saved reports for everything else. Only report a difference as an improvement if it is larger than the spread between the three runs.

## 6. Minecraft and graphics

- [ ] `bash scripts/game-readiness.sh` — Java, Vulkan and OpenGL renderer recorded
- [ ] GDLauncher installed (Flatpak or AppImage); Minecraft Java starts and reaches a world
- [ ] Note FPS at default settings and render distance, on AC and on battery
- [ ] If the unit has an MX150: note which GPU Minecraft actually uses

## 7. Recovery check

- [ ] `./scripts/restore-defaults.sh --dry-run` lists the expected files
- [ ] `./scripts/restore-defaults.sh` returns the desktop to its previous look after logging out and in

## Results log

Record the date, Kubuntu version, Plasma version, kernel, InnyGrOS commit, and a link to the saved reports for every test session here.
