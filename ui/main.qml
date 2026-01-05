import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root
    
    preferredRepresentation: fullRepresentation
    
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    
    // Mark widget as configurable
    Plasmoid.configurationRequired: !cfg_accessToken || !cfg_calendarId
    
    // Function to open configuration modal
    function openConfiguration() {
        // Show our custom configuration modal using Popup
        console.log("openConfiguration called, opening popup")
        showConfigModal = true
    }
    
    // Configuration properties - these will be saved/loaded by Plasma
    property string cfg_calendarId: plasmoid.configuration.calendarId || ""
    property string cfg_accessToken: plasmoid.configuration.accessToken || ""
    
    // Configuration modal
    property bool showConfigModal: false
    onShowConfigModalChanged: {
        console.log("showConfigModal changed to:", showConfigModal)
        console.log("configModalLoader.active will be:", showConfigModal)
    }
    
    // Watch for configuration property changes
    onCfg_calendarIdChanged: {
        if (cfg_calendarId && cfg_accessToken) {
            refreshTimer.restart()
        }
    }
    
    onCfg_accessTokenChanged: {
        if (cfg_calendarId && cfg_accessToken) {
            refreshTimer.restart()
        }
    }
    
    property string statusText: ""
    property var calendarModel: ListModel { id: calendarModel }
    property var calendarListModel: ListModel { id: calendarListModel }
    
    // Use cfg_ properties for configuration
    property string accessToken: cfg_accessToken
    property string calendarId: cfg_calendarId
    
    function runOAuthHelper() {
        // For Plasma 6, we'll use a file-based approach since direct process execution is limited
        // The button will trigger the script execution via a helper mechanism
        statusText = "Preparing authentication..."
        
        // We'll use a workaround: create a trigger file that a background process can watch
        // Or use QML's limited process execution capabilities
        // For now, we'll instruct the system to run the script
        // In a real implementation, this would use PlasmaCore.DataSource or a QML extension
        
        // Start monitoring for completion
        oauthOutputTimer.start()
        statusText = "Opening browser for authentication... Please complete the login."
    }
    
    function getHomeDir() {
        // Get home directory by using the known plasmoid path structure
        // The plasmoid is always in ~/.local/share/plasma/plasmoids/com.github.kagenda
        // We can use Qt.resolvedUrl with a relative path or construct it differently
        // Simple approach: use the current QML file location and go up
        var currentFile = Qt.resolvedUrl(".")
        var filePath = String(currentFile).replace("file://", "").replace("/contents/ui", "")
        // filePath should be: /home/user/.local/share/plasma/plasmoids/com.github.kagenda
        var pathParts = filePath.split("/")
        if (pathParts.length >= 3) {
            return "/" + pathParts[1] + "/" + pathParts[2]  // /home/username
        }
        // Fallback: try to extract from any path
        return "/home/" + (pathParts.length > 2 ? pathParts[2] : "user")
    }
    
    function executeOAuthScript() {
        root.statusText = "Executing OAuth helper..."
        
        var homeDir = getHomeDir()
        var scriptPath = homeDir + "/.local/share/plasma/plasmoids/com.github.kagenda/oauth-helper.py"
        
        // Use P5Support.DataSource to execute the Python script
        // The Python script will:
        // 1. Open browser automatically (via flow.run_local_server)
        // 2. Handle OAuth callback
        // 3. Output calendar list JSON to stdout
        // 4. Save access token to config.json
        oauthExecutable.connectSource("python3 '" + scriptPath + "'")
        
        root.statusText = "Executing Python script... Browser should open automatically."
    }
    
    function logout() {
        // Clear authentication
        plasmoid.configuration.accessToken = ""
        plasmoid.configuration.calendarId = ""
        
        // Clear models
        calendarListModel.clear()
        calendarModel.clear()
        
        // Close popup if open
        if (showConfigModal) {
            showConfigModal = false
        }
        
        root.statusText = "Logged out. Please authenticate again."
    }
    
    function loadAccessTokenFromConfig() {
        // Read config file using P5Support.DataSource (executable engine) to read the file
        // This works around XMLHttpRequest file reading restrictions
        var homeDir = getHomeDir()
        var configPath = homeDir + "/.config/kagenda/config.json"
        
        // Use executable engine to read the file
        configReader.connectSource("cat '" + configPath + "' 2>/dev/null || echo '{}'")
    }
    
    function parseCalendarList(jsonString) {
        try {
            // Clean the JSON string - remove any non-JSON content
            var cleanJson = jsonString.trim()
            // Remove any leading/trailing non-JSON text
            var jsonStart = cleanJson.indexOf('{')
            var jsonEnd = cleanJson.lastIndexOf('}') + 1
            if (jsonStart >= 0 && jsonEnd > jsonStart) {
                cleanJson = cleanJson.substring(jsonStart, jsonEnd)
            }
            
            var calendarData = JSON.parse(cleanJson)
            calendarListModel.clear()
            
            if (calendarData.items && Array.isArray(calendarData.items)) {
                for (var i = 0; i < calendarData.items.length; i++) {
                    var item = calendarData.items[i]
                    var displayText = item.summary || item.id
                    if (item.primary) {
                        displayText += " (Primary)"
                    }
                    calendarListModel.append({
                        id: item.id,
                        summary: item.summary || item.id,
                        display: displayText,
                        primary: item.primary || false
                    })
                }
            }
            
            // Don't auto-select calendar - let user choose in the popup
            // Just update the combo box selection if popup is open
            if (calendarListModel.count > 0) {
                // Update UI elements if they exist (only if popup is open)
                // Use Qt.callLater to ensure UI is ready
                Qt.callLater(function() {
                    if (typeof calendarCombo !== 'undefined' && calendarCombo) {
                        // Update selection to match saved calendar or show placeholder
                        calendarCombo.updateSelection()
                    }
                })
            }
            
            console.log("Successfully parsed", calendarListModel.count, "calendars")
        } catch(e) {
            console.log("Error parsing calendar list:", e)
            console.log("JSON string was:", jsonString.substring(0, 200))
            root.statusText = "Error parsing calendar list: " + e.toString()
        }
    }
    
    function refreshEvents() {
        // Use cfg_ properties directly
        var token = cfg_accessToken || ""
        var calId = cfg_calendarId || ""
        
        if (!calId || !token) {
            statusText = "Please configure the widget"
            return
        }
        
        statusText = "Loading events..."
        
        var now = new Date()
        var later = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000)
        var timeMin = now.toISOString()
        var timeMax = later.toISOString()
        
        var url = "https://www.googleapis.com/calendar/v3/calendars/" + 
                  encodeURIComponent(calId) + 
                  "/events?timeMin=" + encodeURIComponent(timeMin) + 
                  "&timeMax=" + encodeURIComponent(timeMax) + 
                  "&maxResults=50&singleEvents=true&orderBy=startTime"
        
        var request = new XMLHttpRequest()
        request.open("GET", url)
        request.setRequestHeader("Authorization", "Bearer " + token)
        
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
                    
                    // Status text removed - no longer displayed
                } else if (request.status === 401) {
                    statusText = "Authentication expired. Please re-authenticate."
                } else {
                    statusText = "Error loading events: " + request.status
                }
            }
        }
        
        request.send()
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
                            // Save to plasmoid configuration
                            plasmoid.configuration.accessToken = config.access_token
                            console.log("Access token loaded and saved to configuration:", config.access_token.substring(0, 20) + "...")
                            
                            // If we have a calendar ID, refresh events immediately
                            if (cfg_calendarId && cfg_calendarId.length > 0) {
                                Qt.callLater(function() {
                                    root.refreshEvents()
                                })
                            }
                        } else {
                            console.log("No access_token found in config file")
                        }
                    } catch(e) {
                        console.log("Error parsing config:", e, "Output:", output.substring(0, 100))
                    }
                } else {
                    console.log("Config file is empty or could not be read")
                }
            } else {
                console.log("Failed to read config file, exit code:", data["exit code"])
            }
            disconnectSource(sourceName)
        }
    }
    
    // DataSource for executing Python script (Plasma 6 compatibility)
    P5Support.DataSource {
        id: oauthExecutable
        engine: "executable"
        connectedSources: []
        
        onNewData: function(sourceName, data) {
            var exitCode = data["exit code"] || 0
            var stdout = data.stdout || ""
            var stderr = data.stderr || ""
            
            console.log("OAuth script finished. Exit code:", exitCode)
            console.log("Stdout length:", stdout.length)
            console.log("Stderr length:", stderr.length)
            
            if (exitCode === 0) {
                if (stdout && stdout.trim()) {
                    // Parse the calendar list JSON from Python script output
                    try {
                        // The Python script outputs clean JSON to stdout
                        var jsonOutput = stdout.trim()
                        console.log("Parsing JSON output (first 200 chars):", jsonOutput.substring(0, 200))
                        
                        // Parse calendar list first (this is the main output)
                        parseCalendarList(jsonOutput)
                        
                        // Wait a moment for Python script to finish writing config file, then load token
                        // The configReader will update the token asynchronously
                        // Use Timer instead of setTimeout (which doesn't exist in QML)
                        tokenLoadTimer.interval = 200 // Wait 200ms for Python to write the file
                        tokenLoadTimer.start()
                    } catch(e) {
                        console.log("Error parsing calendar list:", e)
                        console.log("Full stdout:", stdout)
                        root.statusText = "Error parsing calendar list: " + e.toString()
                    }
                } else {
                    // No output but exit code 0 - might still be processing
                    root.statusText = "Authentication completed. Loading calendar list..."
                    // Try to load from config and check for output file
                    loadAccessTokenFromConfig()
                    if (fullRepresentation && fullRepresentation.oauthOutputTimerInstance) {
                        fullRepresentation.oauthOutputTimerInstance.start()
                    }
                }
            } else {
                // Error occurred - show stderr if available, otherwise generic message
                var errorMsg = stderr.trim() || stdout.trim() || "Unknown error"
                
                // Extract the actual error message (skip traceback if it's too long)
                if (errorMsg.length > 200) {
                    // Try to extract the last meaningful error line
                    var lines = errorMsg.split("\n")
                    for (var i = lines.length - 1; i >= 0; i--) {
                        var line = lines[i].trim()
                        if (line && !line.includes("File \"") && !line.includes("Traceback") && 
                            !line.includes("File \"/") && !line.startsWith("  ")) {
                            errorMsg = line
                            break
                        }
                    }
                    // If still too long, truncate
                    if (errorMsg.length > 150) {
                        errorMsg = errorMsg.substring(0, 147) + "..."
                    }
                }
                
                // Check for common errors and provide helpful messages
                if (errorMsg.includes("deleted_client") || errorMsg.includes("invalid_client")) {
                    root.statusText = "OAuth client invalid. Please check credentials.json file."
                } else if (errorMsg.includes("RefreshError") || errorMsg.includes("refresh")) {
                    root.statusText = "Token expired. Re-authenticating... (this is normal)"
                    // The script should handle this automatically by removing old token
                } else if (errorMsg.includes("credentials.json")) {
                    root.statusText = "Missing credentials.json. Please add it to ~/.config/kagenda/"
                } else {
                    root.statusText = "Error: " + errorMsg
                }
                console.log("Python script error:", stderr || stdout)
            }
            // Disconnect after processing
            disconnectSource(sourceName)
        }
    }
    
    fullRepresentation: Item {
        Layout.preferredWidth: 500
        Layout.preferredHeight: 550
        Layout.minimumWidth: 400
        Layout.minimumHeight: 400
        implicitWidth: 500
        implicitHeight: 550
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                
                PlasmaComponents.Label {
                    text: "KAgenda"
                    font.bold: true
                }
                
                Item { Layout.fillWidth: true }
                
                Kirigami.Icon {
                    source: "configure"
                    width: 22
                    height: 22
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            console.log("Configure icon clicked")
                            // Open the same configuration dialog as the center "Configurar..." button
                            root.openConfiguration()
                        }
                    }
                }
                
                Kirigami.Icon {
                    source: "view-refresh"
                    width: 22
                    height: 22
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: refreshEvents()
                    }
                }
            }
            
            ListView {
                id: eventsList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: calendarModel
                spacing: 4
                
                delegate: Item {
                    width: eventsList.width
                    height: eventContent.height + 8
                    Column {
                        id: eventContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: 4
                        spacing: 4
                        PlasmaComponents.Label {
                            width: parent.width
                            text: model.title || ""
                            font.bold: true
                            wrapMode: Text.WordWrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }
                        PlasmaComponents.Label {
                            width: parent.width
                            text: (model.date || "") + " " + (model.time || "")
                            color: "#808080"
                            wrapMode: Text.WordWrap
                        }
                        PlasmaComponents.Label {
                            width: parent.width
                            visible: model.location !== ""
                            text: model.location || ""
                            color: "#808080"
                            font.pointSize: 9
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                    }
                }
            }
            
        }
        
        // Configuration modal using Popup component
        QQC2.Popup {
            id: configModalPopup
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.9, 600)
            height: Math.min(parent.height * 0.8, 350)
            modal: true
            closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside
            visible: showConfigModal
            
            onVisibleChanged: {
                if (!visible) {
                    showConfigModal = false
                }
            }
            
            background: Rectangle {
                radius: 8
                color: "#2b2b2b"
                border.color: "#555555"
                border.width: 1
                
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#2b2b2b" }
                    GradientStop { position: 1.0; color: "#1e1e1e" }
                }
            }
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                anchors.topMargin: 15
                anchors.bottomMargin: 15
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 15
                
                // Title
                RowLayout {
                    Layout.fillWidth: true
                    
                    PlasmaComponents.Label {
                        text: "KAgenda Configuration"
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
                                configModalPopup.close()
                            }
                        }
                    }
                }
                
                // OAuth Authentication Button
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    
                    PlasmaComponents.Label {
                        text: "Step 1: Authenticate with Google"
                        color: "#ffffff"
                        font.bold: true
                    }
                    
                    PlasmaComponents.Button {
                        id: oauthButton
                        Layout.fillWidth: true
                        text: {
                            if (fullRepresentation && fullRepresentation.oauthOutputTimerInstance && fullRepresentation.oauthOutputTimerInstance.running) {
                                return "Authenticating..."
                            } else {
                                return "Authenticate with Google"
                            }
                        }
                        enabled: !(fullRepresentation && fullRepresentation.oauthOutputTimerInstance && fullRepresentation.oauthOutputTimerInstance.running)
                        onClicked: {
                            root.executeOAuthScript()
                        }
                    }
                    
                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        text: statusText || ""
                        color: "#808080"
                        wrapMode: Text.WordWrap
                        visible: statusText !== ""
                    }
                }
                
                // Calendar Selection
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    
                    PlasmaComponents.Label {
                        text: "Step 2: Select Calendar:"
                        color: "#ffffff"
                    }
                    
                    QQC2.ComboBox {
                        id: calendarCombo
                        Layout.fillWidth: true
                        model: calendarListModel
                        textRole: "display"
                        enabled: calendarListModel.count > 0
                        
                        // Set placeholder text when no calendar is selected
                        displayText: {
                            if (currentIndex >= 0 && calendarListModel.count > 0) {
                                var calendar = calendarListModel.get(currentIndex)
                                return calendar.display || calendar.summary || calendar.id
                            } else if (cfg_calendarId && calendarListModel.count > 0) {
                                // Try to find and select the saved calendar
                                for (var i = 0; i < calendarListModel.count; i++) {
                                    if (calendarListModel.get(i).id === cfg_calendarId) {
                                        currentIndex = i
                                        var calendar = calendarListModel.get(i)
                                        return calendar.display || calendar.summary || calendar.id
                                    }
                                }
                                return "Select a calendar"
                            } else {
                                return "Select a calendar"
                            }
                        }
                        
                        background: Rectangle {
                            color: "#1e1e1e"
                            border.color: "#555555"
                            border.width: 1
                            radius: 4
                        }
                        
                        contentItem: Text {
                            text: calendarCombo.displayText
                            color: calendarCombo.enabled ? "#ffffff" : "#808080"
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 12
                            rightPadding: calendarCombo.indicator.width + calendarCombo.spacing
                        }
                        
                        delegate: QQC2.ItemDelegate {
                            width: calendarCombo.width
                            text: model.display || model.summary || model.id
                            background: Rectangle {
                                color: parent.hovered ? "#3a3a3a" : "transparent"
                            }
                        }
                        
                        onActivated: function(index) {
                            if (index >= 0) {
                                var calendar = calendarListModel.get(index)
                                var calendarId = calendar.id
                                
                                // Save to configuration immediately
                                plasmoid.configuration.calendarId = calendarId
                                
                                // Refresh events immediately after selection
                                if (cfg_accessToken && calendarId) {
                                    root.statusText = "Loading events for " + (calendar.summary || calendarId) + "..."
                                    // Use a small delay to ensure configuration is saved
                                    Qt.callLater(function() {
                                        root.refreshEvents()
                                    })
                                }
                            }
                        }
                        
                        // Update selection when calendarId changes or when calendars are loaded
                        Component.onCompleted: {
                            updateSelection()
                        }
                        
                        function updateSelection() {
                            if (cfg_calendarId && calendarListModel.count > 0) {
                                for (var i = 0; i < calendarListModel.count; i++) {
                                    if (calendarListModel.get(i).id === cfg_calendarId) {
                                        currentIndex = i
                                        return
                                    }
                                }
                            }
                            // If no match found, set to -1 to show placeholder
                            if (currentIndex < 0 || currentIndex >= calendarListModel.count) {
                                currentIndex = -1
                            }
                        }
                    }
                    
                    // Watch for calendarId changes to update selection
                    Connections {
                        target: root
                        function onCfg_calendarIdChanged() {
                            if (calendarCombo) {
                                calendarCombo.updateSelection()
                            }
                        }
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
                            configModalPopup.close()
                        }
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    PlasmaComponents.Button {
                        text: "Save"
                        Layout.preferredWidth: 80
                        onClicked: {
                            if (plasmoid && plasmoid.configuration) {
                                // Save configuration
                                // Access token is already saved automatically after authentication
                                plasmoid.configuration.calendarId = (calendarCombo.currentIndex >= 0 ? calendarListModel.get(calendarCombo.currentIndex).id : "")
                                
                                // Trigger refresh in parent
                                if (root && typeof root.refreshEvents === 'function') {
                                    root.refreshEvents()
                                }
                                
                                // Close modal
                                configModalPopup.close()
                            }
                        }
                    }
                }
            }
            
            
            // Timer to check for OAuth completion
            property alias oauthOutputTimer: oauthOutputTimerInstance
            Timer {
                id: oauthOutputTimerInstance
                interval: 1000
                repeat: true
                running: false
                
                onTriggered: {
                    var homeDir = root.getHomeDir()
                    
                    // Check for output file from wrapper script
                    var outputFile = "file://" + homeDir + "/.local/share/plasma/plasmoids/com.github.kagenda/oauth-output.json"
                    var request = new XMLHttpRequest()
                    request.open("GET", outputFile, false)
                    request.send()
                    
                    if (request.status === 200 && request.responseText.trim()) {
                        try {
                            // Parse the calendar list JSON
                            var calendarData = JSON.parse(request.responseText.trim())
                            parseCalendarList(request.responseText.trim())
                            
                            // Load access token from config
                            loadAccessTokenFromConfig()
                            
                            statusText = "Authentication successful! " + calendarListModel.count + " calendar(s) loaded."
                            running = false
                        } catch(e) {
                            console.log("Error parsing output:", e)
                        }
                    }
                    
                    // Also check config file directly as fallback
                    var configPath = "file://" + homeDir + "/.config/kagenda/config.json"
                    var configRequest = new XMLHttpRequest()
                    configRequest.open("GET", configPath, false)
                    configRequest.send()
                    
                    if (configRequest.status === 200) {
                        try {
                            var config = JSON.parse(configRequest.responseText)
                            if (config.access_token) {
                                plasmoid.configuration.accessToken = config.access_token
                            }
                        } catch(e) {
                            console.log("Error:", e)
                        }
                    }
                }
            }
        }
    }
    
    Component.onCompleted: {
        // Check if we have configuration
        if (cfg_accessToken && cfg_calendarId) {
            statusText = "Loading events..."
            refreshEvents()
        } else {
            statusText = "Please configure the widget"
            // Open configuration popup automatically if not authenticated
            if (!cfg_accessToken) {
                Qt.callLater(function() {
                    root.showConfigModal = true
                })
            }
        }
    }
    
    // Timer to load token after OAuth authentication
    Timer {
        id: tokenLoadTimer
        interval: 200
        repeat: false
        onTriggered: {
            // Load access token from config file (saved by Python script)
            loadAccessTokenFromConfig()
            
            // Wait a bit more for the config reader to finish, then update status
            tokenStatusTimer.interval = 300 // Wait 300ms for configReader to finish
            tokenStatusTimer.start()
        }
    }
    
    // Timer to update status after token is loaded
    Timer {
        id: tokenStatusTimer
        interval: 300
        repeat: false
        onTriggered: {
            root.statusText = "Authentication successful! " + calendarListModel.count + " calendar(s) loaded."
            
            // Open configuration popup automatically after authentication
            // This allows user to select a calendar
            if (!cfg_calendarId || cfg_calendarId === "") {
                root.showConfigModal = true
            }
        }
    }
    
    // Timer to refresh after configuration changes (with delay to ensure save is complete)
    Timer {
        id: refreshTimer
        interval: 500
        repeat: false
        onTriggered: {
            if (cfg_accessToken && cfg_calendarId) {
                refreshEvents()
            }
        }
    }
    
    // Watch for configuration changes - use a Timer to check periodically
    Timer {
        id: configCheckTimer
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            var hasToken = cfg_accessToken && cfg_accessToken.length > 0
            var hasCalendar = cfg_calendarId && cfg_calendarId.length > 0
            
            if (hasToken && hasCalendar) {
                if (statusText === "Please configure the widget" || statusText === "Please configure the widget (click Configure button)") {
                    refreshEvents()
                }
            }
        }
    }
}









