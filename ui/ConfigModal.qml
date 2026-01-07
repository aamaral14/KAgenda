import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support

Item {
    id: configModal
    anchors.fill: parent
    z: 999999
    visible: true
    
    onVisibleChanged: {
        if (visible) {
            // Check authentication status when modal becomes visible
            checkAuthenticationStatus()
        }
    }
    
    property var plasmoidRef: null
    property var onClose: null
    property var rootRef: null
    
    // State management
    property string currentState: "auth" // "auth", "nextcloudEndpoints", "authenticating", "selectCalendar", "configured"
    property string selectedProvider: ""
    property string authStatusText: ""
    property string redirectUri: "" // Stores the redirect URI with port for display
    property int nextcloudPort: -1 // Stores the port that will be used for Nextcloud OAuth callback

    // Nextcloud-specific parameters (entered in the popup)
    // Default values for debugging
    property string nextcloudAuthEndpoint: "http://localhost:8080/apps/oauth2/authorize"
    property string nextcloudTokenEndpoint: "http://localhost:8080/apps/oauth2/api/v1/token"
    property string nextcloudClientId: "iTX4CegtmoQCzJXrv2TQ7FZuCpHm4RpmXoAFdNhXhwM9dmGa8eGBswzpqLynT2FU"
    property string nextcloudClientSecret: "RwIyqt0beO9PswDM4iZa2KH5WepHlR1OF2q1q38DtJxJArh3k87xTOpk5mfRcDNP"
    
    // Calendar list model
    property var calendarListModel: ListModel { id: calendarListModel }
    
    // Property to track authentication status
    property bool isAuthenticated: false
    
    // Function to check and update authentication status
    function checkAuthenticationStatus() {
        if (!plasmoidRef || !plasmoidRef.configuration) {
            isAuthenticated = false
            return false
        }
        
        var hasToken = plasmoidRef.configuration.accessToken && plasmoidRef.configuration.accessToken.length > 0
        var hasCalendar = plasmoidRef.configuration.calendarId && plasmoidRef.configuration.calendarId.length > 0
        var wasAuthenticated = isAuthenticated
        isAuthenticated = hasToken && hasCalendar
        
        // If we just became authenticated, update the state
        if (isAuthenticated && !wasAuthenticated) {
            if (currentState === "selectCalendar" || currentState === "authenticating" || currentState === "auth") {
                currentState = "configured"
                var provider = selectedProvider || plasmoidRef.configuration.provider || "google"
                var calendarId = plasmoidRef.configuration.calendarId || "Unknown"
                authStatusText = "Authenticated with " + provider + ". Calendar: " + calendarId
            }
        } else if (!isAuthenticated && wasAuthenticated && currentState === "configured") {
            currentState = "auth"
            authStatusText = "Logged out. Please authenticate again."
        }
        
        return isAuthenticated
    }
    
    // Computed property to check if all required fields are filled
    property bool canSave: {
        if (currentState === "nextcloudEndpoints") {
            // All Nextcloud fields must be filled
            return nextcloudAuthEndpoint.trim() !== "" && 
                   nextcloudTokenEndpoint.trim() !== "" && 
                   nextcloudClientId.trim() !== "" && 
                   nextcloudClientSecret.trim() !== ""
        } else if (currentState === "selectCalendar") {
            // A calendar must be selected
            return calendarCombo.currentIndex >= 0 && calendarListModel.count > 0
        } else if (currentState === "auth") {
            // In auth state, no fields to fill, so Save is not applicable
            return false
        } else if (currentState === "authenticating") {
            // During authentication, Save is disabled
            return false
        }
        return false
    }
    
    Component.onCompleted: {
        console.log("ConfigModal Component.onCompleted")
        // Check if already authenticated
        checkAuthenticationStatus()
        if (isAuthenticated) {
            currentState = "configured"
            selectedProvider = plasmoidRef.configuration.provider || "google"
            authStatusText = "Authenticated with " + (selectedProvider === "nextcloud" ? "Nextcloud" : "Google") + ". Calendar: " + (plasmoidRef.configuration.calendarId || "Unknown")
            loadCalendarsFromConfig()
        } else if (plasmoidRef && plasmoidRef.configuration.accessToken) {
            currentState = "selectCalendar"
            selectedProvider = plasmoidRef.configuration.provider || "google"
            loadCalendarsFromConfig()
        } else {
            currentState = "auth"
        }
    }
    
    // Watch for state changes to trigger port scanning
    onCurrentStateChanged: {
        if (currentState === "nextcloudEndpoints" && nextcloudPort < 0) {
            console.log("State changed to nextcloudEndpoints, scanning for port...")
            findAvailablePort()
        }
    }
    
    // Timer to periodically check authentication status (since configuration properties might not emit change signals)
    Timer {
        id: authStatusTimer
        interval: 200
        running: visible
        repeat: true
        onTriggered: {
            checkAuthenticationStatus()
        }
    }
    
    function getHomeDir() {
        var currentFile = Qt.resolvedUrl(".")
        var filePath = String(currentFile).replace("file://", "").replace("/contents/ui", "")
        var pathParts = filePath.split("/")
        if (pathParts.length >= 3) {
            return "/" + pathParts[1] + "/" + pathParts[2]
        }
        return "/home/" + (pathParts.length > 2 ? pathParts[2] : "user")
    }
    
    function findAvailablePort() {
        // Use oauth-helper.py with --find-port option to find an available port
        var homeDir = getHomeDir()
        var scriptPath = homeDir + "/.local/share/plasma/plasmoids/com.github.kagenda/oauth-helper.py"
        var command = "python3 '" + scriptPath + "' --find-port"
        
        console.log("Scanning for available port...")
        portScanner.connectSource(command)
    }
    
    function executeOAuth(provider) {
        if (provider === "nextcloud") {
            // For Nextcloud, first show endpoint input fields
            currentState = "nextcloudEndpoints"
            selectedProvider = provider
            authStatusText = "Enter Nextcloud OAuth endpoints:"
            // Find an available port and update redirect URI
            findAvailablePort()
        } else {
            // For Google, proceed directly to authentication
            currentState = "authenticating"
            selectedProvider = provider
            authStatusText = "Opening browser for " + provider + " authentication..."
            
            var homeDir = getHomeDir()
            var scriptPath = homeDir + "/.local/share/plasma/plasmoids/com.github.kagenda/oauth-helper.py"
            
            oauthExecutable.connectSource("python3 '" + scriptPath + "' " + provider)
        }
    }
    
    function executeNextcloudOAuth() {
        if (!nextcloudAuthEndpoint || !nextcloudTokenEndpoint) {
            authStatusText = "Please enter both Authorization and Token endpoints"
            return
        }

        if (!nextcloudClientId || !nextcloudClientSecret) {
            authStatusText = "Please enter both Client ID and Client Secret"
            return
        }
        
        if (nextcloudPort < 0) {
            authStatusText = "Port not available. Please try again."
            findAvailablePort()
            return
        }
        
        currentState = "authenticating"
        authStatusText = "Opening browser for Nextcloud authentication..."
        
        var homeDir = getHomeDir()
        var scriptPath = homeDir + "/.local/share/plasma/plasmoids/com.github.kagenda/oauth-helper.py"
        
        // Pass endpoints, credentials, and port as arguments:
        // provider auth_endpoint token_endpoint client_id client_secret port
        var command = "python3 '" + scriptPath + "' nextcloud '" +
                      nextcloudAuthEndpoint + "' '" +
                      nextcloudTokenEndpoint + "' '" +
                      nextcloudClientId + "' '" +
                      nextcloudClientSecret + "' " +
                      nextcloudPort
        
        console.log("DEBUG: Executing Nextcloud OAuth with parameters:")
        console.log("  - Auth Endpoint:", nextcloudAuthEndpoint)
        console.log("  - Token Endpoint:", nextcloudTokenEndpoint)
        console.log("  - Client ID:", nextcloudClientId.substring(0, 20) + "...")
        console.log("  - Port:", nextcloudPort)
        console.log("  - Command:", command.substring(0, 100) + "...")
        
        oauthExecutable.connectSource(command)
    }
    
    function parseCalendarList(jsonString) {
        try {
            console.log("parseCalendarList - Raw JSON string (first 500 chars):", jsonString.substring(0, 500))
            
            var cleanJson = jsonString.trim()
            var jsonStart = cleanJson.indexOf('{')
            var jsonEnd = cleanJson.lastIndexOf('}') + 1
            if (jsonStart >= 0 && jsonEnd > jsonStart) {
                cleanJson = cleanJson.substring(jsonStart, jsonEnd)
            }
            
            var calendarData = JSON.parse(cleanJson)
            console.log("parseCalendarList - Parsed calendar data:", JSON.stringify(calendarData).substring(0, 500))
            calendarListModel.clear()
            
            if (calendarData.items && Array.isArray(calendarData.items)) {
                console.log("parseCalendarList - Found", calendarData.items.length, "calendars")
                for (var i = 0; i < calendarData.items.length; i++) {
                    var item = calendarData.items[i]
                    console.log("parseCalendarList - Calendar", i, ":", JSON.stringify(item))
                    
                    // Validate calendar ID
                    var calendarId = item.id || ""
                    if (!calendarId || calendarId.length < 1 || calendarId === "<") {
                        console.log("WARNING: Invalid calendar ID:", calendarId, "- skipping calendar:", item.summary)
                        continue
                    }
                    
                    var displayText = item.summary || item.id
                    if (item.primary) {
                        displayText += " (Primary)"
                    }
                    calendarListModel.append({
                        id: calendarId,
                        summary: item.summary || item.id,
                        display: displayText,
                        primary: item.primary || false
                    })
                    console.log("parseCalendarList - Added calendar:", displayText, "with ID:", calendarId)
                }
            }
            
            if (calendarListModel.count > 0) {
                currentState = "selectCalendar"
                authStatusText = "Authentication successful! Select a calendar:"
            } else {
                authStatusText = "Authentication successful but no calendars found."
            }
        } catch(e) {
            console.log("Error parsing calendar list:", e)
            authStatusText = "Error parsing calendar list: " + e.toString()
        }
    }
    
    function loadCalendarsFromConfig() {
        // Try to load calendars from config file if available
        var homeDir = getHomeDir()
        var configPath = homeDir + "/.config/kagenda/config.json"
        configReader.connectSource("cat '" + configPath + "' 2>/dev/null || echo '{}'")
    }
    
    function saveConfiguration() {
        if (!plasmoidRef || !plasmoidRef.configuration) return
        
        if (calendarCombo.currentIndex >= 0 && calendarListModel.count > 0) {
            var calendar = calendarListModel.get(calendarCombo.currentIndex)
            console.log("Saving calendar selection:")
            console.log("  - Selected index:", calendarCombo.currentIndex)
            console.log("  - Calendar object:", JSON.stringify(calendar))
            console.log("  - Calendar ID:", calendar.id)
            console.log("  - Calendar summary:", calendar.summary)
            console.log("  - Calendar display:", calendar.display)
            
            // Validate calendar ID before saving
            if (!calendar.id || calendar.id.length < 1 || calendar.id === "<" || calendar.id.trim() === "") {
                console.log("ERROR: Invalid calendar ID detected:", calendar.id)
                authStatusText = "ERROR: Invalid calendar ID. Please try selecting a different calendar."
                return
            }
            
            plasmoidRef.configuration.calendarId = String(calendar.id).trim()
            console.log("  - Saved calendar ID:", plasmoidRef.configuration.calendarId)
            // Check authentication status immediately after saving calendarId
            checkAuthenticationStatus()
        } else {
            console.log("WARNING: No calendar selected! Index:", calendarCombo.currentIndex, "Count:", calendarListModel.count)
            authStatusText = "Please select a calendar"
            return
        }
        
        console.log("Saving provider:", selectedProvider)
        plasmoidRef.configuration.provider = selectedProvider
        
        // Don't overwrite nextcloudServer - it's already set correctly by the Python script
        // in the config file and loaded via loadAccessTokenFromConfig()
        // The Python script extracts the correct server URL from the endpoints provided
        
        // Load token from config file
        loadAccessTokenFromConfig()
        
        // Wait a moment for token to load, then refresh events
        Qt.callLater(function() {
            // Check authentication status after token loads
            checkAuthenticationStatus()
            
            // If authenticated, update the UI
            if (isAuthenticated) {
                currentState = "configured"
                authStatusText = "Configuration saved! Authenticated with " + selectedProvider + "."
            }
            
            // Trigger refresh in parent
            if (rootRef && typeof rootRef.refreshEvents === 'function') {
                rootRef.refreshEvents()
            }
            
            // Close modal after a brief delay to ensure save is complete
            Qt.callLater(function() {
                if (onClose) onClose()
            })
        })
    }
    
    function loadAccessTokenFromConfig() {
        var homeDir = getHomeDir()
        var configPath = homeDir + "/.config/kagenda/config.json"
        tokenReader.connectSource("cat '" + configPath + "' 2>/dev/null || echo '{}'")
    }
    
    function logout() {
        if (!plasmoidRef || !plasmoidRef.configuration) return
        
        console.log("Logging out - clearing tokens and events")
        
        // Clear configuration
        plasmoidRef.configuration.accessToken = ""
        plasmoidRef.configuration.calendarId = ""
        plasmoidRef.configuration.provider = ""
        plasmoidRef.configuration.nextcloudServer = ""
        
        // Clear models
        calendarListModel.clear()
        
        // Clear events in root if available
        if (rootRef) {
            if (typeof rootRef.calendarModel !== 'undefined' && rootRef.calendarModel) {
                rootRef.calendarModel.clear()
            }
            if (typeof rootRef.logout === 'function') {
                rootRef.logout()
            }
        }
        
        // Update authentication status
        checkAuthenticationStatus()
        
        // Reset state
        currentState = "auth"
        selectedProvider = ""
        authStatusText = "Logged out. Please authenticate again."
        redirectUri = ""
        nextcloudPort = -1
        
        // Reset Nextcloud fields
        nextcloudAuthEndpoint = "http://localhost:8080/apps/oauth2/authorize"
        nextcloudTokenEndpoint = "http://localhost:8080/apps/oauth2/api/v1/token"
        nextcloudClientId = ""
        nextcloudClientSecret = ""
        
        console.log("Logout complete")
    }
    
    // DataSource for OAuth execution
    P5Support.DataSource {
        id: oauthExecutable
        engine: "executable"
        connectedSources: []
        
        onNewData: function(sourceName, data) {
            var exitCode = data["exit code"] || 0
            var stdout = data.stdout || ""
            var stderr = data.stderr || ""
            
            console.log("OAuth script finished. Exit code:", exitCode)
            console.log("Stderr:", stderr)
            
            // Extract redirect URI from stderr if present (for display in popup)
            if (stderr) {
                var uriMatch = stderr.match(/Using redirect URI:\s*(http:\/\/localhost:\d+\/[^\n]+)/)
                if (uriMatch) {
                    redirectUri = uriMatch[1]
                    console.log("Found redirect URI:", redirectUri)
                }
            }
            
            if (exitCode === 0) {
                if (stdout && stdout.trim()) {
                    parseCalendarList(stdout)
                    // Wait a bit then load token
                    tokenLoadTimer.start()
                } else {
                    authStatusText = "Authentication completed but no calendar data received."
                }
            } else {
                authStatusText = "Authentication failed: " + (stderr || "Unknown error")
                currentState = "auth"
            }
            disconnectSource(sourceName)
        }
    }
    
    // DataSource for reading config file
    P5Support.DataSource {
        id: configReader
        engine: "executable"
        connectedSources: []
        
        onNewData: function(sourceName, data) {
            if (data["exit code"] === 0) {
                var output = data.stdout || ""
                if (output && output.trim()) {
                    try {
                        var config = JSON.parse(output.trim())
                        if (config.access_token) {
                            parseCalendarList(JSON.stringify({items: config.calendars || []}))
                        }
                    } catch(e) {
                        console.log("Error parsing config:", e)
                    }
                }
            }
            disconnectSource(sourceName)
        }
    }
    
    // DataSource for reading token from config
    P5Support.DataSource {
        id: tokenReader
        engine: "executable"
        connectedSources: []
        
        onNewData: function(sourceName, data) {
            if (data["exit code"] === 0) {
                var output = data.stdout || ""
                if (output && output.trim()) {
                    try {
                        var config = JSON.parse(output.trim())
                        if (config.access_token && plasmoidRef) {
                            plasmoidRef.configuration.accessToken = config.access_token
                            if (config.provider) {
                                plasmoidRef.configuration.provider = config.provider
                            }
                            if (config.nextcloud_server) {
                                plasmoidRef.configuration.nextcloudServer = config.nextcloud_server
                            }
                            
                            // Check authentication status after token is loaded
                            checkAuthenticationStatus()
                        }
                    } catch(e) {
                        console.log("Error parsing token config:", e)
                    }
                }
            }
            disconnectSource(sourceName)
        }
    }
    
    // DataSource for scanning available port
    P5Support.DataSource {
        id: portScanner
        engine: "executable"
        connectedSources: []
        
        onNewData: function(sourceName, data) {
            if (data["exit code"] === 0) {
                var output = data.stdout || ""
                var port = parseInt(output.trim())
                if (!isNaN(port) && port > 0) {
                    nextcloudPort = port
                    redirectUri = "http://localhost:" + port + "/oauth-callback"
                    console.log("Found available port:", port)
                } else {
                    console.log("Failed to find available port")
                    nextcloudPort = -1
                    redirectUri = ""
                }
            } else {
                console.log("Port scanner error:", data.stderr)
                nextcloudPort = -1
                redirectUri = ""
            }
            disconnectSource(sourceName)
        }
    }
    
    Timer {
        id: tokenLoadTimer
        interval: 500
        repeat: false
        onTriggered: {
            loadAccessTokenFromConfig()
        }
    }
    
    // Semi-transparent background overlay
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.6
        
        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (onClose) onClose()
            }
        }
    }
    
    // Modal content
    Rectangle {
        id: modalContent
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.9, 650)
        height: Math.min(parent.height * 0.8, 500)
        radius: 8
        color: "#2b2b2b"
        border.color: "#555555"
        border.width: 1
        z: 999999
        clip: false
        
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#2b2b2b" }
            GradientStop { position: 1.0; color: "#1e1e1e" }
        }
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15
            clip: false
            
            // Title (fixed header)
            RowLayout {
                Layout.fillWidth: true
                
                PlasmaComponents.Label {
                    text: "KAgenda Calendar Configuration"
                    font.bold: true
                    font.pointSize: 16
                    color: "#ffffff"
                }
                
                Item { Layout.fillWidth: true }
                
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

            // Scrollable content area (everything below the header)
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: contentColumn.implicitHeight

                ColumnLayout {
                    id: contentColumn
                    width: parent.width
                    spacing: 15

                    // Status text
                    PlasmaComponents.Label {
                        id: statusLabel
                        Layout.fillWidth: true
                        text: authStatusText || "Select authentication method:"
                        color: (currentState === "configured" && isAuthenticated) ? "#88ff88" : "#ffffff"
                        wrapMode: Text.WordWrap
                        visible: authStatusText.length > 0 || currentState === "auth"
                    }
                    
                    // Authentication buttons (shown when not authenticated)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        visible: !isAuthenticated && currentState === "auth"
                        
                        PlasmaComponents.Button {
                            Layout.fillWidth: true
                            text: "Authenticate with Google"
                            enabled: currentState === "auth"
                            onClicked: {
                                executeOAuth("google")
                            }
                        }
                        
                        PlasmaComponents.Button {
                            Layout.fillWidth: true
                            text: "Authenticate with Nextcloud"
                            enabled: currentState === "auth"
                            onClicked: {
                                executeOAuth("nextcloud")
                            }
                        }
                    }
                    
                    // Nextcloud endpoint & credentials input fields
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        visible: currentState === "nextcloudEndpoints"
                        
                        // Display redirect URI with port
                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            text: redirectUri ? "Redirect URI (register this in Nextcloud):" : "Finding available port..."
                            color: "#88ccff"
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }
                        
                        // Make redirect URI selectable for copy/paste
                        QQC2.TextField {
                            Layout.fillWidth: true
                            text: redirectUri || "Scanning ports..."
                            readOnly: true
                            selectByMouse: true
                            font.family: redirectUri ? "monospace" : "default"
                            color: redirectUri ? "#ffffff" : "#aaaaaa"
                            background: Rectangle {
                                color: "#1e1e1e"
                                border.color: redirectUri ? "#555555" : "transparent"
                                border.width: 1
                                radius: 4
                            }
                        }
                        
                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            text: "Authorization Endpoint:"
                            color: "#ffffff"
                        }
                        
                        QQC2.TextField {
                            id: authEndpointField
                            Layout.fillWidth: true
                            placeholderText: "https://your-nextcloud.com/index.php/apps/oauth2/authorize"
                            text: nextcloudAuthEndpoint
                            onTextChanged: nextcloudAuthEndpoint = text
                            background: Rectangle {
                                color: "#1e1e1e"
                                border.color: "#555555"
                                border.width: 1
                                radius: 4
                            }
                        }
                        
                        PlasmaComponents.Label {
                            text: "Token Endpoint:"
                            color: "#ffffff"
                        }
                        
                        QQC2.TextField {
                            id: tokenEndpointField
                            Layout.fillWidth: true
                            placeholderText: "https://your-nextcloud.com/index.php/apps/oauth2/api/v1/token"
                            text: nextcloudTokenEndpoint
                            onTextChanged: nextcloudTokenEndpoint = text
                            background: Rectangle {
                                color: "#1e1e1e"
                                border.color: "#555555"
                                border.width: 1
                                radius: 4
                            }
                        }

                        PlasmaComponents.Label {
                            text: "Client ID:"
                            color: "#ffffff"
                        }

                        QQC2.TextField {
                            id: clientIdField
                            Layout.fillWidth: true
                            placeholderText: "OAuth client ID from Nextcloud"
                            text: nextcloudClientId
                            onTextChanged: nextcloudClientId = text
                            background: Rectangle {
                                color: "#1e1e1e"
                                border.color: "#555555"
                                border.width: 1
                                radius: 4
                            }
                        }

                        PlasmaComponents.Label {
                            text: "Client Secret:"
                            color: "#ffffff"
                        }

                        QQC2.TextField {
                            id: clientSecretField
                            Layout.fillWidth: true
                            echoMode: TextInput.Password
                            placeholderText: "OAuth client secret from Nextcloud"
                            text: nextcloudClientSecret
                            onTextChanged: nextcloudClientSecret = text
                            background: Rectangle {
                                color: "#1e1e1e"
                                border.color: "#555555"
                                border.width: 1
                                radius: 4
                            }
                        }
                    }
                    
                    // Authenticating state
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        visible: currentState === "authenticating"
                        
                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            text: "Please complete authentication in your browser..."
                            color: "#ffffff"
                            wrapMode: Text.WordWrap
                        }
                        
                        // Display redirect URI/port if available
                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            text: redirectUri ? "Redirect URI: " + redirectUri : ""
                            color: "#88ccff"
                            font.bold: true
                            wrapMode: Text.WordWrap
                            visible: redirectUri.length > 0
                        }
                        
                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            text: redirectUri ? "Make sure this URI is registered in your " + (selectedProvider === "nextcloud" ? "Nextcloud" : "Google") + " OAuth app settings." : ""
                            color: "#aaaaaa"
                            font.pointSize: 9
                            wrapMode: Text.WordWrap
                            visible: redirectUri.length > 0
                        }
                        
                        QQC2.BusyIndicator {
                            Layout.alignment: Qt.AlignHCenter
                            running: true
                        }
                    }
                    
                    // Calendar selection (shown after authentication)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        visible: currentState === "selectCalendar"
                        
                        PlasmaComponents.Label {
                            text: "Select Calendar:"
                            color: "#ffffff"
                        }
                        
                        // Custom dropdown using Button + Popup
                        QQC2.Button {
                            id: calendarButton
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            text: calendarCombo.currentIndex >= 0 && calendarListModel.count > 0 ? calendarListModel.get(calendarCombo.currentIndex).display : "Select Calendar..."
                            
                            background: Rectangle {
                                color: "#1e1e1e"
                                border.color: "#555555"
                                border.width: 1
                                radius: 4
                            }
                            
                            contentItem: Text {
                                text: calendarButton.text
                                font: calendarButton.font
                                color: "#ffffff"
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 12
                                elide: Text.ElideRight
                            }
                            
                            onClicked: calendarPopup.open()
                            
                            QQC2.Popup {
                                id: calendarPopup
                                x: 0
                                y: calendarButton.height + 1
                                width: calendarButton.width
                                implicitHeight: Math.min(calendarListView.contentHeight + 4, 200)
                                padding: 2
                                
                                background: Rectangle {
                                    color: "#2b2b2b"
                                    border.color: "#555555"
                                    border.width: 1
                                    radius: 4
                                }
                                
                                ListView {
                                    id: calendarListView
                                    clip: true
                                    width: parent.width - 4
                                    implicitHeight: contentHeight
                                    model: calendarListModel
                                    spacing: 0
                                    
                                    delegate: QQC2.ItemDelegate {
                                        width: calendarListView.width
                                        height: 36
                                        
                                        contentItem: Text {
                                            text: model.display
                                            color: parent.highlighted ? "#ffffff" : "#cccccc"
                                            font: calendarButton.font
                                            elide: Text.ElideRight
                                            verticalAlignment: Text.AlignVCenter
                                            leftPadding: 12
                                        }
                                        
                                        background: Rectangle {
                                            color: parent.highlighted ? "#3d5afe" : (parent.hovered ? "#3a3a3a" : "transparent")
                                            radius: 0
                                        }
                                        
                                        onClicked: {
                                            console.log("Calendar item clicked - index:", index)
                                            calendarCombo.currentIndex = index
                                            calendarPopup.close()
                                            console.log("CalendarCombo currentIndex set to:", calendarCombo.currentIndex)
                                            if (calendarListModel.count > index) {
                                                var selectedCal = calendarListModel.get(index)
                                                console.log("Selected calendar - ID:", selectedCal ? selectedCal.id : "null", "Summary:", selectedCal ? selectedCal.summary : "null")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Hidden ComboBox to maintain compatibility with existing code
                        QQC2.ComboBox {
                            id: calendarCombo
                            visible: false
                            model: calendarListModel
                            textRole: "display"
                            
                            Component.onCompleted: {
                                // Select saved calendar if available
                                if (plasmoidRef && plasmoidRef.configuration.calendarId) {
                                    var savedId = plasmoidRef.configuration.calendarId
                                    for (var i = 0; i < calendarListModel.count; i++) {
                                        if (calendarListModel.get(i).id === savedId) {
                                            calendarCombo.currentIndex = i
                                            break
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Extra spacer at bottom so last element isn't cut off
                    Item {
                        Layout.fillWidth: true
                        Layout.minimumHeight: 10
                    }
                }
            }
            
            // Buttons - fixed at bottom
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
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
                    text: isAuthenticated ? "Logout" : "Save"
                    Layout.preferredWidth: 80
                    enabled: isAuthenticated ? true : canSave
                    onClicked: {
                        if (isAuthenticated) {
                            // Logout
                            logout()
                        } else if (currentState === "selectCalendar") {
                            saveConfiguration()
                        } else if (currentState === "nextcloudEndpoints") {
                            // Validate and proceed with Nextcloud authentication
                            executeNextcloudOAuth()
                        } else {
                            if (onClose) onClose()
                        }
                    }
                }
            }
        }
    }
}
