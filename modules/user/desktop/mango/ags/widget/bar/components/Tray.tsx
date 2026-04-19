import { Gtk } from "ags/gtk4";
import Tray from "gi://AstalTray";

function createTrayItem(trayItem: Tray.TrayItem): Gtk.MenuButton {
    const itemImage = <image pixel_size={16} /> as Gtk.Image;

    const updateImage = () => {
        itemImage.gicon = trayItem.gicon;
    };

    const updateTooltip = () => {
        menuButton.tooltip_markup = trayItem.tooltip_markup;
    };

    const menuButton = (
        <menubutton
            cssClasses={["tray-item-button"]}
            valign={Gtk.Align.CENTER}
            halign={Gtk.Align.CENTER}
            menu_model={trayItem.menu_model}
            has_frame={false}
        >
            {itemImage}
        </menubutton>
    ) as Gtk.MenuButton;

    if (trayItem.action_group) {
        menuButton.insert_action_group("dbusmenu", trayItem.action_group);
    }

    trayItem.connect("notify::gicon", updateImage);
    trayItem.connect("notify::tooltip-markup", updateTooltip);

    updateImage();
    updateTooltip();
    return menuButton;
}

export default function TrayModule() {
    const trayInstance = Tray.get_default();
    let isTrayExpanded = false;

    const arrowIcon = <label cssClasses={["tray-arrow-icon"]} label="􀆉" /> as Gtk.Label;
    const trayItemsBox = <box spacing={6} cssClasses={["tray-items-box"]} /> as Gtk.Box;

    const trayRevealer = (
        <revealer
            transition_type={Gtk.RevealerTransitionType.SLIDE_LEFT}
            transition_duration={250}
            reveal_child={false}
        >
            {trayItemsBox}
        </revealer>
    ) as Gtk.Revealer;

    const trayWidgetsMap = new Map<string, Gtk.Widget>();

    const addTrayItem = (itemId: string) => {
        const currentItem = trayInstance.get_item(itemId);

        if (!currentItem) {
            return;
        }

        const itemWidget = createTrayItem(currentItem);
        trayWidgetsMap.set(itemId, itemWidget);
        trayItemsBox.append(itemWidget);
    };

    const removeTrayItem = (itemId: string) => {
        const itemWidget = trayWidgetsMap.get(itemId);

        if (itemWidget) {
            trayItemsBox.remove(itemWidget);
            trayWidgetsMap.delete(itemId);
        }
    };

    trayInstance.connect("item-added", (tray, itemId) => {
        addTrayItem(itemId);
    });

    trayInstance.connect("item-removed", (tray, itemId) => {
        removeTrayItem(itemId);
    });

    const initialItems = trayInstance.get_items();
    for (let index = 0; index < initialItems.length; index++) {
        addTrayItem(initialItems[index].item_id);
    }

    const toggleBox = (
        <box cssClasses={["tray-toggle-box"]} valign={Gtk.Align.CENTER}>
            {arrowIcon}
        </box>
    ) as Gtk.Box;

    const clickController = new Gtk.GestureClick();
    
    clickController.connect("pressed", () => {
        isTrayExpanded = !isTrayExpanded;
        trayRevealer.reveal_child = isTrayExpanded;

        if (isTrayExpanded) {
            arrowIcon.label = "􀆊"; 
        } else {
            arrowIcon.label = "􀆉"; 
        }
    });
    
    toggleBox.add_controller(clickController);

    return (
        <box cssClasses={["tray-container"]} spacing={4} halign={Gtk.Align.END}>
            {trayRevealer}
            {toggleBox}
        </box>
    );
}