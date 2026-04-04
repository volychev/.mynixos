{ lib }:
''
	exec-once=xwayland-satellite :11
	exec=echo "Xft.dpi: 180" | xrdb -merge
	exec=awww-daemon
	exec=awww img ${../wallpaper.png} --transition-step 255
	exec=sudo touchscreen-innhibit
	exec-once=ags run ${../../ags}
	exec-once=kitty &
	exec-once=Throne &
	exec-once=power-mode restore --quiet &
	exec-once=power-mode-daemon &
	exec-once=screen-idle-daemon &
	exec-once=wl-paste --type text --watch cliphist store
	exec-once=wl-paste --type image --watch cliphist store
''
