import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root
    
    preferredRepresentation: fullRepresentation
    
    fullRepresentation: Item {
        Layout.minimumWidth: 200
        Layout.minimumHeight: 200
        
        PlasmaCore.IconItem {
            anchors.centerIn: parent
            source: "view-calendar"
            width: 64
            height: 64
        }
    }
}


