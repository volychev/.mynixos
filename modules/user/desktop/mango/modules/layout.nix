{ lib }:
''
    # Default Layout
    tagrule=id:1,layout_name:vertical_scroller
    tagrule=id:2,layout_name:vertical_scroller
    tagrule=id:3,layout_name:vertical_scroller
    tagrule=id:4,layout_name:vertical_scroller
    tagrule=id:5,layout_name:vertical_scroller
    tagrule=id:6,layout_name:vertical_scroller
    tagrule=id:7,layout_name:vertical_scroller
    tagrule=id:8,layout_name:vertical_scroller
    tagrule=id:9,layout_name:vertical_scroller

    # Master
    default_nmaster = 1
    default_mfact = 0.50
    new_is_master = 1

    # Scroller
    scroller_structs = 5
    scroller_default_proportion = 0.975
    scroller_default_proportion_single = 1.00
    scroller_ignore_proportion_single = 0
    scroller_focus_center = 0
    scroller_prefer_center = 0
    scroller_prefer_overspread = 1

    # Overview
    overviewgappi = 5
    overviewgappo = 15
''
