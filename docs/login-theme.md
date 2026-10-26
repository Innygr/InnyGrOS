# Blacklight Matrix login theme

The optional **Blacklight Matrix** SDDM theme continues the black-and-green InnyGrOS identity from the Plymouth boot animation into the graphical login greeter. It uses QML and text/vector elements only; it does not launch the terminal app, access the network, or include a wallpaper image.

## Check status

From the repository root:

```bash
bash scripts/login-theme.sh status
```

## Install

This theme is for systems using SDDM (the usual display manager on Kubuntu), not GDM or other greeters. Check that SDDM is installed and that you can reach a text console or recovery mode before changing the login theme.

```bash
sudo bash scripts/login-theme.sh install
```

Read the prompt and type `INSTALL`. The helper refuses to overwrite an existing theme directory or its dedicated config file. It installs the theme into `/usr/share/sddm/themes/blacklight` and adds `/etc/sddm.conf.d/90-innygros-blacklight.conf`. It does not restart SDDM or change Plymouth/GRUB. Log out only when ready to test the greeter.

## Update an installed theme

Pull the latest repository changes, then refresh the files already installed under `/usr/share/sddm/themes/blacklight`:

```bash
git pull --ff-only origin main
sudo bash scripts/login-theme.sh update
```

Type `UPDATE` at the prompt. This replaces only the theme's QML and metadata files; it does not change the selected display manager or restart SDDM. Log out to test the updated design.

## Uninstall

```bash
sudo bash scripts/login-theme.sh uninstall
```

Type `REMOVE`. The helper removes only its dedicated config drop-in and the two files it installed. SDDM then uses the theme selected by the remaining system configuration. If the config drop-in was edited so it no longer matches the expected setting, the helper refuses to remove it automatically.

## Recovery notes

- Keep a working session open until you are ready to test the greeter.
- If the greeter is unusable, switch to a text console (often Ctrl+Alt+F3), log in, and run the uninstall command from the repository checkout with sudo.
- This theme is experimental. QML/theme compatibility depends on the installed SDDM and Qt versions; automated checks inspect the source and installer but do not emulate an actual SDDM greeter.
- The theme does not change the user's password, accounts, or session configuration.
