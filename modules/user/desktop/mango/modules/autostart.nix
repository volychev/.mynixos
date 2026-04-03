{ lib }:
''
	exec=awww-daemon
	exec=awww img ${../wallpaper.png} --transition-step 255
	exec=sudo touchscreen-innhibit
	exec-once=ags run ${../../ags}
	exec-once=kitty &
	exec-once=Throne &
	exec-once=wl-paste --type text --watch cliphist store
	exec-once=wl-paste --type image --watch cliphist store
''
