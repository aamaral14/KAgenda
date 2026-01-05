import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents

Rectangle {
    id: eventItem
    
    property string eventTitle: ""
    property string eventDate: ""
    property string eventTime: ""
    property string eventLocation: ""
    
    height: contentColumn.height + PlasmaCore.Units.smallSpacing * 2
    color: PlasmaCore.Theme.backgroundColor
    border.color: PlasmaCore.Theme.separatorColor
    border.width: 1
    radius: 4
    
    ColumnLayout {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: PlasmaCore.Units.smallSpacing
        
        PlasmaComponents.Label {
            Layout.fillWidth: true
            text: eventTitle
            font.bold: true
            wrapMode: Text.WordWrap
        }
        
        RowLayout {
            Layout.fillWidth: true
            
            PlasmaCore.IconItem {
                source: "view-calendar-day"
                width: PlasmaCore.Units.iconSizes.small
                height: width
            }
            
            PlasmaComponents.Label {
                text: eventDate
                color: PlasmaCore.Theme.neutralTextColor
            }
        }
        
        RowLayout {
            Layout.fillWidth: true
            visible: eventTime !== ""
            
            PlasmaCore.IconItem {
                source: "clock"
                width: PlasmaCore.Units.iconSizes.small
                height: width
            }
            
            PlasmaComponents.Label {
                text: eventTime
                color: PlasmaCore.Theme.neutralTextColor
            }
        }
        
        RowLayout {
            Layout.fillWidth: true
            visible: eventLocation !== ""
            
            PlasmaCore.IconItem {
                source: "location"
                width: PlasmaCore.Units.iconSizes.small
                height: width
            }
            
            PlasmaComponents.Label {
                text: eventLocation
                color: PlasmaCore.Theme.neutralTextColor
                elide: Text.ElideRight
            }
        }
    }
}

