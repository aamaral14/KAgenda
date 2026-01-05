import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

Item {
    id: configModal
    anchors.fill: parent
    z: 999999
    visible: true
    
    property var plasmoidRef: null
    property var onClose: null
    property var rootRef: null
    
    Component.onCompleted: {
        console.log("ConfigModal Component.onCompleted")
    }
    
    // Semi-transparent background overlay
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.6
        visible: true
        
        MouseArea {
            anchors.fill: parent
            onClicked: {
                console.log("Background clicked, closing modal")
                if (onClose) onClose()
            }
        }
    }
    
    // Modal content
    Rectangle {
        id: modalContent
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.8, 500)
        height: Math.min(parent.height * 0.8, 350)
        radius: 8
        color: "#2b2b2b"
        border.color: "#555555"
        border.width: 1
        visible: true
        z: 999999
        clip: true
        
        // Match the main widget's background style
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#2b2b2b" }
            GradientStop { position: 1.0; color: "#1e1e1e" }
        }
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            anchors.topMargin: 15
            anchors.bottomMargin: 15
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 15
            clip: true
            
            // Title
            RowLayout {
                Layout.fillWidth: true
                
                PlasmaComponents.Label {
                    text: "Gmail Calendar Configuration"
                    font.bold: true
                    font.pointSize: 16
                    color: "#ffffff"
                }
                
                Item { Layout.fillWidth: true }
                
                // Close button
                Kirigami.Icon {
                    source: "window-close"
                    width: 20
                    height: 20
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (onClose) onClose()
                        }
                    }
                }
            }
            
            // Access Token field
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                
                PlasmaComponents.Label {
                    text: "Access Token:"
                    color: "#ffffff"
                }
                
                QQC2.TextField {
                    id: tokenField
                    Layout.fillWidth: true
                    placeholderText: "Paste access token here"
                    text: plasmoidRef ? (plasmoidRef.configuration.accessToken || "") : ""
                    background: Rectangle {
                        color: "#1e1e1e"
                        border.color: "#555555"
                        border.width: 1
                        radius: 4
                    }
                    color: "#ffffff"
                }
            }
            
            // Calendar ID field
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                
                PlasmaComponents.Label {
                    text: "Calendar ID:"
                    color: "#ffffff"
                }
                
                QQC2.TextField {
                    id: calendarIdField
                    Layout.fillWidth: true
                    placeholderText: "Enter calendar ID (e.g., primary)"
                    text: plasmoidRef ? (plasmoidRef.configuration.calendarId || "") : ""
                    background: Rectangle {
                        color: "#1e1e1e"
                        border.color: "#555555"
                        border.width: 1
                        radius: 4
                    }
                    color: "#ffffff"
                }
            }
            
            Item { 
                Layout.fillHeight: true
                Layout.minimumHeight: 0
            }
            
            // Buttons - fixed at bottom
            RowLayout {
                Layout.fillWidth: true
                Layout.maximumHeight: 40
                Layout.minimumHeight: 40
                spacing: 10
                
                PlasmaComponents.Button {
                    text: "Cancel"
                    Layout.preferredWidth: 80
                    onClicked: {
                        if (onClose) onClose()
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                PlasmaComponents.Button {
                    text: "Save"
                    Layout.preferredWidth: 80
                    onClicked: {
                        if (plasmoidRef && plasmoidRef.configuration) {
                            // Save configuration
                            plasmoidRef.configuration.accessToken = tokenField.text
                            plasmoidRef.configuration.calendarId = calendarIdField.text
                            
                            // Trigger refresh in parent
                            if (rootRef && typeof rootRef.refreshEvents === 'function') {
                                rootRef.refreshEvents()
                            }
                            
                            // Close modal
                            if (onClose) onClose()
                        }
                    }
                }
            }
        }
    }
}

