// Original author: piotr4@gmail.com
// License: GPLv3
//
// Plasma 6 port and update by Matt Galanto (with help from Grok)
// Based on: https://github.com/Risu/CoolPopupQuicklaunch

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.platform as Platform
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

Item {
    id: root

    // Normal cfg_ properties
    property alias cfg_iconType: iconTypeCombo.currentIndex
    property alias cfg_slimIcon: slimIconCheck.checked
    property alias cfg_filesFilter: filesFilterText.text
    property alias cfg_foldersLast: foldersLastCheck.checked
    property alias cfg_minMenuWidth: minMenuWidthSpin.value
    property alias cfg_scrollSpeed: scrollSpeedSpin.value
    property alias cfg_scrollTime: scrollTimeSpin.value
    property alias cfg_useGenericIcons: useGenericIconsCheck.checked
    property alias cfg_useIconCache: useIconCacheCheck.checked
    property alias cfg_iconLineCacheSize: iconLineCacheSizeSpin.value
    property alias cfg_useThemeDefaultColor: useThemeDefaultColorCheck.checked
    property alias cfg_useThemeHighlightColor: useThemeHighlightColorCheck.checked
    property alias cfg_useThemeBackgroundColor: useThemeBackgroundColorCheck.checked
    property alias cfg_useThemeBorderColor: useThemeBorderColorCheck.checked
    property alias cfg_useThemeHoverColor: useThemeHoverColorCheck.checked

    property string cfg_itemDefaultColor
    property string cfg_itemHighlightedColor
    property string cfg_menuBackgroundColor
    property string cfg_menuBorderColor
    property string cfg_itemHoverColor

    property string cfg_quicklaunchFolder
    property string cfg_genericFileIcon
    property string cfg_genericFolderIcon

    // Dummy Default properties to silence the warnings
    property var cfg_iconTypeDefault
    property var cfg_slimIconDefault
    property var cfg_filesFilterDefault
    property var cfg_foldersLastDefault
    property var cfg_minMenuWidthDefault
    property var cfg_scrollSpeedDefault
    property var cfg_scrollTimeDefault
    property var cfg_useGenericIconsDefault
    property var cfg_useIconCacheDefault
    property var cfg_iconLineCacheSizeDefault
    property var cfg_useThemeDefaultColorDefault
    property var cfg_useThemeHighlightColorDefault
    property var cfg_itemDefaultColorDefault
    property var cfg_itemHighlightedColorDefault
    property string cfg_menuBackgroundColorDefault
    property string cfg_menuBorderColorDefault
    property string cfg_itemHoverColorDefault
    property var cfg_useThemeBackgroundColorDefault
    property var cfg_useThemeBorderColorDefault
    property var cfg_useThemeHoverColorDefault
    property var cfg_quicklaunchFolderDefault
    property string cfg_genericFileIconDefault
    property string cfg_genericFolderIconDefault


    // also silence the "title" complaint
    property string title

    property string demoFolder: Qt.resolvedUrl("demo").toString().replace("file://", "")
    property var previewMenu: null

    ScrollView {
        id: scroll
        anchors.fill: parent
        contentWidth: availableWidth
        Kirigami.FormLayout {
            anchors.left: parent.left
            anchors.right: parent.right

            ComboBox {
                id: iconTypeCombo
                Kirigami.FormData.label: "Panel icon:"
                model: ["Arrow (auto)", "White custom", "Black custom"]
            }

            CheckBox {
                id: slimIconCheck
                text: "Slim panel icon"
            }

            TextField {
                id: filesFilterText
                Kirigami.FormData.label: "Filter for shown files (*.desktop;*.etc):"
                /*color: acceptableInput ? Kirigami.Theme.textColor
                           : Kirigami.Theme.negativeTextColor
                validator: RegularExpressionValidator {
                    regularExpression: /[^\/]*/
                //}
                property bool isValid: !text.includes("/")   // or your full check

                onIsValidChanged: {
                    if (!isValid) {
                        text = text.replace("/", "")
                        filesFilterError.visible = true
                        filesFilterTimer.restart()
                    }
                }
            }
            Label {
                id: filesFilterError
                visible: false
                text: "The filter does not work on paths, so / will match no files."
                color: Kirigami.Theme.neutralTextColor
                font.pointSize: Kirigami.Theme.smallFont.pointSize
            }
            Timer {
                id: filesFilterTimer
                interval: 3000          // show for 3 seconds
                onTriggered: filesFilterError.visible = false
            }

            CheckBox {
                id: foldersLastCheck
                Kirigami.FormData.label: "Folders:"
                text: "Show folders at the bottom"
            }

            SpinBox {
                id: minMenuWidthSpin
                Kirigami.FormData.label: "Minimum menu width:"
                from: 120
                to: 600
                stepSize: 10
            }

            RowLayout {
                Kirigami.FormData.label: "When scrolling, scroll"

                SpinBox {
                    id: scrollSpeedSpin
                    from: 1
                    to: 500
                    stepSize: 1
                }
                Label {
                    text: "pixels every"
                }
                SpinBox {
                    id: scrollTimeSpin
                    Kirigami.FormData.label: " pixels every "
                    from: 5
                    to: 5000
                    stepSize: 5
                }
                Label {
                    text: "milliseconds"
                }
            }

            CheckBox {
                id: useGenericIconsCheck
                Kirigami.FormData.label: "Menu icons:"
                text: "Use generic icons only (faster)"
            }

            CheckBox {
                id: useIconCacheCheck
                Kirigami.FormData.label: ""
                enabled: !useGenericIconsCheck.checked
                text: "Cache icons"
            }

            SpinBox {
                id: iconLineCacheSizeSpin
                Kirigami.FormData.label: "Icon lines cache size:"
                from: 50
                to: 1000
                stepSize: 50
                enabled: !useGenericIconsCheck.checked && useIconCacheCheck.checked
                visible: false
            }

            // ============================================================
            // Color settings + live preview
            // ============================================================

            // Helper that resolves a colour (theme or custom)
            function resolveColor(useTheme, customColor, themeColor) {
                return useTheme ? themeColor : (customColor || themeColor)
            }

            // ----- Preview -----
            /*Kirigami.Separator {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: "Preview"
            }

            Button {
                id: previewButton
                text: previewMenu ? "Close Preview" : "Show Preview"

                onClicked: {
                    if (previewMenu) {
                        previewMenu.closeAll()
                        previewMenu.destroy()
                        previewMenu = null
                        return
                    }

                    var component = Qt.createComponent(Qt.resolvedUrl("floatingMenu.qml"))
                    if (component.status === Component.Ready) {
                        var modelComp = Qt.createComponent(Qt.resolvedUrl("folderModel.qml"))
                        var demoModel = modelComp.createObject(null, {
                            "folder": demoFolder
                        })

                        previewMenu = component.createObject(null, {
                            "previewMode": true,
                            "folderModel": demoModel,
                            "nesting": 0
                        })

                        // Position just to the right of the button
                        var pos = previewButton.mapToGlobal(previewButton.width + 8, 0)
                        previewMenu.x = pos.x
                        previewMenu.y = pos.y
                        previewMenu.visible = true
                    }
                }
            }*/

            // ----- Color controls -----
            Kirigami.Separator {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: "Colors"
            }

            // Background
            CheckBox {
                id: useThemeBackgroundColorCheck
                Kirigami.FormData.label: "Menu background:"
                text: "Use theme default"
            }
            RowLayout {
                enabled: !useThemeBackgroundColorCheck.checked
                Button { text: "Choose…"; onClicked: bgColorDialog.open() }
                Rectangle {
                    width: 36; height: 24; radius: 3
                    color: cfg_menuBackgroundColor || Kirigami.Theme.backgroundColor
                    border.color: Kirigami.Theme.disabledTextColor
                }
            }

            // Border
            CheckBox {
                id: useThemeBorderColorCheck
                Kirigami.FormData.label: "Menu border:"
                text: "Use theme default"
            }
            RowLayout {
                enabled: !useThemeBorderColorCheck.checked
                Button { text: "Choose…"; onClicked: borderColorDialog.open() }
                Rectangle {
                    width: 36; height: 24; radius: 3
                    color: cfg_menuBorderColor || Kirigami.Theme.alternateBackgroundColor
                    border.color: Kirigami.Theme.disabledTextColor
                }
            }

            // Hover
            CheckBox {
                id: useThemeHoverColorCheck
                Kirigami.FormData.label: "Item hover:"
                text: "Use theme default"
            }
            RowLayout {
                enabled: !useThemeHoverColorCheck.checked
                Button { text: "Choose…"; onClicked: hoverColorDialog.open() }
                Rectangle {
                    width: 36; height: 24; radius: 3
                    color: cfg_itemHoverColor || Kirigami.Theme.highlightColor
                    border.color: Kirigami.Theme.disabledTextColor
                }
            }

            // Default text
            CheckBox {
                id: useThemeDefaultColorCheck
                Kirigami.FormData.label: "Default text:"
                text: "Use theme default"
            }
            RowLayout {
                enabled: !useThemeDefaultColorCheck.checked
                Button { text: "Choose…"; onClicked: defaultColorDialog.open() }
                Rectangle {
                    width: 36; height: 24; radius: 3
                    color: cfg_itemDefaultColor || Kirigami.Theme.textColor
                    border.color: Kirigami.Theme.disabledTextColor
                }
            }

            // Highlighted text
            CheckBox {
                id: useThemeHighlightColorCheck
                Kirigami.FormData.label: "Highlighted text:"
                text: "Use theme default"
            }
            RowLayout {
                enabled: !useThemeHighlightColorCheck.checked
                Button { text: "Choose…"; onClicked: highlightColorDialog.open() }
                Rectangle {
                    width: 36; height: 24; radius: 3
                    color: cfg_itemHighlightedColor || Kirigami.Theme.highlightedTextColor
                    border.color: Kirigami.Theme.disabledTextColor
                }
            }

            // Color dialogs
            Platform.ColorDialog {
                id: bgColorDialog
                title: "Menu background"
                color: cfg_menuBackgroundColor || Kirigami.Theme.backgroundColor
                onAccepted: cfg_menuBackgroundColor = color
            }
            Platform.ColorDialog {
                id: borderColorDialog
                title: "Menu border"
                color: cfg_menuBorderColor || Kirigami.Theme.alternateBackgroundColor
                onAccepted: cfg_menuBorderColor = color
            }
            Platform.ColorDialog {
                id: hoverColorDialog
                title: "Item hover"
                color: cfg_itemHoverColor || Kirigami.Theme.highlightColor
                onAccepted: cfg_itemHoverColor = color
            }
            Platform.ColorDialog {
                id: defaultColorDialog
                title: "Default text"
                color: cfg_itemDefaultColor || Kirigami.Theme.textColor
                onAccepted: cfg_itemDefaultColor = color
            }
            Platform.ColorDialog {
                id: highlightColorDialog
                title: "Highlighted text"
                color: cfg_itemHighlightedColor || Kirigami.Theme.highlightedTextColor
                onAccepted: cfg_itemHighlightedColor = color
            }
        }
    }
}
