import { Astal, Gtk } from "ags/gtk4";
import Wp from "gi://AstalWp";
import Apps from "gi://AstalApps";
import Notifd from "gi://AstalNotifd";
import GLib from "gi://GLib";
import Gio from "gi://Gio";
import Battery from "gi://AstalBattery";
import Gdk from "gi://Gdk";
import { InteractiveCenterMode, subscribeInteractiveCenterRequests } from "./interactiveCenterControl";

const INTERACTIVE_MODES: InteractiveCenterMode[] = ["search", "clipboard", "notifications"];
type FocusWindow = Gtk.Window & { keymode?: Astal.Keymode };
const MAX_APPLICATION_RESULTS = 20;
const INTERACTIVE_FOCUS_GRACE_US = 420_000;

function clearBoxChildren(box: Gtk.Box) {
    let child = box.get_first_child();
    while (child) {
        box.remove(child);
        child = box.get_first_child();
    }
}

function ensureButtonVisible(scrolledWindow: Gtk.ScrolledWindow, button: Gtk.Button) {
    const adjustment = scrolledWindow.get_vadjustment();
    if (!adjustment) {
        return;
    }

    const allocation = button.get_allocation();
    const top = adjustment.get_value();
    const bottom = top + adjustment.get_page_size();
    const itemTop = allocation.y;
    const itemBottom = allocation.y + allocation.height;

    if (itemBottom > bottom) {
        adjustment.set_value(itemBottom - adjustment.get_page_size());
    } else if (itemTop < top) {
        adjustment.set_value(itemTop);
    }
}

function setWindowKeymode(widget: Gtk.Widget, keymode: Astal.Keymode) {
    const root = widget.get_root();
    if (root instanceof Gtk.Window && "keymode" in root) {
        const focusWindow = root as FocusWindow;
        if (focusWindow.keymode !== keymode) {
            focusWindow.keymode = keymode;
        }
    }
}

function clearWindowFocus(widget: Gtk.Widget) {
    const root = widget.get_root();
    if (root instanceof Gtk.Window) {
        root.set_focus(null);
    }
}

function isDescendantOf(widget: Gtk.Widget | null, ancestor: Gtk.Widget) {
    let current = widget;
    while (current) {
        if (current === ancestor) {
            return true;
        }
        current = current.get_parent();
    }

    return false;
}

function focusWidget(widget: Gtk.Widget, captureInput = true) {
    let attempts = 0;

    const tryFocus = () => {
        attempts += 1;
        if (captureInput) {
            setWindowKeymode(widget, Astal.Keymode.EXCLUSIVE);
        }
        const root = widget.get_root();
        if (root instanceof Gtk.Window) {
            root.set_focus(widget);
        }
        widget.grab_focus();

        return widget.has_focus || attempts >= 6;
    };

    if (tryFocus()) {
        return;
    }

    GLib.timeout_add(GLib.PRIORITY_DEFAULT_IDLE, 20, () => {
        if (tryFocus()) {
            return GLib.SOURCE_REMOVE;
        }

        return GLib.SOURCE_CONTINUE;
    });
}

function focusEntry(entry: Gtk.Entry) {
    let attempts = 0;

    const tryFocus = () => {
        attempts += 1;
        setWindowKeymode(entry, Astal.Keymode.EXCLUSIVE);
        const root = entry.get_root();
        if (root instanceof Gtk.Window) {
            root.set_focus(entry);
        }
        entry.grab_focus();
        entry.set_position(-1);

        return entry.has_focus || attempts >= 6;
    };

    if (tryFocus()) {
        return;
    }

    GLib.timeout_add(GLib.PRIORITY_DEFAULT_IDLE, 20, () => {
        if (tryFocus()) {
            return GLib.SOURCE_REMOVE;
        }

        return GLib.SOURCE_CONTINUE;
    });
}

function clearTimeoutSource(sourceId: number | null): null {
    if (sourceId === null) {
        return null;
    }

    if (GLib.MainContext.default().find_source_by_id(sourceId)) {
        GLib.source_remove(sourceId);
    }

    return null;
}

function ensureFocusedInput(entry: Gtk.Entry) {
    focusEntry(entry);
    setWindowKeymode(entry, Astal.Keymode.EXCLUSIVE);
}

function isRootWindowActive(root: Gtk.Root | null) {
    if (!(root instanceof Gtk.Window)) {
        return false;
    }
    if ("is_active" in root && typeof root.is_active === "function") {
        return root.is_active();
    }

    const activeProperty = root.get_property("is-active");
    return typeof activeProperty === "boolean" ? activeProperty : true;
}

export default function InteractiveCenter() {
    const stack = new Gtk.Stack();
    stack.transition_type = Gtk.StackTransitionType.SLIDE_UP_DOWN;
    stack.transition_duration = 200;

    let displayTimeout: number | null = null;
    let searchDebounce: number | null = null;
    let clipboardDebounce: number | null = null;
    let searchBlurTimeout: number | null = null;
    let clipboardBlurTimeout: number | null = null;
    let notificationsBlurTimeout: number | null = null;
    let interactiveFocusWatchTimeout: number | null = null;
    let interactiveFocusWatchMode: InteractiveCenterMode | null = null;
    let interactiveFocusWatchGraceUntilUs = 0;

    let lastVolumeValue = -1;
    let lastMuteState = false;
    let lastChargingState = false;
    let lastBrightnessValue = -1;

    let applicationIndex = 0;
    let applicationItems: Gtk.Button[] = [];
    let applicationActions: (() => void)[] = [];

    let clipboardIndex = 0;
    let clipboardItems: Gtk.Button[] = [];
    let clipboardActions: (() => void)[] = [];
    let suppressSearchChanged = false;
    let suppressClipboardChanged = false;
    let defaultInteractiveMode: InteractiveCenterMode = "search";
    let activeInteractiveMode: InteractiveCenterMode = "search";

    const showState = (
        state: "search" | "clipboard" | "notifications" | "volume" | "brightness" | "battery",
    ) => {
        displayTimeout = clearTimeoutSource(displayTimeout);

        if (state !== "search" && state !== "clipboard" && state !== "notifications") {
            displayTimeout = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 2000, () => {
                stack.set_visible_child_name(defaultInteractiveMode);
                activeInteractiveMode = defaultInteractiveMode;
                displayTimeout = null;
                return GLib.SOURCE_REMOVE;
            });
        }

        if (state === "search" || state === "clipboard" || state === "notifications") {
            activeInteractiveMode = state;
        }

        if (stack.get_visible_child_name() !== state) {
            stack.set_visible_child_name(state);
        }

        if (state !== "search") {
            searchBlurTimeout = clearTimeoutSource(searchBlurTimeout);
            applicationPopover.set_visible(false);
            setWindowKeymode(searchEntry, Astal.Keymode.ON_DEMAND);
        }
        if (state !== "clipboard") {
            clipboardBlurTimeout = clearTimeoutSource(clipboardBlurTimeout);
            clipboardPopover.set_visible(false);
            setWindowKeymode(clipboardEntry, Astal.Keymode.ON_DEMAND);
        }
        if (state !== "notifications") {
            notificationsBlurTimeout = clearTimeoutSource(notificationsBlurTimeout);
            notificationsPopover.set_visible(false);
            setWindowKeymode(notificationsBox, Astal.Keymode.ON_DEMAND);
        }
        if (state !== "search" && state !== "clipboard" && state !== "notifications") {
            interactiveFocusWatchTimeout = clearTimeoutSource(interactiveFocusWatchTimeout);
            interactiveFocusWatchMode = null;
            interactiveFocusWatchGraceUntilUs = 0;
        }
    };

    const focusInsideMode = (mode: InteractiveCenterMode) => {
        const root = stack.get_root();
        if (!(root instanceof Gtk.Window)) {
            return false;
        }
        const focusedWidget = root.get_focus();
        if (!focusedWidget) {
            return false;
        }
        if (mode === "search") {
            return isDescendantOf(focusedWidget, searchBox) || isDescendantOf(focusedWidget, applicationPopover);
        }
        if (mode === "clipboard") {
            return isDescendantOf(focusedWidget, clipboardBox) || isDescendantOf(focusedWidget, clipboardPopover);
        }
        return isDescendantOf(focusedWidget, notificationsBox) || isDescendantOf(focusedWidget, notificationsPopover);
    };

    const closeInteractiveMode = (mode: InteractiveCenterMode) => {
        if (mode === "search") {
            clearApplicationSearch();
            showState(defaultInteractiveMode);
            setWindowKeymode(searchEntry, Astal.Keymode.ON_DEMAND);
            clearWindowFocus(searchEntry);
            return;
        }
        if (mode === "clipboard") {
            clearClipboardSearch();
            showState(defaultInteractiveMode);
            setWindowKeymode(clipboardEntry, Astal.Keymode.ON_DEMAND);
            clearWindowFocus(clipboardEntry);
            return;
        }
        closeNotificationsPopover();
    };

    const startInteractiveFocusWatch = (mode: InteractiveCenterMode, graceUs = INTERACTIVE_FOCUS_GRACE_US) => {
        interactiveFocusWatchMode = mode;
        interactiveFocusWatchGraceUntilUs = GLib.get_monotonic_time() + graceUs;
        interactiveFocusWatchTimeout = clearTimeoutSource(interactiveFocusWatchTimeout);
        interactiveFocusWatchTimeout = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 90, () => {
            if (interactiveFocusWatchMode !== mode || stack.get_visible_child_name() !== mode) {
                interactiveFocusWatchTimeout = null;
                return GLib.SOURCE_REMOVE;
            }

            const root = stack.get_root();
            const windowActive = isRootWindowActive(root);
            const modeFocused = focusInsideMode(mode);

            if (windowActive && modeFocused) {
                interactiveFocusWatchGraceUntilUs = 0;
                return GLib.SOURCE_CONTINUE;
            }

            if (interactiveFocusWatchGraceUntilUs !== 0 && GLib.get_monotonic_time() < interactiveFocusWatchGraceUntilUs) {
                return GLib.SOURCE_CONTINUE;
            }

            closeInteractiveMode(mode);
            interactiveFocusWatchTimeout = null;
            interactiveFocusWatchMode = null;
            interactiveFocusWatchGraceUntilUs = 0;
            return GLib.SOURCE_REMOVE;
        });
    };

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
    const searchEntry = <entry cssClasses={["zone-entry"]} placeholder_text="Search..." /> as Gtk.Entry;
    const searchBox = (
        <box cssClasses={["interactive-zone-box"]} halign={Gtk.Align.CENTER}>
            {searchIcon}
            {searchEntry}
        </box>
    ) as Gtk.Box;

    const applicationPopover = new Gtk.Popover();
    const applicationPopoverContent = <box cssClasses={["search-results"]} orientation={Gtk.Orientation.VERTICAL} spacing={2} /> as Gtk.Box;
    const applicationScrollWindow = new Gtk.ScrolledWindow({
        hscrollbar_policy: Gtk.PolicyType.NEVER,
        vscrollbar_policy: Gtk.PolicyType.AUTOMATIC,
        min_content_height: 100,
        max_content_height: 260,
    });
    applicationScrollWindow.set_child(applicationPopoverContent);
    applicationPopover.set_child(applicationScrollWindow);
    applicationPopover.set_parent(searchBox);
    applicationPopover.set_autohide(false);
    applicationPopover.set_can_focus(false);
    applicationPopover.set_has_arrow(false);

    const astalApplications = new Apps.Apps();
    let applicationCache: Apps.Application[] = [];

    const refreshApplicationCache = () => {
        applicationCache = [...astalApplications.list].sort((left, right) => {
            return left.name.localeCompare(right.name, undefined, { sensitivity: "base" });
        });
    };
    refreshApplicationCache();
    astalApplications.connect("notify::list", refreshApplicationCache);
    if (applicationCache.length === 0) {
        astalApplications.reload();
    }

    const clearApplicationSearch = () => {
        searchDebounce = clearTimeoutSource(searchDebounce);
        searchBlurTimeout = clearTimeoutSource(searchBlurTimeout);

        suppressSearchChanged = true;
        if (searchEntry.get_text() !== "") {
            searchEntry.set_text("");
        }
        suppressSearchChanged = false;

        clearBoxChildren(applicationPopoverContent);
        applicationItems = [];
        applicationActions = [];
        applicationIndex = 0;
        applicationPopover.set_visible(false);
    };

    const executeApplicationSearch = () => {
        const searchText = searchEntry.get_text().trim().toLowerCase();

        clearBoxChildren(applicationPopoverContent);
        applicationItems = [];
        applicationActions = [];
        applicationIndex = 0;

        const sourceApplications = applicationCache.length > 0 ? applicationCache : astalApplications.fuzzy_query("");
        const searchResults =
            searchText === ""
                ? sourceApplications
                : sourceApplications.filter((applicationItem) => {
                      const name = (applicationItem.name ?? "").toLowerCase();
                      const entry = (applicationItem.entry ?? "").toLowerCase();
                      const executable = (applicationItem.executable ?? "").toLowerCase();
                      const description = (applicationItem.description ?? "").toLowerCase();
                      const keywords = (applicationItem.keywords ?? []).some((keyword) => {
                          return keyword.toLowerCase().includes(searchText);
                      });

                      return (
                          name.includes(searchText) ||
                          entry.includes(searchText) ||
                          executable.includes(searchText) ||
                          description.includes(searchText) ||
                          keywords
                      );
                  });
        const visibleResults = searchResults.slice(0, MAX_APPLICATION_RESULTS);

        if (visibleResults.length === 0) {
            applicationPopover.set_visible(false);
            return;
        }

        visibleResults.forEach((applicationItem) => {
            const applicationAction = () => {
                applicationItem.launch();
                clearApplicationSearch();
                setWindowKeymode(searchEntry, Astal.Keymode.ON_DEMAND);
                clearWindowFocus(searchEntry);
            };
            applicationActions.push(applicationAction);

            const applicationButton = new Gtk.Button();
            applicationButton.set_can_focus(false);
            applicationButton.add_css_class("search-app-button");
            applicationButton.connect("clicked", applicationAction);

            const applicationRow = new Gtk.Box({
                orientation: Gtk.Orientation.HORIZONTAL,
                spacing: 8,
            });
            applicationRow.halign = Gtk.Align.START;

            const applicationIcon = new Gtk.Image();
            applicationIcon.icon_name = applicationItem.icon_name || "application-x-executable-symbolic";
            applicationIcon.pixel_size = 18;

            const applicationLabel = new Gtk.Label({ label: applicationItem.name });
            applicationLabel.halign = Gtk.Align.START;
            applicationLabel.set_xalign(0);
            applicationLabel.set_max_width_chars(42);

            applicationRow.append(applicationIcon);
            applicationRow.append(applicationLabel);
            applicationButton.set_child(applicationRow);

            applicationItems.push(applicationButton);
            applicationPopoverContent.append(applicationButton);
        });

        updateApplicationSelection();
        applicationPopover.set_visible(true);
    };

    searchEntry.connect("changed", () => {
        if (suppressSearchChanged || stack.get_visible_child_name() !== "search") {
            return;
        }
        searchDebounce = clearTimeoutSource(searchDebounce);
        searchDebounce = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 60, () => {
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

    searchEntry.connect("notify::has-focus", () => {
        if (searchEntry.has_focus) {
            searchBlurTimeout = clearTimeoutSource(searchBlurTimeout);
            return;
        }

        startInteractiveFocusWatch("search");
    });

    const searchKeyController = new Gtk.EventControllerKey();
    searchKeyController.connect("key-pressed", (_controller, keyValue) => {
        if (keyValue === Gdk.KEY_Escape) {
            clearApplicationSearch();
            searchEntry.set_text("");
            showState(defaultInteractiveMode);
            setWindowKeymode(searchEntry, Astal.Keymode.ON_DEMAND);
            clearWindowFocus(searchEntry);
            return true;
        }

        if (!applicationPopover.get_visible() || applicationItems.length === 0) {
            return false;
        }

        if (keyValue === Gdk.KEY_Down) {
            applicationIndex = Math.min(applicationIndex + 1, applicationItems.length - 1);
            updateApplicationSelection();
            ensureButtonVisible(applicationScrollWindow, applicationItems[applicationIndex]);
            return true;
        }

        if (keyValue === Gdk.KEY_Up) {
            applicationIndex = Math.max(applicationIndex - 1, 0);
            updateApplicationSelection();
            ensureButtonVisible(applicationScrollWindow, applicationItems[applicationIndex]);
            return true;
        }

        if (keyValue === Gdk.KEY_Return || keyValue === Gdk.KEY_KP_Enter) {
            if (applicationActions[applicationIndex]) {
                applicationActions[applicationIndex]();
            }
            return true;
        }

        return false;
    });
    searchEntry.add_controller(searchKeyController);

    stack.add_named(searchBox, "search");

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
        max_content_height: 360,
    });
    clipboardScrollWindow.set_child(clipboardContent);

    clipboardPopover.set_child(clipboardScrollWindow);
    clipboardPopover.set_parent(clipboardBox);
    clipboardPopover.set_autohide(false);
    clipboardPopover.set_can_focus(false);
    clipboardPopover.set_has_arrow(false);

    const clearClipboardSearch = () => {
        clipboardDebounce = clearTimeoutSource(clipboardDebounce);
        clipboardBlurTimeout = clearTimeoutSource(clipboardBlurTimeout);

        suppressClipboardChanged = true;
        if (clipboardEntry.get_text() !== "") {
            clipboardEntry.set_text("");
        }
        suppressClipboardChanged = false;

        clearBoxChildren(clipboardContent);
        clipboardItems = [];
        clipboardActions = [];
        clipboardIndex = 0;
        clipboardPopover.set_visible(false);
    };

    const executeClipboardSearch = () => {
        const clipboardQuery = clipboardEntry.get_text().toLowerCase();
        const clipboardProcess = Gio.Subprocess.new(["cliphist", "list"], Gio.SubprocessFlags.STDOUT_PIPE);

        clipboardProcess.communicate_utf8_async(null, null, (subprocess, asyncResult) => {
            try {
                const [, standardOutput] = subprocess!.communicate_utf8_finish(asyncResult);

                clearBoxChildren(clipboardContent);
                clipboardItems = [];
                clipboardActions = [];
                clipboardIndex = 0;

                if (!standardOutput) {
                    clipboardPopover.set_visible(false);
                    return;
                }

                const clipboardLines = standardOutput
                    .split("\n")
                    .map((line) => line.trimEnd())
                    .filter((line) => line.trim() !== "");

                const resultsToShow =
                    clipboardQuery === ""
                        ? clipboardLines
                        : clipboardLines.filter((line) => line.toLowerCase().includes(clipboardQuery));

                if (resultsToShow.length === 0) {
                    clipboardPopover.set_visible(false);
                    return;
                }

                resultsToShow.forEach((line) => {
                    const lineParts = line.split("\t");
                    const identifier = lineParts[0];
                    const textParts = lineParts.slice(1);
                    const rawText = textParts.join("\t") || "[ Image / Binary ]";
                    const displayText = rawText.length > 52 ? `${rawText.slice(0, 52)}...` : rawText;

                    const clipboardAction = () => {
                        const quotedIdentifier = GLib.shell_quote(identifier);
                        Gio.Subprocess.new(
                            ["bash", "-c", `cliphist decode ${quotedIdentifier} | wl-copy`],
                            Gio.SubprocessFlags.NONE,
                        );
                        clearClipboardSearch();
                        showState(defaultInteractiveMode);
                        setWindowKeymode(clipboardEntry, Astal.Keymode.ON_DEMAND);
                        clearWindowFocus(clipboardEntry);
                    };
                    clipboardActions.push(clipboardAction);

                    const clipboardButton = new Gtk.Button();
                    clipboardButton.set_can_focus(false);
                    clipboardButton.add_css_class("search-app-button");
                    clipboardButton.connect("clicked", clipboardAction);

                    const clipboardLabel = new Gtk.Label({ label: displayText });
                    clipboardLabel.halign = Gtk.Align.START;
                    clipboardLabel.set_xalign(0);
                    clipboardLabel.set_max_width_chars(42);
                    clipboardButton.set_child(clipboardLabel);

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
        if (suppressClipboardChanged || stack.get_visible_child_name() !== "clipboard") {
            return;
        }
        clipboardDebounce = clearTimeoutSource(clipboardDebounce);
        clipboardDebounce = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 60, () => {
            executeClipboardSearch();
            clipboardDebounce = null;
            return GLib.SOURCE_REMOVE;
        });
    });

    clipboardEntry.connect("notify::has-focus", () => {
        if (clipboardEntry.has_focus) {
            clipboardBlurTimeout = clearTimeoutSource(clipboardBlurTimeout);
            return;
        }

        startInteractiveFocusWatch("clipboard");
    });

    const clipboardKeyController = new Gtk.EventControllerKey();
    clipboardKeyController.connect("key-pressed", (_controller, keyValue) => {
        if (keyValue === Gdk.KEY_Escape) {
            clearClipboardSearch();
            clipboardEntry.set_text("");
            showState(defaultInteractiveMode);
            setWindowKeymode(clipboardEntry, Astal.Keymode.ON_DEMAND);
            clearWindowFocus(clipboardEntry);
            return true;
        }

        if (!clipboardPopover.get_visible() || clipboardItems.length === 0) {
            return false;
        }

        if (keyValue === Gdk.KEY_Down) {
            clipboardIndex = Math.min(clipboardIndex + 1, clipboardItems.length - 1);
            updateClipboardSelection();
            ensureButtonVisible(clipboardScrollWindow, clipboardItems[clipboardIndex]);
            return true;
        }

        if (keyValue === Gdk.KEY_Up) {
            clipboardIndex = Math.max(clipboardIndex - 1, 0);
            updateClipboardSelection();
            ensureButtonVisible(clipboardScrollWindow, clipboardItems[clipboardIndex]);
            return true;
        }

        if (keyValue === Gdk.KEY_Return || keyValue === Gdk.KEY_KP_Enter) {
            if (clipboardActions[clipboardIndex]) {
                clipboardActions[clipboardIndex]();
            }
            return true;
        }

        return false;
    });
    clipboardEntry.add_controller(clipboardKeyController);

    stack.add_named(clipboardBox, "clipboard");

    const notificationsIcon = <label label="􀋚" cssClasses={["zone-icon", "clickable-icon"]} /> as Gtk.Label;
    const notificationsLabel = <label label="Notifications" cssClasses={["zone-text", "notifications-zone-text"]} /> as Gtk.Label;
    const notificationsBox = (
        <box cssClasses={["interactive-zone-box", "active"]} halign={Gtk.Align.CENTER}>
            {notificationsIcon}
            {notificationsLabel}
        </box>
    ) as Gtk.Box;

    const notificationsPopover = new Gtk.Popover();
    const notificationsContent = <box cssClasses={["search-results"]} orientation={Gtk.Orientation.VERTICAL} spacing={2} /> as Gtk.Box;
    const notificationsScrollWindow = new Gtk.ScrolledWindow({
        hscrollbar_policy: Gtk.PolicyType.NEVER,
        vscrollbar_policy: Gtk.PolicyType.AUTOMATIC,
        min_content_height: 100,
        max_content_height: 260,
    });
    notificationsScrollWindow.set_child(notificationsContent);
    notificationsPopover.set_child(notificationsScrollWindow);
    notificationsPopover.set_parent(notificationsBox);
    notificationsPopover.set_autohide(false);
    notificationsPopover.set_can_focus(false);
    notificationsPopover.set_has_arrow(false);

    const notifd = Notifd.get_default();

    const clearAllNotifications = () => {
        [...notifd.notifications].forEach((notification) => {
            notification.dismiss();
        });
        updateNotifications();
    };

    const closeNotificationsPopover = () => {
        notificationsBlurTimeout = clearTimeoutSource(notificationsBlurTimeout);
        notificationsPopover.set_visible(false);
        clearWindowFocus(notificationsBox);
        setWindowKeymode(notificationsBox, Astal.Keymode.ON_DEMAND);
        showState(defaultInteractiveMode);
    };

    const updateNotifications = () => {
        clearBoxChildren(notificationsContent);
        const notifications = [...notifd.notifications].sort((left, right) => right.time - left.time);
        defaultInteractiveMode = notifications.length > 0 ? "notifications" : "search";
        notificationsLabel.label = notifications.length > 0 ? `Notifications ${notifications.length}` : "Notifications";

        const visibleMode = stack.get_visible_child_name();
        if (
            !searchEntry.has_focus &&
            !clipboardEntry.has_focus &&
            (visibleMode === "search" || visibleMode === "notifications")
        ) {
            if (visibleMode !== defaultInteractiveMode) {
                stack.set_visible_child_name(defaultInteractiveMode);
            }
            activeInteractiveMode = defaultInteractiveMode;
        }

        if (notifications.length === 0) {
            const emptyLabel = new Gtk.Label({ label: "No notifications" });
            emptyLabel.halign = Gtk.Align.START;
            emptyLabel.set_xalign(0);
            emptyLabel.add_css_class("search-empty");
            notificationsContent.append(emptyLabel);
            return;
        }

        notifications.forEach((notification) => {
            const summary = notification.summary.trim() || notification.app_name.trim() || "Notification";
            const appIconImage = new Gtk.Image();
            appIconImage.pixel_size = 18;
            const appIconName = notification.app_icon.trim();
            const imagePath = notification.image.trim();

            try {
                if (appIconName.length > 0) {
                    if (appIconName.startsWith("/")) {
                        appIconImage.set_from_file(appIconName);
                    } else {
                        appIconImage.icon_name = appIconName;
                    }
                } else if (imagePath.length > 0 && imagePath.startsWith("/")) {
                    appIconImage.set_from_file(imagePath);
                } else {
                    appIconImage.icon_name = "dialog-information-symbolic";
                }
            } catch (error) {
                console.error(error);
                appIconImage.icon_name = "dialog-information-symbolic";
            }

            const notificationButton = new Gtk.Button();
            notificationButton.set_can_focus(false);
            notificationButton.add_css_class("search-app-button");
            notificationButton.connect("clicked", () => {
                notification.dismiss();
            });

            const notificationRow = new Gtk.Box({
                orientation: Gtk.Orientation.HORIZONTAL,
                spacing: 10,
            });
            notificationRow.halign = Gtk.Align.START;

            const notificationLabel = new Gtk.Label({ label: summary });
            notificationLabel.halign = Gtk.Align.START;
            notificationLabel.set_xalign(0);
            notificationLabel.set_max_width_chars(42);
            notificationLabel.add_css_class("notification-item-label");

            notificationRow.append(appIconImage);
            notificationRow.append(notificationLabel);
            notificationButton.set_child(notificationRow);

            notificationsContent.append(notificationButton);
        });
    };

    notifd.connect("notify::notifications", updateNotifications);
    notifd.connect("notified", updateNotifications);
    notifd.connect("resolved", updateNotifications);
    updateNotifications();

    stack.add_named(notificationsBox, "notifications");

    const openInteractiveMode = (mode: InteractiveCenterMode, focusInput = false) => {
        showState(mode);

        if (mode === "search") {
            executeApplicationSearch();
            applicationPopover.set_visible(true);
            if (focusInput) {
                ensureFocusedInput(searchEntry);
            }
            startInteractiveFocusWatch("search", focusInput ? 700_000 : INTERACTIVE_FOCUS_GRACE_US);
            return;
        }

        if (mode === "clipboard") {
            executeClipboardSearch();
            clipboardPopover.set_visible(true);
            if (focusInput) {
                ensureFocusedInput(clipboardEntry);
            }
            startInteractiveFocusWatch("clipboard", focusInput ? 700_000 : INTERACTIVE_FOCUS_GRACE_US);
            return;
        }

        updateNotifications();
        notificationsPopover.set_visible(true);
        focusWidget(notificationsBox, false);
        startInteractiveFocusWatch("notifications");
    };

    const searchIconClick = new Gtk.GestureClick();
    searchIconClick.connect("pressed", () => {
        openInteractiveMode("search", true);
    });
    searchIcon.add_controller(searchIconClick);

    const clipboardIconClick = new Gtk.GestureClick();
    clipboardIconClick.connect("pressed", () => {
        openInteractiveMode("clipboard");
    });
    clipboardIcon.add_controller(clipboardIconClick);

    const notificationsIconClick = new Gtk.GestureClick();
    notificationsIconClick.connect("pressed", () => {
        clearAllNotifications();
    });
    notificationsIcon.add_controller(notificationsIconClick);

    const notificationsLabelClick = new Gtk.GestureClick();
    notificationsLabelClick.connect("pressed", () => {
        openInteractiveMode("notifications");
    });
    notificationsLabel.add_controller(notificationsLabelClick);
    notificationsBox.set_focusable(true);
    notificationsBox.connect("notify::has-focus", () => {
        startInteractiveFocusWatch("notifications");
    });

    const notificationsKeyController = new Gtk.EventControllerKey();
    notificationsKeyController.connect("key-pressed", (_controller, keyValue) => {
        if (keyValue === Gdk.KEY_Escape) {
            closeNotificationsPopover();
            return true;
        }

        return false;
    });
    notificationsBox.add_controller(notificationsKeyController);

    const notificationsPopoverFocusController = new Gtk.EventControllerFocus();
    notificationsPopoverFocusController.connect("leave", () => {
        startInteractiveFocusWatch("notifications");
    });
    notificationsPopover.add_controller(notificationsPopoverFocusController);

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
        volumeScrollController.connect("scroll", (_controller, _deltaX, deltaY) => {
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
    stack.set_visible_child_name(defaultInteractiveMode);

    const interactiveCenterContainer = (
        <box cssClasses={["interactive-center-container"]} halign={Gtk.Align.CENTER}>
            {stack}
        </box>
    ) as Gtk.Box;

    const unsubscribeRequestHandler = subscribeInteractiveCenterRequests((request) => {
        openInteractiveMode(request.mode, request.focusInput);
    });
    interactiveCenterContainer.connect("notify::root", () => {
        if (!interactiveCenterContainer.get_root()) {
            interactiveFocusWatchTimeout = clearTimeoutSource(interactiveFocusWatchTimeout);
            interactiveFocusWatchMode = null;
            interactiveFocusWatchGraceUntilUs = 0;
            unsubscribeRequestHandler();
        }
    });

    return interactiveCenterContainer;
}
