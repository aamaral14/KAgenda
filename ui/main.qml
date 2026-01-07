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
    
    // Empty compactRepresentation to prevent default "Configure..." button from showing
    compactRepresentation: Item {
        // Empty - we don't want a compact representation
    }
    
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    
    // Don't show the built-in "Configure..." button - we use our custom modal instead
    Plasmoid.configurationRequired: false
    
    // Function to open configuration modal
    function openConfiguration() {
        // Show our custom configuration modal using Popup
        console.log("openConfiguration called, opening popup")
        showConfigModal = true
    }
    
    // Configuration properties - these will be saved/loaded by Plasma
    property string cfg_calendarId: plasmoid.configuration.calendarId || ""
    property string cfg_accessToken: plasmoid.configuration.accessToken || ""
    property string cfg_provider: plasmoid.configuration.provider || "google"
    property string cfg_nextcloudServer: plasmoid.configuration.nextcloudServer || ""
    
    // Configuration modal
    property bool showConfigModal: false
    property bool _originalConfigRequired: false
    onShowConfigModalChanged: {
        console.log("showConfigModal changed to:", showConfigModal)
        console.log("configModalLoader.active will be:", showConfigModal)
        
        // Temporarily disable configurationRequired when modal is open to hide built-in configure button
        if (showConfigModal) {
            // Store original state
            if (!_originalConfigRequiredSet) {
                _originalConfigRequired = Plasmoid.configurationRequired
                _originalConfigRequiredSet = true
            }
            Plasmoid.configurationRequired = false
        } else {
            // Restore original state
            if (_originalConfigRequiredSet) {
                Plasmoid.configurationRequired = _originalConfigRequired
            }
        }
    }
    property bool _originalConfigRequiredSet: false
    
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
        var provider = cfg_provider || "google"
        
        // Use P5Support.DataSource to execute the Python script
        // The Python script will:
        // 1. Open browser automatically (via flow.run_local_server or OAuth callback)
        // 2. Handle OAuth callback
        // 3. Output calendar list JSON to stdout
        // 4. Save access token to config.json
        oauthExecutable.connectSource("python3 '" + scriptPath + "' " + provider)
        
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
        var provider = cfg_provider || "google"
        
        console.log("refreshEvents called:")
        console.log("  - Calendar ID:", calId)
        console.log("  - Provider:", provider)
        console.log("  - Has token:", token.length > 0)
        console.log("  - Nextcloud server:", cfg_nextcloudServer)
        
        if (!calId || !token) {
            statusText = "Please configure the widget"
            return
        }
        
        statusText = "Loading events..."
        
        var now = new Date()
        var later = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000)
        var timeMin = now.toISOString()
        var timeMax = later.toISOString()
        
        var url = ""
        var request = new XMLHttpRequest()
        
        if (provider === "google") {
            // Google Calendar API
            url = "https://www.googleapis.com/calendar/v3/calendars/" + 
                  encodeURIComponent(calId) + 
                  "/events?timeMin=" + encodeURIComponent(timeMin) + 
                  "&timeMax=" + encodeURIComponent(timeMax) + 
                  "&maxResults=50&singleEvents=true&orderBy=startTime"
            
            request.open("GET", url)
            request.setRequestHeader("Authorization", "Bearer " + token)
        } else if (provider === "nextcloud") {
            // Nextcloud Calendar API (using CalDAV REPORT)
            var serverUrl = cfg_nextcloudServer || ""
            if (!serverUrl) {
                statusText = "Nextcloud server URL not configured"
                return
            }
            
            // Normalize server URL
            serverUrl = serverUrl.replace(/\/$/, "")
            
            // Nextcloud Calendar API - try multiple endpoint formats
            // Nextcloud Calendar app may use different endpoint formats depending on version
            // Try: /apps/calendar/api/v1/calendars/{id}/events (Calendar app API)
            // Or: /index.php/apps/calendar/api/v1/calendars/{id}/events (with index.php)
            // Or: CalDAV REPORT (standard, but requires XML parsing)
            
            // Try format 1: Calendar app REST API without index.php
            url = serverUrl + "/apps/calendar/api/v1/calendars/" + encodeURIComponent(calId) + "/events"
            url += "?start=" + encodeURIComponent(timeMin) + "&end=" + encodeURIComponent(timeMax)
            
            console.log("Trying Nextcloud Calendar REST API (format 1):", url)
            
            request.open("GET", url)
            request.setRequestHeader("Authorization", "Bearer " + token)
            request.setRequestHeader("Accept", "application/json")
        } else {
            statusText = "Unknown provider: " + provider
            return
        }
        
        request.onreadystatechange = function() {
            if (request.readyState === XMLHttpRequest.DONE) {
                console.log("Event fetch response status:", request.status)
                console.log("Event fetch URL:", url)
                
                if (request.status === 200) {
                    try {
                        var response = JSON.parse(request.responseText)
                        console.log("Event fetch response (first 500 chars):", JSON.stringify(response).substring(0, 500))
                        calendarModel.clear()
                        
                        var events = []
                        
                        if (provider === "google") {
                            // Google Calendar format
                            events = response.items || []
                        } else if (provider === "nextcloud") {
                            // Nextcloud Calendar format
                            // The API might return data in different formats
                            console.log("Parsing Nextcloud events, response type:", typeof response)
                            if (response.data && Array.isArray(response.data)) {
                                events = response.data
                                console.log("Found events in response.data:", events.length)
                            } else if (Array.isArray(response)) {
                                events = response
                                console.log("Found events as direct array:", events.length)
                            } else if (response.objects) {
                                // CalDAV format
                                events = response.objects
                                console.log("Found events in response.objects:", events.length)
                            } else if (response.ocs && response.ocs.data && Array.isArray(response.ocs.data)) {
                                // OCS format
                                events = response.ocs.data
                                console.log("Found events in response.ocs.data:", events.length)
                            } else {
                                console.log("No events found in response. Response keys:", Object.keys(response))
                            }
                        }
                    
                    for (var i = 0; i < events.length; i++) {
                        var event = events[i]
                        var start, end, summary, location
                        
                        if (provider === "google") {
                            start = event.start.dateTime || event.start.date
                            end = event.end.dateTime || event.end.date
                            summary = event.summary || "No Title"
                            location = event.location || ""
                        } else if (provider === "nextcloud") {
                            // Nextcloud event format
                            if (event.dtstart) {
                                start = event.dtstart
                            } else if (event.start) {
                                start = event.start
                            } else if (event.startDate) {
                                start = event.startDate
                            }
                            
                            if (event.dtend) {
                                end = event.dtend
                            } else if (event.end) {
                                end = event.end
                            } else if (event.endDate) {
                                end = event.endDate
                            }
                            
                            summary = event.title || event.summary || event.name || "No Title"
                            location = event.location || ""
                        }
                        
                        if (!start) continue
                        
                        var startDate = new Date(start)
                        var endDate = end ? new Date(end) : startDate
                        var dateStr = startDate.toISOString().split('T')[0]
                        var timeStr = ""
                        
                        // Check if it's an all-day event (date only, no time)
                        var isAllDay = !start.includes('T') || (provider === "nextcloud" && !start.match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}/))
                        
                        if (!isAllDay && startDate) {
                            var startTime = startDate.toLocaleTimeString('en-US', {hour: '2-digit', minute: '2-digit', hour12: false})
                            var endTime = endDate.toLocaleTimeString('en-US', {hour: '2-digit', minute: '2-digit', hour12: false})
                            timeStr = startTime + " - " + endTime
                        } else {
                            timeStr = "All day"
                        }
                        
                        calendarModel.append({
                            title: summary,
                            date: dateStr,
                            time: timeStr,
                            location: location
                        })
                    }
                    
                    // Status text removed - no longer displayed
                    } catch(e) {
                        console.log("Error parsing event response:", e)
                        console.log("Response text:", request.responseText.substring(0, 500))
                        statusText = "Error parsing events: " + e.toString()
                    }
                } else if (request.status === 401) {
                    console.log("Authentication expired (401)")
                    statusText = "Authentication expired. Refreshing token..."
                    // Token expired - try to refresh by running OAuth helper
                    // The Python script will automatically refresh if refresh_token exists
                    executeOAuthScript()
                } else if (request.status === 404) {
                    console.log("404 Not Found - REST API not available, trying CalDAV via Python helper...")
                    console.log("Calendar ID:", calId)
                    
                    // XMLHttpRequest doesn't support REPORT method, use Python helper instead
                    var homeDir = getHomeDir()
                    var scriptPath = homeDir + "/.local/share/plasma/plasmoids/com.github.kagenda/oauth-helper.py"
                    var command = "python3 '" + scriptPath + "' --fetch-events '" + 
                                  serverUrl + "' '" + 
                                  calId + "' '" + 
                                  token + "' '" + 
                                  timeMin + "' '" + 
                                  timeMax + "'"
                    
                    console.log("Calling Python helper for CalDAV events...")
                    caldavEventFetcher.connectSource(command)
                    return // Don't show error message yet, wait for Python response
                } else {
                    console.log("Error loading events - Status:", request.status)
                    console.log("Response text:", request.responseText.substring(0, 500))
                    statusText = "Error loading events: " + request.status + " - " + (request.responseText.substring(0, 100) || "Unknown error")
                }
            }
        }
        
        request.send()
    }
    
    // DataSource for fetching CalDAV events via Python helper
    P5Support.DataSource {
        id: caldavEventFetcher
        engine: "executable"
        connectedSources: []
        
        onNewData: function(sourceName, data) {
            var exitCode = data["exit code"] || 0
            var stdout = data.stdout || ""
            var stderr = data.stderr || ""
            
            console.log("CalDAV event fetcher finished. Exit code:", exitCode)
            
            if (exitCode === 0 && stdout && stdout.trim()) {
                try {
                    var response = JSON.parse(stdout.trim())
                    console.log("CalDAV events response:", JSON.stringify(response).substring(0, 500))
                    calendarModel.clear()
                    
                    var events = response.items || []
                    console.log("Found", events.length, "events from CalDAV")
                    
                    for (var i = 0; i < events.length; i++) {
                        var event = events[i]
                        var start = event.start
                        var end = event.end
                        var summary = event.summary || "No Title"
                        var location = event.location || ""
                        
                        if (!start) continue
                        
                        // Parse iCalendar date format (YYYYMMDDTHHMMSSZ or YYYYMMDD)
                        var startDate, endDate
                        if (start.length === 8) {
                            // All-day event (YYYYMMDD)
                            startDate = new Date(start.substring(0,4), parseInt(start.substring(4,6))-1, start.substring(6,8))
                            endDate = end && end.length === 8 ? new Date(end.substring(0,4), parseInt(end.substring(4,6))-1, end.substring(6,8)) : startDate
                        } else if (start.length >= 15) {
                            // Date-time (YYYYMMDDTHHMMSSZ)
                            var year = start.substring(0,4)
                            var month = parseInt(start.substring(4,6)) - 1
                            var day = start.substring(6,8)
                            var hour = start.substring(9,11) || 0
                            var minute = start.substring(11,13) || 0
                            var second = start.substring(13,15) || 0
                            startDate = new Date(Date.UTC(year, month, day, hour, minute, second))
                            
                            if (end && end.length >= 15) {
                                var endYear = end.substring(0,4)
                                var endMonth = parseInt(end.substring(4,6)) - 1
                                var endDay = end.substring(6,8)
                                var endHour = end.substring(9,11) || 0
                                var endMinute = end.substring(11,13) || 0
                                var endSecond = end.substring(13,15) || 0
                                endDate = new Date(Date.UTC(endYear, endMonth, endDay, endHour, endMinute, endSecond))
                            } else {
                                endDate = startDate
                            }
                        } else {
                            continue
                        }
                        
                        var dateStr = startDate.toISOString().split('T')[0]
                        var timeStr = ""
                        var isAllDay = start.length === 8
                        
                        if (!isAllDay && startDate) {
                            var startTime = startDate.toLocaleTimeString('en-US', {hour: '2-digit', minute: '2-digit', hour12: false})
                            var endTime = endDate.toLocaleTimeString('en-US', {hour: '2-digit', minute: '2-digit', hour12: false})
                            timeStr = startTime + " - " + endTime
                        } else {
                            timeStr = "All day"
                        }
                        
                        calendarModel.append({
                            title: summary,
                            date: dateStr,
                            time: timeStr,
                            location: location
                        })
                    }
                    
                    console.log("Loaded", calendarModel.count, "events from CalDAV")
                    statusText = "Loaded " + calendarModel.count + " events"
                } catch(e) {
                    console.log("Error parsing CalDAV events:", e)
                    statusText = "Error parsing CalDAV events: " + e.toString()
                }
            } else {
                console.log("CalDAV fetch error:", stderr)
                statusText = "Failed to fetch events: " + (stderr || "Unknown error")
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
                            // Save to plasmoid configuration
                            plasmoid.configuration.accessToken = config.access_token
                            if (config.provider) {
                                plasmoid.configuration.provider = config.provider
                            }
                            if (config.nextcloud_server) {
                                plasmoid.configuration.nextcloudServer = config.nextcloud_server
                            }
                            console.log("Access token loaded and saved to configuration:", config.access_token.substring(0, 20) + "...")
                            
                            // Wait a moment for the property binding to update, then check if we can refresh events
                            // Use a timer to ensure cfg_accessToken property has updated
                            tokenLoadedTimer.start()
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
            visible: !showConfigModal
            
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
        
        // Configuration modal using Loader
        Loader {
            id: configModalLoader
            active: showConfigModal
            source: "ConfigModal.qml"
            anchors.fill: parent
            
            onLoaded: {
                if (item) {
                    item.plasmoidRef = plasmoid
                    item.rootRef = root
                    item.onClose = function() {
                        root.showConfigModal = false
                    }
                }
            }
        }
        
        // Timer to check for OAuth completion (kept for backward compatibility)
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
                        root.parseCalendarList(request.responseText.trim())
                        
                        // Load access token from config
                        root.loadAccessTokenFromConfig()
                        
                        root.statusText = "Authentication successful! " + root.calendarListModel.count + " calendar(s) loaded."
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
                        var config = JSON.parse(configRequest.responseText.trim())
                        if (config.access_token) {
                            plasmoid.configuration.accessToken = config.access_token
                            if (config.provider) {
                                plasmoid.configuration.provider = config.provider
                            }
                            if (config.nextcloud_server) {
                                plasmoid.configuration.nextcloudServer = config.nextcloud_server
                            }
                            running = false
                        }
                    } catch(e) {
                        console.log("Error parsing config:", e)
                    }
                }
            }
        }
    }
    
    Component.onCompleted: {
        console.log("Component.onCompleted: Starting initialization...")
        console.log("Current cfg_accessToken:", cfg_accessToken ? cfg_accessToken.substring(0, 20) + "..." : "empty")
        console.log("Current cfg_calendarId:", cfg_calendarId || "empty")
        console.log("Current plasmoid.configuration.accessToken:", plasmoid.configuration.accessToken ? plasmoid.configuration.accessToken.substring(0, 20) + "..." : "empty")
        console.log("Current plasmoid.configuration.calendarId:", plasmoid.configuration.calendarId || "empty")
        
        // First, check if we already have configuration saved (from previous session)
        // Plasma configuration persists across restarts, so check that first
        var hasToken = plasmoid.configuration.accessToken && plasmoid.configuration.accessToken.length > 0
        var hasCalendar = plasmoid.configuration.calendarId && plasmoid.configuration.calendarId.length > 0
        
        if (hasToken && hasCalendar) {
            console.log("Found saved configuration, refreshing events immediately...")
            statusText = "Loading events..."
            // Use a small delay to ensure everything is initialized
            Qt.callLater(function() {
                refreshEvents()
            })
        } else {
            // No saved configuration, try to load from config file
            console.log("No saved configuration found, loading from config file...")
            loadAccessTokenFromConfig()
            
            // Use a timer to wait for the config file to be read asynchronously
            // Then check if we have configuration
            Qt.callLater(function() {
                // Give configReader time to load the token (it's async)
                startupTimer.start()
            })
        }
    }
    
    // Timer to check configuration after startup token load
    Timer {
        id: startupTimer
        interval: 1500
        repeat: false
        onTriggered: {
            console.log("startupTimer triggered")
            // Check if we have configuration (token might have been loaded from config file)
            // Use plasmoid.configuration directly for more reliable checking
            var hasToken = plasmoid.configuration.accessToken && plasmoid.configuration.accessToken.length > 0
            var hasCalendar = plasmoid.configuration.calendarId && plasmoid.configuration.calendarId.length > 0
            
            console.log("startupTimer: hasToken:", hasToken, "hasCalendar:", hasCalendar)
            
            if (hasToken && hasCalendar) {
                console.log("startupTimer: Both token and calendar found, refreshing events...")
                statusText = "Loading events..."
                refreshEvents()
            } else if (hasToken && !hasCalendar) {
                // We have token but no calendar selected - open config to select calendar
                console.log("startupTimer: Token found but no calendar selected")
                statusText = "Please select a calendar"
                Qt.callLater(function() {
                    root.showConfigModal = true
                })
            } else {
                console.log("startupTimer: No configuration found")
                statusText = "Please configure the widget"
                // Open configuration popup automatically if not authenticated
                Qt.callLater(function() {
                    root.showConfigModal = true
                })
            }
        }
    }
    
    // Timer to refresh events after token is loaded from config file
    Timer {
        id: tokenLoadedTimer
        interval: 500
        repeat: false
        onTriggered: {
            console.log("tokenLoadedTimer triggered")
            // Check if we have both token and calendar ID after loading token from config
            // Use plasmoid.configuration directly to avoid timing issues with property bindings
            var hasToken = plasmoid.configuration.accessToken && plasmoid.configuration.accessToken.length > 0
            var hasCalendar = plasmoid.configuration.calendarId && plasmoid.configuration.calendarId.length > 0
            
            console.log("tokenLoadedTimer: hasToken:", hasToken, "hasCalendar:", hasCalendar)
            
            if (hasToken && hasCalendar) {
                console.log("tokenLoadedTimer: Both token and calendar found, refreshing events...")
                statusText = "Loading events..."
                refreshEvents()
            } else if (hasToken && !hasCalendar) {
                console.log("tokenLoadedTimer: Token loaded but no calendar selected")
                statusText = "Please select a calendar"
            } else {
                console.log("tokenLoadedTimer: Token or calendar missing")
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









