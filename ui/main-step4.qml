import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root
    
    preferredRepresentation: fullRepresentation
    
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    
    property string statusText: ""
    property var calendarModel: ListModel { id: calendarModel }
    property string accessToken: ""
    property string calendarId: ""
    
    fullRepresentation: Item {
        width: 350
        height: 500
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            
            RowLayout {
                Layout.fillWidth: true
                
                PlasmaComponents.Label {
                    text: "Gmail Calendar"
                    font.bold: true
                }
                
                Item { Layout.fillWidth: true }
                
                PlasmaComponents.ToolButton {
                    iconSource: "configure"
                    onClicked: Plasmoid.action("configure").trigger()
                }
            }
            
            PlasmaComponents.Label {
                Layout.fillWidth: true
                visible: statusText !== ""
                text: statusText
                wrapMode: Text.WordWrap
                color: "#808080"
            }
            
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                ListView {
                    id: eventsList
                    model: calendarModel
                    spacing: 4
                    
                    delegate: Item {
                        width: eventsList.width
                        height: 40
                        PlasmaComponents.Label {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: model.title || "Test Event"
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
            
            PlasmaComponents.Label {
                text: "Step 4: Added ListView and ScrollView"
            }
        }
    }
    
    Component.onCompleted: {
        statusText = "Widget initialized"
    }
}

