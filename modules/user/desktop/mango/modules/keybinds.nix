{ lib }:
''
	bind=SUPER,Space,spawn,kitty
	bind=SUPER,x,killclient
	bind=SUPER,Escape,spawn,mmsg-layout-switch

	bind=SUPER,z,spawn,zen-beta
	bind=SUPER,t,spawn,Telegram
	bind=SUPER,o,spawn,obsidian
	bind=SUPER,n,spawn,Throne
	bind=SUPER,c,spawn,code
	bind=SUPER,f,spawn,nautilus
	bind=SUPER,w,spawn,kitty -- nmtui
	bind=SUPER,b,spawn,blueman-manager
	bind=SUPER+Shift,T,spawn,screenshot-ocr
	bind=SUPER,s,spawn,screenshot
	bind=SUPER+Shift,s,spawn,screenshot
	bind=SUPER,r,spawn,ags-interactive-center search
	bind=SUPER,v,spawn,ags-interactive-center clipboard

	gesturebind=none,right,3,viewtoleft
	gesturebind=none,left,3,viewtoright
	gesturebind=none,up,3,spawn,mmsg-scroll up
	gesturebind=none,down,3,spawn,mmsg-scroll down
	gesturebind=SUPER,up,3,scroller_stack,up
	gesturebind=SUPER,down,3,scroller_stack,down
	gesturebind=SUPER,right,3,tagtoleft
	gesturebind=SUPER,left,3,tagtoright
	gesturebind=none,up,4,toggleoverview
	gesturebind=none,down,4,toggleoverview

	bind=NONE,XF86MonBrightnessUp,spawn,brightnessctl set 2%+
	bind=SHIFT,XF86MonBrightnessUp,spawn,brightnessctl set 100%
	bind=NONE,XF86MonBrightnessDown,spawn,brightnessctl set 2%-
	bind=SHIFT,XF86MonBrightnessDown,spawn,brightnessctl set 1%

	bind=NONE,XF86AudioRaiseVolume,spawn,wpctl set-volume @DEFAULT_SINK@ 5%+
	bind=NONE,XF86AudioLowerVolume,spawn,wpctl set-volume @DEFAULT_SINK@ 5%-
	bind=NONE,XF86AudioMute,spawn,wpctl set-mute @DEFAULT_SINK@ toggle
	bind=SHIFT,XF86AudioMute,spawn,wpctl set-mute @DEFAULT_SOURCE@ toggle

	bind=SUPER,1,view,1
	bind=SUPER,2,view,2
	bind=SUPER,3,view,3
	bind=SUPER,4,view,4
	bind=SUPER,5,view,5
	bind=SUPER,6,view,6
	bind=SUPER,7,view,7
	bind=SUPER,8,view,8
	bind=SUPER,9,view,9
	bind=SUPER,0,view,0

	bind=SUPER+SHIFT,1,tag,1
	bind=SUPER+SHIFT,2,tag,2
	bind=SUPER+SHIFT,3,tag,3
	bind=SUPER+SHIFT,4,tag,4
	bind=SUPER+SHIFT,5,tag,5
	bind=SUPER+SHIFT,6,tag,6
	bind=SUPER+SHIFT,7,tag,7
	bind=SUPER+SHIFT,8,tag,8
	bind=SUPER+SHIFT,9,tag,9
''
