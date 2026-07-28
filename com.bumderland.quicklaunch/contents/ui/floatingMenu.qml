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
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support



PlasmaCore.Dialog {
    id: floatingMenu

    property var modelCombiner
    property int nesting: 0
    property var parentMenu: null
    property var childMenu: null
    property var launcher: null
    property var objectGenerator: null
    property bool previewMode: false
    // Properties set by the creator
    property var parentRect: null          // { x, y, width, height } in global coords
    property int preferredSide: Common.PreferredSide.Right
    // Use these values to prevent the widget from using that many pixels along each edge of he Screen
    property int restrictLeft: 0
    property int restrictRight: 0
    property int restrictTop: 0
    property int restrictBottom: 0

    property var maxWidth: Screen.width - restrictLeft - restrictRight - 8
    property var minWidth: plasmoid.configuration.minMenuWidth
    property var maxHeight: Screen.height - restrictTop - restrictBottom - 8
    property var minHeight: 42

    type: PlasmaCore.Dialog.PopupMenu
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    backgroundHints: PlasmaCore.Types.NoBackground
    color: "transparent"
    visible: false

    hideOnWindowDeactivate: false

    width: content.width
    height: content.height


    // Reposition whenever our own size changes or the parent rect changes
    //onWidthChanged: Qt.callLater(reposition)
    //onHeightChanged: Qt.callLater(reposition)
    //onParentRectChanged: Qt.callLater(reposition, 0, 0)
    //onPreferredSideChanged: Qt.callLater(reposition, 0, 0)

    // -------------------------------------------------------
    // Content
    // -------------------------------------------------------
    mainItem: Rectangle {
        id: content
        color: menuColor(plasmoid.configuration.useThemeBackgroundColor,
                 plasmoid.configuration.menuBackgroundColor,
                 Kirigami.Theme.backgroundColor)

        border.color: menuColor(plasmoid.configuration.useThemeBorderColor,
                                plasmoid.configuration.menuBorderColor,
                                Kirigami.Theme.alternateBackgroundColor)
        radius: 8
        border.width: 1
        width: scroll.width
        height: scroll.height

        onHeightChanged: {
            Qt.callLater(floatingMenu.reposition, 0, 0)
        }


        ScrollView {
            id: scroll
            clip: true

            width: floatingMenu.fixWidth(view.width + scroll.effectiveScrollBarWidth)
            height: floatingMenu.fixHeight(view.height)
            //implicitWidth:  view.implicitWidth
            //implicitHeight: view.implicitHeight

            // Hide the native scrollbars
            ScrollBar.vertical.policy: ScrollBar.AlwaysOff
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            Column {
                id: view
                //spacing: 20
                //topPadding: 8
                //bottomPadding: 8

                width: implicitWidth
                height: implicitHeight

                /*onImplicitHeightChanged: function() {
                    //floatingMenu.visible = true
                    console.log("onHeight(",height,")Changed: ", floatingMenu.modelCombiner.model.count, "?", repeater.count, " -> ",
                                floatingMenu.modelCombiner.isReady(), " && ", repeater.itemAt(floatingMenu.modelCombiner.model.count - 1))
                    if (floatingMenu.modelCombiner.isReady()
                        && repeater.itemAt(floatingMenu.modelCombiner.model.count - 1) !==  null) {
                        console.log("Last repeater item")
                        floatingMenu.reposition(0, 0)
                        floatingMenu.visible = true
                    }
                }*/

                Repeater {
                    id: repeater
                    model: floatingMenu.modelCombiner.model

                    onItemAdded: function(index, item) {
                        if (index === model.count - 1) {
                            // Last delegate has been created
                            //floatingMenu.visible = true
                            //floatingMenu.reposition(0, 0)
                            //Qt.callLater(floatingMenu.reposition, 0, 0)

                            // Let's get an approximate size maybe
                            var widthGuess = item.width
                            var heightGuess = item.height
                            for(var i = 0; i < index; i++) {
                                var checkItem = repeater.itemAt(i)
                                if(checkItem !== null) {
                                    if(widthGuess < checkItem.width) widthGuess = checkItem.width
                                    heightGuess += checkItem.height
                                }
                            }

                            // Clamp the sizes if need be
                            widthGuess = floatingMenu.fixWidth(widthGuess)
                            heightGuess = floatingMenu.fixHeight(heightGuess)

                            // Make all rows the same width
                            for(var i = 0; i <= index; i++) {
                                var checkItem = repeater.itemAt(i)
                                if(checkItem !== null) {
                                    checkItem.rowLayout.width = widthGuess
                                }
                            }

                            //console.log("onItemAdded: ", index + 1, "==?", model.count, ",", heightGuess)

                            // Height * item count
                            floatingMenu.reposition(widthGuess, heightGuess)
                            floatingMenu.visible = true
                        }
                    }

                    Item {
                        id: delegateRoot

                        required property string fileName
                        required property string filePath
                        required property bool fileIsDir
                        required property var fileModified
                        readonly property bool isFolder: fileIsDir

                        // Expose the RowLayout
                        property alias rowLayout: row

                        width: row.width
                        height: row.height

                        Rectangle {
                            width: view.width - 2
                            height: parent.height - 2
                            radius: 5
                            color: mouseArea.containsMouse
                                ? menuColor(plasmoid.configuration.useThemeHoverColor,
                                            plasmoid.configuration.itemHoverColor,
                                            Kirigami.Theme.highlightColor)
                                : "transparent"
                        }

                        RowLayout {
                            id: row

                            //width: implicitWidth
                            //height: implicitHeight
                            spacing: 10

                            /*Component.onCompleted: {
                                console.log(floatingMenu.visible,"-Icon height:", itemIcon.height,
                                            "Label height:", itemLabel.height,
                                            "Row height:", row.height)
                            }*/

                            Item {
                                id: itemIconContainer
                                Layout.preferredWidth: 22
                                Layout.preferredHeight: 22
                                Layout.leftMargin: 10
                                Layout.topMargin: 10
                                Layout.bottomMargin: 10

                                Component.onCompleted: {
                                    if (isFolder || plasmoid.configuration.useGenericIcons) {
                                        itemIcon.source = isFolder ? plasmoid.configuration.genericFolderIcon : plasmoid.configuration.genericFileIcon
                                        return
                                    }

                                    if (!fileName.endsWith(".desktop")) {
                                        // Non-desktop file – just try the path
                                        itemIcon.source = itemIcon.fallback
                                        //itemImageIcon.source = filePath.startsWith("file://") ? filePath : "file://" + filePath
                                        return
                                    }

                                    // Desktop file – ask for the real Icon= value
                                    if (!(launcher && launcher.requestIcon)) {
                                        source = plasmoid.configuration.genericFileIcon
                                        return
                                    }

                                    var mtime = fileModified ? fileModified.getTime() : 0

                                    launcher.requestIcon(filePath, mtime, function(iconName) {
                                        if (!itemIcon) return
                                        if (iconName === "") {
                                            itemIcon.source = itemIcon.fallback
                                            return
                                        }

                                        // Absolute path? Use the image instead
                                        if (iconName.indexOf("/") !== -1) {
                                            itemIcon.source = itemIcon.fallback
                                            itemImageIcon.source = iconName.startsWith("file://") ? iconName : "file://" + iconName
                                        } else {
                                            // Normal icon name
                                            itemIcon.source = iconName
                                        }
                                    })
                                }

                                Kirigami.Icon {
                                    id: itemIcon
                                    anchors.fill: parent
                                    visible: itemImageIcon.status !== Image.Ready
                                    /*Layout.preferredWidth: 22
                                    Layout.preferredHeight: 22
                                    Layout.leftMargin: 10
                                    Layout.topMargin: 10
                                    Layout.bottomMargin: 10*/
                                    fallback: plasmoid.configuration.genericFileIcon
                                    // Recolor symbolic icons to match the text
                                    color: mouseArea.containsMouse
                                        ? menuColor(plasmoid.configuration.useThemeHighlightColor,
                                                    plasmoid.configuration.itemHighlightedColor,
                                                    Kirigami.Theme.highlightedTextColor)
                                        : menuColor(plasmoid.configuration.useThemeDefaultColor,
                                                    plasmoid.configuration.itemDefaultColor,
                                                    Kirigami.Theme.textColor)




                                }

                                // Hidden probe used only for absolute paths
                                Image {
                                    id: itemImageIcon
                                    anchors.fill: parent
                                    visible: status === Image.Ready
                                    asynchronous: true
                                    cache: plasmoid.configuration.useIconCache
                                    fillMode: Image.PreserveAspectFit
                                    sourceSize.width: 22
                                    sourceSize.height: 22

                                    /*onStatusChanged: {
                                        if (status !== Image.Ready) {
                                            itemIcon.source = itemIcon.fallback     // path failed
                                        }
                                    }*/
                                }
                            }

                            Label {
                                id: itemLabel
                                text: fileName.replace(/\.[^/.]+$/, "")
                                Layout.fillWidth: true
                                Layout.rightMargin: isFolder ? 0 : 10
                                Layout.topMargin: 10
                                Layout.bottomMargin: 10
                                elide: Text.ElideRight
                                color: mouseArea.containsMouse
                                    ? menuColor(plasmoid.configuration.useThemeHighlightColor,
                                                plasmoid.configuration.itemHighlightedColor,
                                                Kirigami.Theme.highlightedTextColor)
                                    : menuColor(plasmoid.configuration.useThemeDefaultColor,
                                                plasmoid.configuration.itemDefaultColor,
                                                Kirigami.Theme.textColor)
                            }

                            Kirigami.Icon {
                                id: itemFolderIcon
                                visible: isFolder
                                source: "arrow-right"
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16
                                opacity: 0.7
                                Layout.rightMargin: 10
                                Layout.topMargin: 10
                                Layout.bottomMargin: 10
                            }
                        }

                        MouseArea {
                            id: mouseArea
                            width: view.width - 2
                            height: parent.height - 2
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton

                            onEntered: {
                                if (isFolder) {
                                    openSubmenu()
                                }
                            }

                            onExited: {
                                // Optional: delay closing so the user can move into the submenu
                                // For now we leave submenus open until another one is opened or the parent closes
                            }

                            onClicked: function(mouse) {
                                //primary button
                                if(mouse.button === Qt.LeftButton) {
                                    if (isFolder) {
                                        openSubmenu()
                                    } else if(!previewMode) {
                                        // Call the DataSource that lives on the main plasmoid
                                        //console.log("typeof launcher = " + (typeof launcher));
                                        if (launcher) {
                                            //console.log("Executing kioclient exec \"" + filePath + "\"");
                                            launcher.exec("kioclient exec \"" + filePath + "\"")
                                        } else {
                                            // fallback
                                            //console.log("Opening URL \"file://" + filePath + "\"");
                                            Qt.openUrlExternally("file://" + filePath)
                                        }
                                        floatingMenu.closeAll()
                                    }
                                } else /*if(mouse.button === Qt.RightButton)*/ {
                                    console.log("right-click")
                                    floatingMenu.reposition(0, 0)
                                }
                            }
                        }

                        function openSubmenu() {
                            if (floatingMenu.childMenu) {
                                floatingMenu.childMenu.destroy()
                                floatingMenu.childMenu = null
                            }

                            var subModelCombiner = objectGenerator.createModelCombiner(null, {
                                "folder": "file://" + filePath
                            })
                            if(subModelCombiner === null)
                                return

                            var gpos = delegateRoot.mapToGlobal(0, 0)
                            var submenu = objectGenerator.createFloatingMenu(null, {
                                "modelCombiner": subModelCombiner,
                                "previewMode": floatingMenu.previewMode,
                                "nesting": floatingMenu.nesting + 1,
                                "parentMenu": floatingMenu,
                                "launcher": floatingMenu.launcher,      // ← pass it on
                                "objectGenerator": objectGenerator,
                                "parentRect": {
                                    x: gpos.x,
                                    y: gpos.y,
                                    width: floatingMenu.width,
                                    height: floatingMenu.height
                                },
                                "restrictLeft": floatingMenu.restrictLeft,
                                "restrictRight": floatingMenu.restrictRight,
                                "restrictTop": floatingMenu.restrictTop,
                                "restrictBottom": floatingMenu.restrictBottom,
                                "preferredSide": Common.PreferredSide.Right
                            })

                            floatingMenu.childMenu = submenu
                        }
                    }
                }
            }
        }

        // Floating buttons – they do not affect ScrollView sizing
        ToolButton {
            anchors.horizontalCenter: scroll.horizontalCenter
            anchors.top: scroll.top
            anchors.topMargin: 4
            visible: scroll.contentItem.contentY > 0
            icon.name: "go-up"

            hoverEnabled: true

            onHoveredChanged: {
                if (hovered) upTimer.start()
                else upTimer.stop()
            }

            Timer {
                id: upTimer
                interval: plasmoid.configuration.scrollTime
                repeat: true
                running: false
                onTriggered: {
                    scroll.contentItem.contentY = Math.max(0, scroll.contentItem.contentY - plasmoid.configuration.scrollSpeed)
                    if (scroll.contentItem.contentY <= 0)
                        stop()
                }
            }
        }

        ToolButton {
            anchors.horizontalCenter: scroll.horizontalCenter
            anchors.bottom: scroll.bottom
            anchors.bottomMargin: 4
            visible: scroll.contentItem.contentY < scroll.contentItem.contentHeight - scroll.height
            icon.name: "go-down"

            hoverEnabled: true

            onHoveredChanged: {
                if (hovered) downTimer.start()
                else downTimer.stop()
            }

            Timer {
                id: downTimer
                interval: plasmoid.configuration.scrollTime
                repeat: true
                running: false
                onTriggered: {
                    var maxY = scroll.contentItem.contentHeight - scroll.height
                    scroll.contentItem.contentY = Math.min(maxY, scroll.contentItem.contentY + plasmoid.configuration.scrollSpeed)
                    if (scroll.contentItem.contentY >= maxY)
                        stop()
                }
            }
        }

        Timer {
            id: closeTimer
            interval: 180
            onTriggered: {
                // Walk up to the root and close the whole chain
                // only if nothing in the chain is active
                var rootMenu = floatingMenu
                while (rootMenu.parentMenu) {
                    rootMenu = rootMenu.parentMenu
                }

                // If the root is still not active and has no focused descendants, close
                if (!rootMenu.active) {
                    rootMenu.closeAll()
                }
            }
        }

        Connections {
            target: modelCombiner
            function onReady() {
                //console.log("onReady(): ",modelCombiner.model.count)
                // We need to handle the case of an empty model (Repeater.onItemAdded is not run then)
                if(modelCombiner.model.count === 0) {
                    reposition(fixWidth(0), fixHeight(0))
                    floatingMenu.visible = true
                }
            }
        }
    }

    onVisibleChanged: {
        if (!visible && childMenu) {
            childMenu.destroy()
            childMenu = null
        }
        if (!visible && parentMenu === null) {
            // This is the root menu closing – clear the reference in main.qml if possible
        }
    }

    onActiveChanged: {
        if (!active) {
            // Only start the close timer if we have no open child
            if (!childMenu) {
                closeTimer.restart()
            }
        } else {
            closeTimer.stop()
        }
    }

    Component.onDestruction: {
        if (childMenu) {
            childMenu.destroy()
            childMenu = null
        }
    }

    // Returns w/h or clamps it to the min or max size of the Dialog
    function fixWidth(w) {
        w = Math.max(floatingMenu.minWidth, w)
        return Math.min(floatingMenu.maxWidth , w)
    }
     function fixHeight(h) {
        h = Math.max(floatingMenu.minHeight, h)
        return Math.min(floatingMenu.maxHeight, h)
    }

    // set useWidth and useHeight to 0 to use the actual menu height and width
    function reposition(useWidth, useHeight) {
        //console.log("reposition()")
        if (!parentRect) return
        if (width < 10 || height < 10) return   // not ready yet

        //console.log("reposition() is run: ", useHeight, ",", height, ",", content.height, ",", scroll.height)

        // First, we need to move the menu to the correct Screen, so that Screen values make sense
        x = parentRect.x
        y = parentRect.y

        var margin = 0
        var mw = (useWidth !== 0) ? useWidth : width
        var mh = (useHeight !== 0) ? useHeight : height

        var screenX = Screen.virtualX + restrictLeft
        var screenY = Screen.virtualY + restrictTop
        var screenW = Screen.width - restrictLeft - restrictRight
        var screenH = Screen.height - restrictTop - restrictBottom

        var nx = 0
        var ny = 0

        switch (preferredSide) {
        case Common.PreferredSide.Right:
            nx = parentRect.x + parentRect.width + margin
            ny = parentRect.y
            if (nx + mw > screenX + screenW - 4)
                nx = parentRect.x - mw - margin     // flip side
            break
        case Common.PreferredSide.Left:
            nx = parentRect.x - mw - margin
            ny = parentRect.y
            if (nx < screenX + 4)
                nx = parentRect.x + parentRect.width + margin     // flip side
            break
        case Common.PreferredSide.Top:
            nx = parentRect.x
            ny = parentRect.y - mh - margin
            if (ny < screenY + 4)
                ny = parentRect.y + parentRect.height + margin     // flip side
            break
        case Common.PreferredSide.Bottom:
            nx = parentRect.x
            ny = parentRect.y + parentRect.height + margin     // flip side
            if (ny + mh > screenY + screenH - 4)
                ny = parentRect.y - mh - margin
            break
        }

        //console.log("screen = " + screenX + "," + screenY + "," + screenW + "," + screenH)
        //console.log("nx = Math.max(" +(screenX + 4)+", Math.min(" + nx + "," + (screenX + screenW - mw - 4) +"))")

        // Final clamp
        nx = Math.max(screenX + 4, Math.min(nx, screenX + screenW - mw - 4))
        ny = Math.max(screenY + 4, Math.min(ny, screenY + screenH - mh - 4))

        //console.log("box: " + parentRect.x + "," + parentRect.y + "," + parentRect.width + "," + parentRect.height)
        //console.log("menu: " + nx + "," + ny + "," + mw + "," + mh)

        x = nx
        y = ny
    }

    // For colors
    function menuColor(useTheme, custom, themeColor) {
        if (useTheme) return themeColor
        return (custom && custom !== "") ? custom : themeColor
    }

    // Run up the parent chain to the root and then start destroying things
    function closeAll() {
        // Find the top-most parent and go from there
        var top = floatingMenu
        while (top.parentMenu) {
            top = top.parentMenu
        }

        top.closeChildren()
        Qt.callLater(top.destroy)
    }

    function closeChildren() {
        if (childMenu) {
            childMenu.closeChildren()
            // Only destroy the modelCombiner for children since the root gets its passed rather than created
            childMenu.modelCombiner.destroy()
            childMenu.destroy()
            childMenu = null
        }
    }
}
