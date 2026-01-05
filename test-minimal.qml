import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

PlasmoidItem {
    preferredRepresentation: fullRepresentation
    
    fullRepresentation: Item {
        Layout.minimumWidth: 100
        Layout.minimumHeight: 100
        
        PlasmaCore.IconItem {
            anchors.centerIn: parent
            source: "view-calendar"
            width: 64
            height: 64
        }
    }
}

