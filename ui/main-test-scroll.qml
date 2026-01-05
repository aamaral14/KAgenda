import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root
    
    preferredRepresentation: fullRepresentation
    
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    
    property string statusText: "Ready"
    
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
            
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                PlasmaComponents.Label {
                    text: "Testing ScrollView"
                }
            }
            
            PlasmaComponents.Button {
                Layout.fillWidth: true
                text: "Refresh"
            }
        }
    }
}

