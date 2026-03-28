import { Gtk } from "ags/gtk4";
import Wp from "gi://AstalWp";
import Apps from "gi://AstalApps";
import GLib from "gi://GLib";
import Gio from "gi://Gio";
import Battery from "gi://AstalBattery";
import Gdk from "gi://Gdk";
import Astal from "gi://Astal";

export default function InteractiveCenter() {
    const stack = new Gtk.Stack();
    stack.transition_type = Gtk.StackTransitionType.SLIDE_UP_DOWN;
    stack.transition_duration = 200;

    let displayTimeout: number | null = null;
    let searchDebounce: number | null = null;
    let clipboardDebounce: number | null = null;
    
    let lastVolumeValue = -1;
    let lastMuteState = false;
    let lastChargingState = false;
    let lastBrightnessValue = -1;

    const showState = (state: "search" | "clipboard" | "volume" | "brightness" | "battery") => {
        if (displayTimeout) {
            GLib.source_remove(displayTimeout);
            displayTimeout = null;
        }

        if (state !== "search" && state !== "clipboard") {
            displayTimeout = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 2000, () => {
                stack.set_visible_child_name("search");
                displayTimeout = null;
                return GLib.SOURCE_REMOVE;
            });
        }

        if (stack.get_visible_child_name() === state) {
            return;
        }
        stack.set_visible_child_name(state);
    };

    let applicationIndex = 0;
    let applicationItems: Gtk.Button[] = [];
    let applicationActions: (() => void)[] = [];

    const updateApplicationSelection = () => {
        applicationItems.forEach((button, index) => {
            if (index === applicationIndex) {
                button.add_css_class("selected");
            } else {
                button.remove_css_class("selected");
            }
        });
    };

    const searchIcon = <label label="􀊫" cssClasses={["zone-icon", "clickable-icon"]} /> as Gtk.Label;
    const searchIconClick = new Gtk.GestureClick();
    searchIconClick.connect("pressed", () => {
        showState("clipboard");
    });
    searchIcon.add_controller(searchIconClick);

    const searchEntry = <entry cssClasses={["zone-entry"]} placeholder_text="Search..." /> as Gtk.Entry;
    const searchBox = (
        <box cssClasses={["interactive-zone-box"]} halign={Gtk.Align.CENTER}>
            {searchIcon}
            {searchEntry}
        </box>
    ) as Gtk.Box;

    const applicationPopover = new Gtk.Popover();
    const applicationPopoverContent = <box cssClasses={["search-results"]} orientation={Gtk.Orientation.VERTICAL} spacing={2} /> as Gtk.Box;
    applicationPopover.set_child(applicationPopoverContent);
    applicationPopover.set_parent(searchBox);
    applicationPopover.set_autohide(false);
    applicationPopover.set_has_arrow(false);

    const astalApplications = new Apps.Apps();

    const executeApplicationSearch = () => {
        const searchText = searchEntry.get_text().toLowerCase();
        let child = applicationPopoverContent.get_first_child();
        while (child) {
            applicationPopoverContent.remove(child);
            child = applicationPopoverContent.get_first_child();
        }
        
        applicationItems = [];
        applicationActions = [];
        applicationIndex = 0;

        if (!searchText) {
            applicationPopover.set_visible(false);
            return;
        }

        const searchResults = astalApplications.fuzzy_query(searchText).slice(0, 6);
        if (searchResults.length === 0) {
            applicationPopover.set_visible(false);
            return;
        }

        searchResults.forEach((applicationItem) => {
            const applicationAction = () => {
                applicationItem.launch();
                applicationPopover.set_visible(false);
                searchEntry.set_text("");
            };
            applicationActions.push(applicationAction);

            const applicationButton = (
                <button cssClasses={["search-app-button"]} can_focus={false} onClicked={applicationAction}>
                    <box spacing={10} halign={Gtk.Align.START}>
                        <image icon_name={applicationItem.icon_name} pixel_size={24} />
                        <label label={applicationItem.name} halign={Gtk.Align.START} />
                    </box>
                </button>
            ) as Gtk.Button;
            
            applicationItems.push(applicationButton);
            applicationPopoverContent.append(applicationButton);
        });

        updateApplicationSelection();
        applicationPopover.set_visible(true);
    };

    searchEntry.connect("changed", () => {
        if (searchDebounce) {
            GLib.source_remove(searchDebounce);
        }
        searchDebounce = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 150, () => {
            executeApplicationSearch();
            searchDebounce = null;
            return GLib.SOURCE_REMOVE;
        });
    });

    searchEntry.connect("activate", () => {
        if (applicationActions[applicationIndex]) {
            applicationActions[applicationIndex]();
        }
    });

    const searchKeyController = new Gtk.EventControllerKey();
    searchKeyController.connect("key-pressed", (controller, keyValue) => {
        if (!applicationPopover.get_visible() || applicationItems.length === 0) {
            return false;
        }
        
        if (keyValue === Gdk.KEY_Down) {
            applicationIndex = Math.min(applicationIndex + 1, applicationItems.length - 1);
            updateApplicationSelection();
            return true;
        } else if (keyValue === Gdk.KEY_Up) {
            applicationIndex = Math.max(applicationIndex - 1, 0);
            updateApplicationSelection();
            return true;
        } else if (keyValue === Gdk.KEY_Return || keyValue === Gdk.KEY_KP_Enter) {
            if (applicationActions[applicationIndex]) {
                applicationActions[applicationIndex]();
            }
            return true;
        }
        return false;
    });
    searchEntry.add_controller(searchKeyController);

    stack.add_named(searchBox, "search");

    let clipboardIndex = 0;
    let clipboardItems: Gtk.Button[] = [];
    let clipboardActions: (() => void)[] = [];

    const updateClipboardSelection = () => {
        clipboardItems.forEach((button, index) => {
            if (index === clipboardIndex) {
                button.add_css_class("selected");
            } else {
                button.remove_css_class("selected");
            }
        });
    };

    const clipboardIcon = <label label="􀟺" cssClasses={["zone-icon", "clickable-icon"]} /> as Gtk.Label;
    const clipboardIconClick = new Gtk.GestureClick();
    clipboardIconClick.connect("pressed", () => {
        showState("search");
    });
    clipboardIcon.add_controller(clipboardIconClick);

    const clipboardEntry = <entry cssClasses={["zone-entry"]} placeholder_text="Clipboard..." /> as Gtk.Entry;
    const clipboardBox = (
        <box cssClasses={["interactive-zone-box"]} halign={Gtk.Align.CENTER}>
            {clipboardIcon}
            {clipboardEntry}
        </box>
    ) as Gtk.Box;

    const clipboardPopover = new Gtk.Popover();
    const clipboardContent = <box cssClasses={["search-results"]} orientation={Gtk.Orientation.VERTICAL} spacing={2} /> as Gtk.Box;
    
    const clipboardScrollWindow = new Gtk.ScrolledWindow({
        hscrollbar_policy: Gtk.PolicyType.NEVER,
        vscrollbar_policy: Gtk.PolicyType.AUTOMATIC,
        min_content_height: 100,
        max_content_height: 250
    });
    clipboardScrollWindow.set_child(clipboardContent);

    clipboardPopover.set_child(clipboardScrollWindow);
    clipboardPopover.set_parent(clipboardBox);
    clipboardPopover.set_autohide(false);
    clipboardPopover.set_can_focus(false);
    clipboardPopover.set_has_arrow(false);

    const executeClipboardSearch = () => {
        const clipboardQuery = clipboardEntry.get_text().toLowerCase();
        
        const clipboardProcess = Gio.Subprocess.new(["cliphist", "list"], Gio.SubprocessFlags.STDOUT_PIPE);
        clipboardProcess.communicate_utf8_async(null, null, (subprocess, asyncResult) => {
            try {
                const [, standardOutput] = subprocess!.communicate_utf8_finish(asyncResult);
                
                let child = clipboardContent.get_first_child();
                while (child) {
                    clipboardContent.remove(child);
                    child = clipboardContent.get_first_child();
                }

                clipboardItems = [];
                clipboardActions = [];
                clipboardIndex = 0;

                if (!standardOutput) {
                    clipboardPopover.set_visible(false);
                    return;
                }

                const clipboardLines = standardOutput.split("\n").filter((line) => {
                    return line.trim() !== "";
                });

                let resultsToShow = [];
                if (clipboardQuery === "") {
                    resultsToShow = clipboardLines.slice(0, 5);
                } else {
                    resultsToShow = clipboardLines.filter((line) => {
                        return line.toLowerCase().includes(clipboardQuery);
                    }).slice(0, 20);
                }

                if (resultsToShow.length === 0) {
                    clipboardPopover.set_visible(false);
                    return;
                }

                resultsToShow.forEach((line) => {
                    const lineParts = line.split("\t");
                    const identifier = lineParts[0];
                    const textParts = lineParts.slice(1);
                    const rawText = textParts.join("\t") || "[ Image / Binary ]";
                    
                    const displayText = rawText.length > 19
                        ? rawText.slice(0, 19) + "..." 
                        : rawText;

                    const clipboardAction = () => {
                        Gio.Subprocess.new(["bash", "-c", `cliphist decode '${identifier}' | wl-copy`], Gio.SubprocessFlags.NONE);
                        clipboardPopover.set_visible(false);
                        clipboardEntry.set_text("");
                        showState("search");
                    };
                    clipboardActions.push(clipboardAction);

                    const clipboardButton = (
                        <button cssClasses={["search-app-button"]} can_focus={false} onClicked={clipboardAction}>
                            <label label={displayText} maxWidthChars={30} halign={Gtk.Align.START} />
                        </button>
                    ) as Gtk.Button;

                    clipboardItems.push(clipboardButton);
                    clipboardContent.append(clipboardButton);
                });

                updateClipboardSelection();
                clipboardPopover.set_visible(true);
            } catch (error) {
                console.error(error);
            }
        });
    };

    clipboardEntry.connect("changed", () => {
        if (clipboardDebounce) {
            GLib.source_remove(clipboardDebounce);
        }
        clipboardDebounce = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 150, () => {
            executeClipboardSearch();
            clipboardDebounce = null;
            return GLib.SOURCE_REMOVE;
        });
    });

    const clipboardKeyController = new Gtk.EventControllerKey();
    clipboardKeyController.connect("key-pressed", (controller, keyValue) => {
        if (!clipboardPopover.get_visible() || clipboardItems.length === 0) {
            return false;
        }
        
        if (keyValue === Gdk.KEY_Down) {
            clipboardIndex = Math.min(clipboardIndex + 1, clipboardItems.length - 1);
            updateClipboardSelection();
            
            const selectedButton = clipboardItems[clipboardIndex];
            const adjustment = clipboardScrollWindow.get_vadjustment();
            if (adjustment && selectedButton) {
                const buttonAllocation = selectedButton.get_allocation();
                if (buttonAllocation.y + buttonAllocation.height > adjustment.get_value() + adjustment.get_page_size()) {
                    adjustment.set_value(buttonAllocation.y + buttonAllocation.height - adjustment.get_page_size());
                }
                if (buttonAllocation.y < adjustment.get_value()) {
                    adjustment.set_value(buttonAllocation.y);
                }
            }
            return true;
        } else if (keyValue === Gdk.KEY_Up) {
            clipboardIndex = Math.max(clipboardIndex - 1, 0);
            updateClipboardSelection();
            
            const selectedButton = clipboardItems[clipboardIndex];
            const adjustment = clipboardScrollWindow.get_vadjustment();
            if (adjustment && selectedButton) {
                const buttonAllocation = selectedButton.get_allocation();
                if (buttonAllocation.y < adjustment.get_value()) {
                    adjustment.set_value(buttonAllocation.y);
                }
                if (buttonAllocation.y + buttonAllocation.height > adjustment.get_value() + adjustment.get_page_size()) {
                    adjustment.set_value(buttonAllocation.y + buttonAllocation.height - adjustment.get_page_size());
                }
            }
            return true;
        } else if (keyValue === Gdk.KEY_Return || keyValue === Gdk.KEY_KP_Enter) {
            if (clipboardActions[clipboardIndex]) {
                clipboardActions[clipboardIndex]();
            }
            return true;
        }
        return false;
    });
    clipboardEntry.add_controller(clipboardKeyController);

    clipboardEntry.connect("notify::has-focus", () => {
        if (!clipboardEntry.has_focus) {
            clipboardPopover.set_visible(false);
        } else {
            executeClipboardSearch();
        }
    });

    stack.add_named(clipboardBox, "clipboard");

    const volumeIcon = <label cssClasses={["zone-icon"]} label="􀊩" /> as Gtk.Label;
    const volumeFill = <box cssClasses={["osd-fill"]} /> as Gtk.Box;
    const volumeBody = <box cssClasses={["osd-body"]}>{volumeFill}</box> as Gtk.Box;
    const volumeBox = (
        <box cssClasses={["interactive-zone-box", "active"]} halign={Gtk.Align.CENTER}>
            {volumeIcon}
            {volumeBody}
        </box>
    ) as Gtk.Box;

    const speakerDevice = Wp.get_default()?.audio.default_speaker;
    
    const updateVolumeInterface = () => {
        if (!speakerDevice) {
            return;
        }
        const volumePercentage = Math.min(Math.floor(speakerDevice.volume * 100), 100);
        const isDeviceMuted = speakerDevice.mute;

        volumeBody.set_size_request(100, 8);
        volumeFill.set_size_request(Math.max(4, volumePercentage), 8);

        if (isDeviceMuted || volumePercentage === 0) {
            volumeIcon.label = "􀊣";
        } else if (volumePercentage > 67) {
            volumeIcon.label = "􀊩";
        } else if (volumePercentage > 33) {
            volumeIcon.label = "􀊧";
        } else {
            volumeIcon.label = "􀊥";
        }

        if (volumePercentage !== lastVolumeValue || isDeviceMuted !== lastMuteState) {
            showState("volume");
            lastVolumeValue = volumePercentage;
            lastMuteState = isDeviceMuted;
        }
    };

    if (speakerDevice) {
        lastVolumeValue = Math.min(Math.floor(speakerDevice.volume * 100), 100);
        lastMuteState = speakerDevice.mute;
        
        speakerDevice.connect("notify::volume", updateVolumeInterface);
        speakerDevice.connect("notify::mute", updateVolumeInterface);

        const volumeScrollController = new Gtk.EventControllerScroll({ flags: Gtk.EventControllerScrollFlags.VERTICAL });
        volumeScrollController.connect("scroll", (controller, deltaX, deltaY) => {
            speakerDevice.volume = Math.max(0, Math.min(1, speakerDevice.volume + deltaY * 0.05));
            return true;
        });
        volumeBox.add_controller(volumeScrollController);

        const volumeClickController = new Gtk.GestureClick();
        volumeClickController.connect("pressed", () => {
            speakerDevice.mute = !speakerDevice.mute;
        });
        volumeBox.add_controller(volumeClickController);
    }
    stack.add_named(volumeBox, "volume");

    const brightnessIcon = <label cssClasses={["zone-icon"]} label="􀆭" /> as Gtk.Label;
    const brightnessFill = <box cssClasses={["osd-fill"]} /> as Gtk.Box;
    const brightnessBody = <box cssClasses={["osd-body"]}>{brightnessFill}</box> as Gtk.Box;
    const brightnessBox = (
        <box cssClasses={["interactive-zone-box", "active"]} halign={Gtk.Align.CENTER}>
            {brightnessIcon}
            {brightnessBody}
        </box>
    ) as Gtk.Box;

    const updateBrightnessInterface = (percentageValue: number) => {
        const cappedPercentage = Math.min(percentageValue, 100);
        brightnessBody.set_size_request(100, 8);
        brightnessFill.set_size_request(Math.max(4, cappedPercentage), 8);

        if (lastBrightnessValue !== -1 && lastBrightnessValue !== cappedPercentage) {
            showState("brightness");
        }
        lastBrightnessValue = cappedPercentage;
    };

    GLib.timeout_add(GLib.PRIORITY_DEFAULT, 500, () => {
        const brightnessProcess = Gio.Subprocess.new(["brightnessctl", "-m"], Gio.SubprocessFlags.STDOUT_PIPE);
        brightnessProcess.communicate_utf8_async(null, null, (subprocess, asyncResult) => {
            try {
                const [, standardOutput] = subprocess!.communicate_utf8_finish(asyncResult);
                if (standardOutput) {
                    const brightnessPercentage = parseInt(standardOutput.split(",")[3].replace("%", ""));
                    updateBrightnessInterface(brightnessPercentage);
                }
            } catch (error) {
                console.error(error);
            }
        });
        return GLib.SOURCE_CONTINUE;
    });
    stack.add_named(brightnessBox, "brightness");

    const batteryIcon = <label cssClasses={["zone-icon"]} label="􀋦" /> as Gtk.Label;
    const batteryFill = <box cssClasses={["osd-fill"]} /> as Gtk.Box;
    const batteryBody = <box cssClasses={["osd-body"]}>{batteryFill}</box> as Gtk.Box;
    const batteryBox = (
        <box cssClasses={["interactive-zone-box", "active"]} halign={Gtk.Align.CENTER}>
            {batteryIcon}
            {batteryBody}
        </box>
    ) as Gtk.Box;

    const batteryDevice = Battery.get_default();
    
    const updateBatteryInterface = () => {
        if (!batteryDevice) {
            return;
        }
        const isDeviceCharging = batteryDevice.charging;
        const batteryPercentage = Math.floor(batteryDevice.percentage * 100);

        batteryBody.set_size_request(100, 8);
        batteryFill.set_size_request(Math.max(4, batteryPercentage), 8);
        
        if (isDeviceCharging) {
            batteryIcon.label = "􀋦";
        } else {
            batteryIcon.label = "􀋪";
        }

        if (lastChargingState !== isDeviceCharging) {
            showState("battery");
            lastChargingState = isDeviceCharging;
        }
    };

    if (batteryDevice) {
        lastChargingState = batteryDevice.charging;
        updateBatteryInterface();
        batteryDevice.connect("notify::charging", updateBatteryInterface);
        batteryDevice.connect("notify::percentage", () => {
            batteryFill.set_size_request(Math.max(4, Math.floor(batteryDevice.percentage * 100)), 8);
        });
    }

    stack.add_named(batteryBox, "battery");
    stack.set_visible_child_name("search");

    const interactiveCenterContainer = (
        <box cssClasses={["interactive-center-container"]} halign={Gtk.Align.CENTER}>
            {stack}
        </box>
    ) as Gtk.Box;

    const stackScrollController = new Gtk.EventControllerScroll({
        flags: Gtk.EventControllerScrollFlags.VERTICAL
    });
    
    stackScrollController.connect("scroll", (controller, deltaX, deltaY) => {
        if (deltaY > 0) {
            showState("clipboard");
        }
        if (deltaY < 0) {
            showState("search");
        }
        return true;
    });
    
    interactiveCenterContainer.add_controller(stackScrollController);

    return interactiveCenterContainer;
}