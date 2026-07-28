// Original author: piotr4@gmail.com
// License: GPLv3
//
// Plasma 6 port and update by Matt Galanto (with help from Grok)
// Based on: https://github.com/Risu/CoolPopupQuicklaunch

// File name must start with a capital to be loaded in other files? Or something?
import QtQuick

QtObject {
    property bool useCache: true
    property var componentCache: ({})

    function createComponent(url) {
        var component = Qt.createComponent(Qt.resolvedUrl(url))
        if(component.status !== Component.Ready) {
            console.log("Error creating " + url + " Component: " + component.errorString())
            return null
        }
        //console.log("Component suceess: " + url)
        return component
    }

    function createObject(url, parent, properties) {
        var comp = null

        if(useCache)
        {
            // Create the component if necessary
            if(!componentCache.hasOwnProperty(url)) {
                comp = createComponent(url)
                if(comp === null) {
                    return null
                }
                componentCache[url] = comp
            }
            if(comp === null)
                comp = componentCache[url]
        }
        else {
            comp = createComponent(url)
            if(comp === null) {
                return null
            }
        }

        return comp.createObject(parent, properties)
    }

    function createFloatingMenu(parent, properties) {
        return createObject("floatingMenu.qml", parent, properties)
    }
    function createModelCombiner(parent, properties) {
        return createObject("modelCombiner.qml", parent, properties)
    }

}
