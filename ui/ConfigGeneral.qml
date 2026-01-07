import QtQuick 2.0
import QtQuick.Controls 2.5 as QQC2
import QtQuick.Layouts 1.0
import org.kde.kirigami 2.4 as Kirigami
import org.kde.plasma.plasmoid 2.0

Kirigami.FormLayout {
    id: page
    
    property alias cfg_accessToken: tokenField.text
    property alias cfg_calendarId: calendarIdField.text
    property alias cfg_provider: providerCombo.currentText
    property alias cfg_nextcloudServer: nextcloudServerField.text
    
    Component.onCompleted: {
        // Sync initial values
        if (plasmoid.configuration.accessToken) {
            tokenField.text = plasmoid.configuration.accessToken
        }
        if (plasmoid.configuration.calendarId) {
            calendarIdField.text = plasmoid.configuration.calendarId
        }
        if (plasmoid.configuration.provider) {
            var index = providerCombo.find(plasmoid.configuration.provider)
            if (index >= 0) {
                providerCombo.currentIndex = index
            }
        }
        if (plasmoid.configuration.nextcloudServer) {
            nextcloudServerField.text = plasmoid.configuration.nextcloudServer
        }
    }
    
    QQC2.Label {
        text: "KAgenda Calendar Widget Configuration"
        font.bold: true
        font.pointSize: 14
    }
    
    QQC2.ComboBox {
        id: providerCombo
        Kirigami.FormData.label: "Calendar Provider:"
        model: ["google", "nextcloud"]
        onActivated: {
            plasmoid.configuration.provider = currentText
            nextcloudServerField.visible = (currentText === "nextcloud")
        }
        Component.onCompleted: {
            var savedProvider = plasmoid.configuration.provider || "google"
            var index = find(savedProvider)
            if (index >= 0) {
                currentIndex = index
            }
            nextcloudServerField.visible = (currentText === "nextcloud")
        }
    }
    
    QQC2.TextField {
        id: nextcloudServerField
        Kirigami.FormData.label: "Nextcloud Server URL:"
        placeholderText: "https://your-nextcloud.com"
        text: plasmoid.configuration.nextcloudServer || ""
        visible: providerCombo.currentText === "nextcloud"
        onTextChanged: {
            plasmoid.configuration.nextcloudServer = text
        }
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
        placeholderText: providerCombo.currentText === "google" ? "Enter calendar ID (e.g., primary)" : "Enter calendar ID"
        text: plasmoid.configuration.calendarId || ""
        onTextChanged: {
            plasmoid.configuration.calendarId = text
        }
    }
    
    QQC2.Label {
        text: {
            if (providerCombo.currentText === "google") {
                return "Step 1: Run OAuth helper:\npython3 ~/.local/share/plasma/plasmoids/com.github.kagenda/oauth-helper.py google\n\nStep 2: Paste the access token above\nStep 3: Enter your calendar ID"
            } else {
                return "Step 1: Create nextcloud_credentials.json in ~/.config/kagenda/\nFormat: {\"server_url\": \"https://your-nextcloud.com\", \"client_id\": \"...\", \"client_secret\": \"...\"}\n\nStep 2: Run OAuth helper:\npython3 ~/.local/share/plasma/plasmoids/com.github.kagenda/oauth-helper.py nextcloud\n\nStep 3: Paste the access token above\nStep 4: Enter your calendar ID"
            }
        }
        wrapMode: Text.WordWrap
    }
}

