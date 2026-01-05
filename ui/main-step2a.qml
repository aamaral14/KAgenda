import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root
    
    preferredRepresentation: fullRepresentation
    
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    
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
                text: "Step 2a: Testing backgroundHints only"
            }
        }
    }
}

