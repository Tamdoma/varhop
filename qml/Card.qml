import QtQuick

// Card content: a fixed header above the active view. Owns view routing and
// the draft so a header click, header Enter and the shortcut call the same
// function. Plain QtQuick; the plugin root feeds data in and handles I/O
// through the emitted signals. Ctrl+Tab moves focus between body and header.
FocusScope {
    id: card

    property QtObject theme
    property QtObject tokens
    property var library: ({prompts: []})
    property var rows: []
    property bool retainSelection: false
    property var selection: null
    property string libraryMismatch: ""
    property var syncStatus: ({})
    property var repos: []
    property string reposState: "ready"
    property var binds: []
    property string lastPull: ""
    property string lastError: ""
    property var loadErrors: []
    property var copier: null
    property var copyText: null

    property string view: "search"          // settings | search | editor
    property string cameFrom: ""            // view settings was opened from ("" = first run)
    property var draft: null                // {promptId, values, activeName, cursor, anchor, histories, redos}
    property var currentPrompt: null
    property var prevSearch: null           // {query, selectedId} for the editor's Back
    property string lastQuery: ""
    property string selectedId: ""          // last selected search row, survives view switches
    readonly property Item body: view === "search" ? searchLoader.item
        : view === "editor" ? editorLoader.item : settingsLoader.item
    readonly property bool settingsCloses: cameFrom === "" && !selection && !draft

    property Item _bodyFocus: null

    signal hideRequested
    signal queryEdited(string q)
    signal pullRequested
    signal repoChosen(string fullName)
    signal repoTyped(string fullName)
    signal lookupAccepted(string fullName, var repoId)
    signal syncNow
    signal resetUsage
    signal confirmReimport
    signal settingsOpened

    function route() {
        if (draft !== null) {
            var p = null
            for (var i = 0; i < library.prompts.length; i++)
                if (library.prompts[i].id === draft.promptId) { p = library.prompts[i]; break }
            if (p) {
                currentPrompt = p
                showEditor()
                return
            }
            draft = null
        }
        // A cache rejected while closed leaves libraryMismatch set; summon
        // must land on the settings recovery path, not stale search rows.
        view = !selection || libraryMismatch !== "" ? "settings" : "search"
        cameFrom = ""
    }

    // The editor loader opens the prompt on load; an editor already shown
    // reopens it so a resumed draft applies.
    function showEditor() {
        if (view === "editor" && editorLoader.item) editorLoader.item.openPrompt()
        else view = "editor"
    }

    function openPromptById(id) {
        for (var i = 0; i < library.prompts.length; i++) {
            if (library.prompts[i].id === id) {
                prevSearch = {query: lastQuery, selectedId: id}
                currentPrompt = library.prompts[i]
                view = "editor"
                return
            }
        }
    }

    function findAnother() {
        draft = editorLoader.item.captureDraft()
        if (prevSearch) {
            lastQuery = prevSearch.query || ""
            selectedId = prevSearch.selectedId || ""
            queryEdited(lastQuery)
        }
        view = "search"
    }

    function openSettings() {
        // Capture editor state before its loader destroys the item. A
        // resumed draft is re-captured too: edits made since must survive.
        if (view === "editor" && currentPrompt) draft = editorLoader.item.captureDraft()
        cameFrom = view
        view = "settings"
        settingsOpened()
    }

    function leaveSettings() {
        if (cameFrom !== "") {
            view = cameFrom
            cameFrom = ""
        } else if (selection || draft) {
            if (draft) route()
            else view = "search"
        } else hideRequested()
    }

    function captureForHide() {
        if (view === "editor" && editorLoader.item && currentPrompt && currentPrompt.names.length > 0)
            draft = editorLoader.item.captureDraft()
    }

    function back() {
        if (view === "editor") findAnother()
        else leaveSettings()
    }

    function headerHasFocus() {
        return backButton.activeFocus || settingsButton.activeFocus
    }

    function focusHeader() {
        _bodyFocus = card.Window.activeFocusItem
        if (backButton.visible) backButton.forceActiveFocus(Qt.TabFocusReason)
        else settingsButton.forceActiveFocus(Qt.TabFocusReason)
    }

    function focusBody() {
        if (_bodyFocus) _bodyFocus.forceActiveFocus()
        else if (body)
            body.forceActiveFocus()
    }

    onViewChanged: _bodyFocus = null

    Keys.onPressed: function(event) {
        var ctrl = event.modifiers === Qt.ControlModifier
        if (ctrl && event.key === Qt.Key_Tab) {
            if (headerHasFocus()) focusBody()
            else focusHeader()
            event.accepted = true
        } else if (event.key === Qt.Key_Escape && headerHasFocus()) {
            focusBody()
            event.accepted = true
        } else if (ctrl && event.key === Qt.Key_Comma) {
            if (view === "settings") leaveSettings()
            else openSettings()
            event.accepted = true
        }
    }

    Item {
        id: header
        objectName: "header"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: Math.max(backButton.implicitHeight, settingsButton.implicitHeight, headerTitle.implicitHeight)

        TextButton {
            id: backButton
            objectName: "backButton"
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            visible: card.view !== "search"
            theme: card.theme
            tokens: card.tokens
            label: card.view === "settings" && card.settingsCloses ? "Close" : "Back"
            shortcut: card.view === "editor" ? "Ctrl+P" : "Ctrl+,"
            onClicked: card.back()
        }

        Text {
            id: headerTitle
            objectName: "headerTitle"
            anchors.left: backButton.visible ? backButton.right : parent.left
            anchors.right: settingsButton.visible ? settingsButton.left : parent.right
            anchors.leftMargin: backButton.visible ? card.tokens.spacing.controlGap : 0
            anchors.rightMargin: settingsButton.visible ? card.tokens.spacing.controlGap : 0
            anchors.verticalCenter: parent.verticalCenter
            textFormat: Text.PlainText
            elide: Text.ElideLeft
            color: card.theme.menu.text
            font.family: card.tokens.font.menuFamily
            font.pixelSize: card.tokens.font.heading
            font.bold: true
            text: card.view === "search" ? "Prompts"
                : card.view === "editor" ? (card.currentPrompt ? card.currentPrompt.title : "")
                : "Settings"
        }

        TextButton {
            id: settingsButton
            objectName: "settingsButton"
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: card.view !== "settings"
            theme: card.theme
            tokens: card.tokens
            label: "Settings"
            shortcut: "Ctrl+,"
            onClicked: card.openSettings()
        }
    }

    Item {
        id: bodyArea
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: card.tokens.spacing.panelGap

        Loader {
            id: searchLoader
            anchors.fill: parent
            active: card.view === "search"
            focus: active
            sourceComponent: SearchBody {
                theme: card.theme
                tokens: card.tokens
                rows: card.rows
                draftPromptId: card.draft ? card.draft.promptId : ""
                retainSelection: card.retainSelection
                onSelectionChanged: function(id) { card.selectedId = id }
                onQueryEdited: function(q) { card.lastQuery = q; card.queryEdited(q) }
                onQueryCleared: { card.lastQuery = ""; card.queryEdited("") }
                onHideRequested: card.hideRequested()
                onAccepted: function(id) { card.openPromptById(id) }
                onResumeDraft: card.route()
                onPullRequested: card.pullRequested()
                Component.onCompleted: {
                    setQuery(card.lastQuery)
                    if (card.selectedId !== "") {
                        restoreId = card.selectedId
                        resolveSelection()
                    }
                }
            }
        }

        Loader {
            id: editorLoader
            anchors.fill: parent
            active: card.view === "editor"
            focus: active
            sourceComponent: EditorBody {
                theme: card.theme
                tokens: card.tokens
                prompt: card.currentPrompt
                draft: card.draft
                copier: card.copier
                onHideRequested: card.hideRequested()
                onFindAnother: card.findAnother()
                onPullRequested: card.pullRequested()
            }
            onLoaded: item.openPrompt()
        }

        Loader {
            id: settingsLoader
            anchors.fill: parent
            active: card.view === "settings"
            focus: active
            sourceComponent: SettingsBody {
                theme: card.theme
                tokens: card.tokens
                syncStatus: card.syncStatus
                lastPull: card.lastPull
                lastError: card.lastError
                loadErrors: card.loadErrors
                selection: card.selection
                binds: card.binds
                repos: card.repos
                reposState: card.reposState
                libraryMismatch: card.libraryMismatch
                copyText: card.copyText
                onRepoChosen: function(fullName) { card.repoChosen(fullName) }
                onRepoTyped: function(fullName) { card.repoTyped(fullName) }
                onLookupAccepted: function(fullName, repoId) { card.lookupAccepted(fullName, repoId) }
                onSyncNow: card.syncNow()
                onResetUsage: card.resetUsage()
                onBackRequested: card.leaveSettings()
                onHideRequested: card.hideRequested()
                onResumeRequested: if (card.draft) card.route()
                onConfirmReimport: card.confirmReimport()
                onPullRequested: card.pullRequested()
            }
        }
    }
}
