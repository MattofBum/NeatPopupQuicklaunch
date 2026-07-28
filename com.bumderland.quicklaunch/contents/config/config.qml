// Original author: piotr4@gmail.com
// License: GPLv3
//
// Plasma 6 port and update by Matt Galanto (with help from Grok)
// Based on: https://github.com/Risu/CoolPopupQuicklaunch

import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: "Settings"
        icon: "configure"
        source: "configAppearance.qml"
    }
}
