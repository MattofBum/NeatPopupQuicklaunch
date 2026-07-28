// Original author: piotr4@gmail.com
// License: GPLv3
//
// Plasma 6 port and update by Matt Galanto (with help from Grok)
// Based on: https://github.com/Risu/CoolPopupQuicklaunch

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Qt.labs.folderlistmodel
import Qt.labs.platform as Platform

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root

    property var currentRootMenu: null
    // Root folder model
    property var rootModelCombiner: null

    preferredRepresentation: compactRepresentation

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: "Change Root Folder"
            icon.name: "folder-add"
            onTriggered: action_changeFolder()
        }
    ]

    Plasmoid.icon: {
        if (plasmoid.configuration.iconType === 0) {
            if (plasmoid.location === PlasmaCore.Types.LeftEdge) return "arrow-right"
            if (plasmoid.location === PlasmaCore.Types.RightEdge) return "arrow-left"
            return (plasmoid.location === PlasmaCore.Types.BottomEdge) ? "arrow-up" : "arrow-down"
        }
        if (plasmoid.configuration.iconType === 1) return Qt.resolvedUrl("../icons/qwhite.png")
        if (plasmoid.configuration.iconType === 2) return Qt.resolvedUrl("../icons/qblack.png")
        return plasmoid.configuration.genericFolderIcon
    }

    Component.onCompleted: {
        //console.log("rootModelCombiner with folder ", plasmoid.configuration.quicklaunchFolder)
        rootModelCombiner = objectGenerator.createModelCombiner(null, {"folder": plasmoid.configuration.quicklaunchFolder})
    }

    // Transparent host dialog for the cascading menus
    /*PlasmaCore.Dialog {
        id: menuHost
        type: PlasmaCore.Dialog.PopupMenu
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
        backgroundHints: PlasmaCore.Types.NoBackground
        color: "transparent"
        visible: false
        hideOnWindowDeactivate: true

        width: 750
        height: 550

        mainItem: Item {
            id: hostItem
            width: 750
            height: 550
            property var currentMenu: null
        }
    }*/

    // === Compact representation ===
    compactRepresentation: Item {
        id: compactRoot

        Layout.minimumWidth: plasmoid.configuration.slimIcon ? 20 : Kirigami.Units.iconSizes.small
        Layout.minimumHeight: Kirigami.Units.iconSizes.small
        Layout.preferredWidth: plasmoid.configuration.slimIcon ? 20 : Kirigami.Units.iconSizes.medium
        Layout.preferredHeight: Kirigami.Units.iconSizes.medium

        Kirigami.Icon {
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height) * 0.85
            height: width
            source: Plasmoid.icon
            active: mouseArea.containsMouse
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton

            onClicked: {
                // Toggle behaviour – click the icon again to close
                if (currentRootMenu) {
                    currentRootMenu.closeAll()
                    currentRootMenu = null
                    return
                }

                if (plasmoid.configuration.quicklaunchFolder === "" || !rootModelCombiner) {
                    folderDialog.open()
                    return
                }

                // Determine position of widget and figure out how to restrict the menu positioning
                var gpos = compactRoot.mapToGlobal(0, 0)
                var localX = gpos.x - Screen.virtualX
                var localY = gpos.y - Screen.virtualY
                // [ left, right, top, bottom ]
                var space = [localX, Screen.width - localX - root.width,
                    localY, Screen.height - localY - root.height]
                var restrict = [0, 0, 0, 0]
                // PreferredSide should be opposite of smallest side
                var sides = [Common.PreferredSide.Right, Common.PreferredSide.Left, Common.PreferredSide.Bottom, Common.PreferredSide.Top,]

                // Restrict the shorter sides to prevent overlapping the button
                /*if(space[0] < space[1])
                    restrict[0] = space[0] + root.width
                else
                    restrict[1] = space[1] + root.width
                if(space[2] < space[3])
                    restrict[2] = space[2] + root.height
                else
                    restrict[3] = space[3] + root.height*/

                // Get the min to determine preferred side
                var minIndex = 0
                var min = space[0]
                //console.log("space[ 0 ]: ", space[0])
                for(var i = 1; i < 4; i++) {
                    //console.log("space[", i, "]: ", space[i])
                    if(space[i] < min) {
                        min = space[i]
                        minIndex = i
                    }
                }
                // Add in the width or height to ensure we dont' overlap the button
                restrict[minIndex] = space[minIndex] + ((minIndex < 2) ? root.width : root.height)

                var menu = objectGenerator.createFloatingMenu(null, {
                    "modelCombiner": rootModelCombiner,
                    "previewMode": false,
                    "nesting": 0,
                    "launcher": executable,
                    "objectGenerator": objectGenerator,
                    "parentRect": {
                        x: gpos.x,
                        y: gpos.y,
                        width: compactRoot.width,
                        height: compactRoot.height
                    },
                    "restrictLeft": restrict[0],
                    "restrictRight": restrict[1],
                    "restrictTop": restrict[2],
                    "restrictBottom": restrict[3],
                    "preferredSide": sides[minIndex]
                })

                if(rootModelCombiner.isReady()) {
                    menu.visible = true
                } else {
                    var modelReadyHandler = function() {
                        rootModelCombiner.ready.disconnect(modelReadyHandler)
                        menu.visible = true
                    }
                    rootModelCombiner.ready.connect(modelReadyHandler)
                }

                currentRootMenu = menu


                // Clear the reference when the menu closes itself
                menu.visibleChanged.connect(function() {
                    if (!menu.visible) {
                        currentRootMenu = null
                    }
                })
            }
        }
    }

    fullRepresentation: Item {}

    ObjectGenerator {
        id: objectGenerator
        useCache: true
    }

    // Folder picker
    Platform.FolderDialog {
        id: folderDialog
        title: "Choose the main folder for quicklaunch shortcuts"
        currentFolder: (plasmoid.configuration.quicklaunchFolder === "")
            ? Platform.StandardPaths.writableLocation(Platform.StandardPaths.DocumentsLocation)
            : plasmoid.configuration.quicklaunchFolder

        onAccepted: {
            plasmoid.configuration.quicklaunchFolder = folder
            if (rootModelCombiner) {
                rootModelCombiner.folder = folder
            }
        }
    }

    P5Support.DataSource {
        id: executable

        property var pendingIconRequests: ({})   // cmd → [callback, callback, ...]
        property var iconCache: ({})             // desktopPath → iconName
        property int maxCacheSize: plasmoid.configuration.iconLineCacheSize || 200

        engine: "executable"
        connectedSources: []

        onNewData: function(sourceName, data) {
            var requests = pendingIconRequests[sourceName]
            if (requests) {
                var iconName = (data["stdout"] || "").trim()

                var match = sourceName.match(/--file\s+"([^"]+)"/)
                var desktopPath = match ? match[1] : null

                if (desktopPath && plasmoid.configuration.useIconCache) {
                    // Use the mtime from the first request (they should all be the same)
                    var mtime = requests[0].mtime
                    iconCache[desktopPath] = {
                        icon: iconName,
                        mtime: mtime
                    }

                    // size limiting...
                    var keys = Object.keys(iconCache)
                    if (keys.length > maxCacheSize) {
                        delete iconCache[keys[0]]
                    }
                }

                for (var i = 0; i < requests.length; i++) {
                    requests[i].callback(iconName)
                }

                delete pendingIconRequests[sourceName]
            }
            disconnectSource(sourceName)
        }

        function exec(cmd) {
            connectSource(cmd)
        }

        function requestIcon(desktopPath, mtime, callback) {
            if (!desktopPath || !desktopPath.endsWith(".desktop")) {
                callback("")
                return
            }

            // Cache hit + still valid?
            if (plasmoid.configuration.useIconCache && iconCache.hasOwnProperty(desktopPath)) {
                var entry = iconCache[desktopPath]
                if (entry.mtime === mtime) {
                    callback(entry.icon)
                    return
                }
                // mtime changed → fall through and refresh
            }

            var cmd = "kreadconfig5 --file \"" + desktopPath + "\" --group \"Desktop Entry\" --key Icon"

            if (pendingIconRequests.hasOwnProperty(cmd)) {
                pendingIconRequests[cmd].push({callback: callback, mtime: mtime})
                return
            }

            pendingIconRequests[cmd] = [{callback: callback, mtime: mtime}]
            connectSource(cmd)
        }
    }

    function action_changeFolder() {
        folderDialog.open()
    }
}
