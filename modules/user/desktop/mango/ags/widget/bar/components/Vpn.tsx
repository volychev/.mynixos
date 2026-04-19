import { Gtk } from "ags/gtk4";
import { execAsync } from "ags/process";
import Network from "gi://AstalNetwork";
import GLib from "gi://GLib?version=2.0";
import NM from "gi://NM?version=1.0";

const tunnelCheckCommand = `ip -o link show up 2>/dev/null | awk -F': ' '{print $2}' | grep -Eq '^(tun|tap|wg|tailscale|singtun|sbtun|nekoray|throne)' && echo 1 || echo 0`;

export default function VpnIndicator() {
    const network = Network.get_default();
    const icon = <label cssClasses={["vpn-badge"]} label="􀆪" visible={false} /> as Gtk.Label;

    const setVisibility = (connected: boolean) => {
        icon.visible = connected;
    };

    const hasActiveNetworkManagerVpn = () => {
        const activeConnections = network.client?.active_connections ?? [];
        return activeConnections.some(
            (connection) =>
                connection.vpn &&
                connection.state === NM.ActiveConnectionState.ACTIVATED,
        );
    };

    let updateGeneration = 0;
    const update = () => {
        const generation = ++updateGeneration;

        icon.halign = Gtk.Align.CENTER;
        icon.valign = Gtk.Align.CENTER;

        if (hasActiveNetworkManagerVpn()) {
            setVisibility(true);
            return;
        }

        execAsync(["bash", "-lc", tunnelCheckCommand])
            .then((output) => {
                if (generation !== updateGeneration) {
                    return;
                }

                setVisibility(output.trim() === "1");
            })
            .catch((error) => {
                if (generation !== updateGeneration) {
                    return;
                }

                console.error("Failed to read VPN status:", error);
                setVisibility(false);
            });
    };

    network.connect("notify::state", update);
    network.connect("notify::primary", update);
    if (network.client) {
        network.client.connect("notify::active-connections", update);
    }

    const timerId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 2500, () => {
        update();
        return GLib.SOURCE_CONTINUE;
    });

    icon.connect("destroy", () => {
        if (timerId) {
            GLib.source_remove(timerId);
        }
    });

    update();
    return icon;
}
