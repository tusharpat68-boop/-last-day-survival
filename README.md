# LAST DAY: SURVIVAL (Phase 1)

Godot 4.7.2 (Mobile renderer), GDScript. Package: com.lastday.survival

## Get the project onto GitHub from Termux
```
pkg update -y && pkg upgrade -y
pkg install -y git unzip
termux-setup-storage
cd ~
unzip -o ~/storage/downloads/last-day-survival-phase1.zip -d ~
cd ~/last-day-survival
git init -b main
git config user.name "YOUR NAME"
git config user.email "YOUR_EMAIL"
git add -A
git commit -m "Phase 1 foundation"
git remote add origin https://github.com/YOUR_USER/last-day-survival.git
git push -u origin main
```
GitHub asks for a username and password: use a Personal Access Token
(GitHub > Settings > Developer settings > Personal access tokens, "repo" scope) as the password.
Create the empty repo `last-day-survival` on github.com first (no README).

## Build the APK
Pushing to `main` starts the workflow. Or: repo > Actions > "Build Android APK" > Run workflow.
When it finishes, open the run and download the artifact `last-day-survival-debug-apk`
(a zip containing the .apk), then install it on your phone.

## Desktop test controls (not needed on Android)
WASD move, Shift sprint, Space jump, C crouch, V camera switch, Esc pause. Mouse acts as touch.

## Phase 2 (survival stats, backpack, resources)
Tunable values: `data/survival/config.json` (drain rates, regen, stamina costs) and
`data/items/items.json` (items). Edit them, commit, push, and rebuild - no code changes needed.
