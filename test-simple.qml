import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

PlasmoidItem {
    preferredRepresentation: fullRepresentation
    
    fullRepresentation: Item {
        width: 100
        height: 100
        
        PlasmaCore.IconItem {
            anchors.centerIn: parent
            source: "view-calendar"
            width: 64
            height: 64
        }
    }
}


