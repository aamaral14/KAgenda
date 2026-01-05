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
    
    function loadConfig() {
        var configPath = "file:///home/alex/.config/gmail-calendar-widget/config.json"
        var request = new XMLHttpRequest()
        request.open("GET", configPath, false)
        request.send()
        
        if (request.status === 200) {
            var config = JSON.parse(request.responseText)
            calendarId = config.calendar_id || ""
            accessToken = config.access_token || ""
        }
    }
    
    function refreshEvents() {
        if (!calendarId || !accessToken) {
            statusText = "Please configure the widget"
            return
        }
        
        statusText = "Loading events..."
        
        var now = new Date()
        var later = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000)
        var timeMin = now.toISOString()
        var timeMax = later.toISOString()
        
        var url = "https://www.googleapis.com/calendar/v3/calendars/" + 
                  encodeURIComponent(calendarId) + 
                  "/events?timeMin=" + encodeURIComponent(timeMin) + 
                  "&timeMax=" + encodeURIComponent(timeMax) + 
                  "&maxResults=50&singleEvents=true&orderBy=startTime"
        
        var request = new XMLHttpRequest()
        request.open("GET", url)
        request.setRequestHeader("Authorization", "Bearer " + accessToken)
        
        request.onreadystatechange = function() {
            if (request.readyState === XMLHttpRequest.DONE) {
                if (request.status === 200) {
                    var response = JSON.parse(request.responseText)
                    calendarModel.clear()
                    
                    if (response.items) {
                        for (var i = 0; i < response.items.length; i++) {
                            var event = response.items[i]
                            var start = event.start.dateTime || event.start.date
                            var end = event.end.dateTime || event.end.date
                            
                            var startDate = new Date(start)
                            var endDate = new Date(end)
                            var dateStr = startDate.toISOString().split('T')[0]
                            var timeStr = ""
                            
                            if (event.start.dateTime) {
                                var startTime = startDate.toLocaleTimeString('en-US', {hour: '2-digit', minute: '2-digit', hour12: false})
                                var endTime = endDate.toLocaleTimeString('en-US', {hour: '2-digit', minute: '2-digit', hour12: false})
                                timeStr = startTime + " - " + endTime
                            } else {
                                timeStr = "All day"
                            }
                            
                            calendarModel.append({
                                title: event.summary || "No Title",
                                date: dateStr,
                                time: timeStr,
                                location: event.location || ""
                            })
                        }
                    }
                    
                    statusText = "Loaded " + calendarModel.count + " events"
                } else if (request.status === 401) {
                    statusText = "Authentication expired. Please re-authenticate."
                } else {
                    statusText = "Error loading events: " + request.status
                }
            }
        }
        
        request.send()
    }
    
    fullRepresentation: Item {
        width: 350
        height: 500
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            
            Row {
                spacing: 8
                
                PlasmaComponents.Label {
                    text: "Gmail Calendar"
                    font.bold: true
                }
                
                Item { width: 1; height: 1 }
                
                PlasmaComponents.ToolButton {
                    iconSource: "configure"
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
                        height: 60
                        Column {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
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
            }
            
            PlasmaComponents.Button {
                Layout.fillWidth: true
                text: "Refresh"
                onClicked: refreshEvents()
            }
        }
    }
    
    Component.onCompleted: {
        loadConfig()
        if (accessToken && calendarId) {
            refreshEvents()
        } else {
            statusText = "Please configure the widget"
        }
    }
}

