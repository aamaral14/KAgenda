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
            
            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: statusText
                wrapMode: Text.WordWrap
                color: "#808080"
            }
            
            ListView {
                id: eventsList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: calendarModel
                spacing: 4
                
                delegate: Item {
                    width: eventsList.width
                    height: 60
                    Column {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: 4
                        spacing: 4
                        PlasmaComponents.Label {
                            text: model.title || ""
                            font.bold: true
                        }
                        PlasmaComponents.Label {
                            text: (model.date || "") + " " + (model.time || "")
                            color: "#808080"
                        }
                    }
                }
            }
            
            PlasmaComponents.Button {
                Layout.fillWidth: true
                text: "Refresh"
                onClicked: {
                    statusText = "Refresh clicked"
                }
            }
        }
    }
}

