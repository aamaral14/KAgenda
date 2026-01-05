import QtQuick 2.0
import QtQuick.Controls 2.5 as QQC2
import org.kde.kirigami 2.4 as Kirigami
import org.kde.plasma.plasmoid 2.0

Kirigami.FormLayout {
    id: page
    
    property alias cfg_accessToken: tokenField.text
    property alias cfg_calendarId: calendarIdField.text
    
    Component.onCompleted: {
        console.log("ConfigGeneral.qml loaded!")
        console.log("cfg_accessToken:", cfg_accessToken)
        console.log("cfg_calendarId:", cfg_calendarId)
    }
    
    QQC2.Label {
        text: "Gmail Calendar Widget Configuration"
        font.bold: true
        font.pointSize: 14
    }
    
    QQC2.TextField {
        id: tokenField
        Kirigami.FormData.label: "Access Token:"
        placeholderText: "Paste access token here"
        Layout.fillWidth: true
    }
    
    QQC2.TextField {
        id: calendarIdField
        Kirigami.FormData.label: "Calendar ID:"
        placeholderText: "Enter calendar ID"
        Layout.fillWidth: true
    }
    
    QQC2.Label {
        text: "Step 1: Run OAuth helper:\npython3 ~/.local/share/plasma/plasmoids/com.github.gmailcalendar/oauth-helper.py\n\nStep 2: Paste the access token above\nStep 3: Enter your calendar ID"
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
}
