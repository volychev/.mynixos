{ lib }:
''
    env=DISPLAY,:11
    monitorrule=name:^eDP-1$,width:2880,height:1800,refresh:120,scale:1.8,vrr=0

    syncobj_enable=1

    trackpad_natural_scrolling=1
    mouse_natural_scrolling=1
    cursor_hide_timeout=5
    drag_tile_to_tile=1
    drag_lock=0
    disable_while_typing=0
    accel_speed=-0.125

    xkb_rules_layout=us,ru
    xkb_rules_options=grp:alt_shift_toggle
''
