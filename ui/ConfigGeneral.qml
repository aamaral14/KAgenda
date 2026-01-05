import QtQuick 2.0
import QtQuick.Controls 2.5 as QQC2
import QtQuick.Layouts 1.0
import org.kde.kirigami 2.4 as Kirigami
import org.kde.plasma.plasmoid 2.0

Kirigami.FormLayout {
    id: page
    
    property alias cfg_accessToken: tokenField.text
    property alias cfg_calendarId: calendarIdField.text
    
    Component.onCompleted: {
        // Sync initial values
        if (plasmoid.configuration.accessToken) {
            tokenField.text = plasmoid.configuration.accessToken
        }
        if (plasmoid.configuration.calendarId) {
            calendarIdField.text = plasmoid.configuration.calendarId
        }
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
        text: plasmoid.configuration.accessToken || ""
        onTextChanged: {
            plasmoid.configuration.accessToken = text
        }
    }
    
    QQC2.TextField {
        id: calendarIdField
        Kirigami.FormData.label: "Calendar ID:"
        placeholderText: "Enter calendar ID"
        text: plasmoid.configuration.calendarId || ""
        onTextChanged: {
            plasmoid.configuration.calendarId = text
        }
    }
    
    QQC2.Label {
        text: "Step 1: Run OAuth helper:\npython3 ~/.local/share/plasma/plasmoids/com.github.kagenda/oauth-helper.py\n\nStep 2: Paste the access token above\nStep 3: Enter your calendar ID"
        wrapMode: Text.WordWrap
    }
}

