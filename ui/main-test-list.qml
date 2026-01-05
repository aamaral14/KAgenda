import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root
    
    preferredRepresentation: fullRepresentation
    
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    
    property var calendarModel: ListModel { id: calendarModel }
    
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
            
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: calendarModel
                spacing: 4
                
                delegate: PlasmaComponents.Label {
                    text: model.title || "Test"
                }
            }
            
            PlasmaComponents.Button {
                Layout.fillWidth: true
                text: "Refresh"
            }
        }
    }
}

