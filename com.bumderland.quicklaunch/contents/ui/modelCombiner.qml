// Original author: piotr4@gmail.com
// License: GPLv3
//
// Plasma 6 port and update by Matt Galanto (with help from Grok)
// Based on: https://github.com/Risu/CoolPopupQuicklaunch

// modelCombiner.qml
import QtQuick
import Qt.labs.folderlistmodel
import org.kde.plasma.plasmoid

Item {
    id: root

    property url folder
    property bool foldersLast: plasmoid.configuration.foldersLast

    // The model that the rest of the code will use
    property alias model: combined
    property bool _readyEmitted: false

    signal ready()

    ListModel {
        id: combined
    }

    FolderListModel {
        id: dirModel
        folder: root.folder
        showDirs: true
        showFiles: false
        showDotAndDotDot: false
        nameFilters: ["*"]
    }

    FolderListModel {
        id: fileModel
        folder: root.folder
        showDirs: false
        showFiles: true
        showDotAndDotDot: false
        nameFilters: plasmoid.configuration.filesFilter.split(";").map(s => s.trim()).filter(s => s.length > 0)
    }

    function isReady() {
        return dirModel.status === FolderListModel.Ready &&
            fileModel.status === FolderListModel.Ready;
    }

    function rebuildIfReady() {
        if (isReady()) {
            rebuild()
        }
    }

    function rebuild() {
        combined.clear()

        /*console.log("rebuild:",
            "dirs =", dirModel.count,
            "files =", fileModel.count,
            "dirStatus =", dirModel.status,
            "fileStatus =", fileModel.status,
            "folder = ", folder)*/

        function appendFrom(folderModel) {
            for (var i = 0; i < folderModel.count; ++i) {
                combined.append({
                    fileName: folderModel.get(i, "fileName"),
                    filePath: folderModel.get(i, "filePath"),
                    fileIsDir: folderModel.get(i, "fileIsDir"),
                    fileModified: folderModel.get(i, "fileModified")
                })
            }
        }

        if (foldersLast) {
            appendFrom(fileModel)
            appendFrom(dirModel)
        } else {
            appendFrom(dirModel)
            appendFrom(fileModel)
        }

        if(!_readyEmitted) {
            _readyEmitted = true
            ready()
        }
    }

    Connections {
        target: dirModel
        function onStatusChanged() {
            // schedules the function to run on the next pass of the event loop.
            //  If several signals fire in the same event loop cycle, you only get one rebuild instead of many.
            Qt.callLater(root.rebuildIfReady)
        }
    }
    Connections {
        target: fileModel
        function onStatusChanged() {
            Qt.callLater(root.rebuildIfReady)
        }
    }

    onFoldersLastChanged: {
        _readyEmitted = false
        Qt.callLater(rebuildIfReady)
    }
    onFolderChanged: {
        _readyEmitted = false
        dirModel.folder = folder
        fileModel.folder = folder
    }

    Component.onCompleted: rebuildIfReady()
}
