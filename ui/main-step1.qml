import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root
    
    preferredRepresentation: fullRepresentation
    
    fullRepresentation: Item {
        width: 350
        height: 500
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            
            PlasmaComponents.Label {
                text: "Gmail Calendar"
                font.bold: true
            }
            
            PlasmaComponents.Label {
                text: "Step 1: Basic UI loaded"
            }
        }
    }
}

