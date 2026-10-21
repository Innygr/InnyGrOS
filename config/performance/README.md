# Performance configuration

Future performance presets must explain each change, show current and proposed values, ask before applying changes, and provide rollback. Do not automatically change CPU/GPU governors, kernel settings, thermal controls, security services, or persistent power settings. Measure results instead of promising arbitrary speed gains.

## Measuring before and after

Use `scripts/performance-benchmark.sh` (or **Performance snapshot** in the Welcome Center) to record a baseline before changing anything, then again afterwards:

1. Reboot, log in, and wait about two minutes for startup tasks to settle.
2. Run `./scripts/performance-benchmark.sh --text --save`.
3. Apply one change, reboot, and repeat step 2.
4. Compare the two most recent saved reports with `./scripts/compare-reports.sh` (or **Compare last two saved performance snapshots** in the Welcome Center). It shows boot time, RAM, load, battery draw and CPU timing side by side. Pass two file names to compare older reports. For everything else, use `diff` or Kompare on the files in `~/.local/share/innygros/reports`.

Compare boot time, idle RAM use, load average, battery draw (on battery, screen brightness unchanged), and the median CPU timing. Run on the same power profile each time; the CPU timing is only meaningful on the same machine.
