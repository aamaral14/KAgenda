import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.components as PlasmaComponents

KCM.SimpleKCM {
    id: configPage
    
    // Configuration properties - these are automatically saved/loaded by Plasma
    property string cfg_accessToken: ""
    property string cfg_calendarId: ""
    
    property string statusText: "Ready"
    property var calendarListModel: ListModel { id: calendarListModel }
    
    // Use cfg_ properties
    property string accessToken: cfg_accessToken
    property string calendarId: cfg_calendarId
    
    Kirigami.FormLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        PlasmaComponents.Label {
            Kirigami.FormData.label: "Status:"
            text: statusText
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        
        PlasmaComponents.Label {
            Kirigami.FormData.label: "Step 1:"
            text: "Run OAuth helper in terminal:"
            wrapMode: Text.WordWrap
        }
        
        PlasmaComponents.Label {
            text: "python3 ~/.local/share/plasma/plasmoids/com.github.gmailcalendar/oauth-helper.py"
            font.family: "monospace"
            color: "#808080"
        }
        
        Controls.TextField {
            id: tokenField
            Kirigami.FormData.label: "Step 2: Access Token:"
            placeholderText: "Paste access token here (from OAuth helper output)"
            Layout.fillWidth: true
        }
        
        PlasmaComponents.Button {
            text: "Set Access Token"
            onClicked: {
                if (tokenField.text.length > 20) {
                    cfg_accessToken = tokenField.text.trim()
                    statusText = "Access token set! Now click 'Refresh Calendar List'."
                    Qt.callLater(function() {
                        if (cfg_accessToken) {
                            loadCalendars()
                        }
                    })
                } else {
                    statusText = "Please enter a valid access token (should be long)"
                }
            }
        }
        
        PlasmaComponents.Label {
            Kirigami.FormData.label: "Calendar:"
            text: "Select calendar to display:"
        }
        
        PlasmaComponents.ComboBox {
            id: calendarCombo
            Kirigami.FormData.isSection: false
            Layout.fillWidth: true
            model: calendarListModel
            textRole: "display"
            onActivated: {
                if (currentIndex >= 0) {
                    var calendar = calendarListModel.get(currentIndex)
                    cfg_calendarId = calendar.id
                    statusText = "Calendar selected: " + calendar.display
                }
            }
        }
        
        PlasmaComponents.Button {
            text: "Refresh Calendar List"
            onClicked: loadCalendars()
        }
    }
    
    function loadCalendars() {
        if (!accessToken) {
            statusText = "Please authenticate first. Run the OAuth helper script."
            return
        }
        
        statusText = "Loading calendars..."
        
        var url = "https://www.googleapis.com/calendar/v3/users/me/calendarList"
        var request = new XMLHttpRequest()
        request.open("GET", url)
        request.setRequestHeader("Authorization", "Bearer " + accessToken)
        
        request.onreadystatechange = function() {
            if (request.readyState === XMLHttpRequest.DONE) {
                if (request.status === 200) {
                    var response = JSON.parse(request.responseText)
                    calendarListModel.clear()
                    
                    if (response.items) {
                        for (var i = 0; i < response.items.length; i++) {
                            var item = response.items[i]
                            calendarListModel.append({
                                id: item.id,
                                display: item.summary + (item.primary ? " (Primary)" : "")
                            })
                        }
                    }
                    
                    statusText = "Loaded " + calendarListModel.count + " calendars"
                } else if (request.status === 401) {
                    statusText = "Authentication expired. Please run OAuth helper again."
                } else {
                    statusText = "Error loading calendars: " + request.status
                }
            }
        }
        
        request.send()
    }
    
    Component.onCompleted: {
        if (accessToken) {
            loadCalendars()
        } else {
            statusText = "Please authenticate first and set access token"
        }
    }
}
