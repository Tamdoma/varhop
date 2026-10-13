import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons as Commons
import qs.Ui
import "qml"
import "lib/import.mjs" as Imp
import "lib/search.mjs" as Sea
import "lib/usage.mjs" as Use
import "lib/fold.mjs" as Fold

// ivan.varhop overlay plugin root. Owns the OverlayWindow, view routing, the
// draft, shell.json selection I/O, varhop-sync process flow and the usage
// state file. Views stay Quickshell-free so qmltestrunner can load them.
Item {
    id: root

    property string omarchyPath: Quickshell.env("OMARCHY_PATH") || ""
    property var shell: null
    property var manifest: null

    // ---- state ------------------------------------------------------------
    property bool opened: false
    property string view: "search"          // settings | search | editor
    property string cameFrom: ""            // view settings was opened from ("" = first run)
    property var selection: null            // {repo,login,accountId,repoId} or null
    property var library: ({prompts: [], errors: []})
    property var bundle: null               // last accepted library.json
    property var loadErrors: []
    property var syncStatus: ({})
    property var repos: []
    property var binds: []
    property string lastError: ""
    property string lastPull: ""
    property string libraryMismatch: ""
    property string usageError: ""
    property var usage: Use.resetUsage()
    property var draft: null                // {promptId,values,activeName,cursor,selection}
    property var prevSearch: null           // {query, selectedId} for Ctrl+P return
    property var currentPrompt: null
    property var rows: []
    property int syncGen: 0
    property int pendingGen: 0
    property var pendingSync: null          // {fullName, repoChange, accountId, repoId, staged}
    property var pendingSave: null          // selection object awaiting read-back
    property var pendingMismatch: null      // {actualAccountId, actualRepoId}
    property bool syncing: false
    property real lastKeyAt: 0
    property bool firstFramePending: false

    // ---- colors -------------------------------------------------------------
    function col(name) { return Commons.Color[name] }
    property var colors: ({
        foreground: Commons.Color.foreground,
        muted: Commons.Color.muted,
        accent: Commons.Color.accent,
        urgent: Commons.Color.urgent,
        selectedBackground: Commons.Color.menu.selectedBackground,
        selectedText: Commons.Color.menu.selectedText,
        border: Commons.Color.menu.border
    })

    // ---- paths ---------------------------------------------------------------
    readonly property string homePath: Quickshell.env("HOME")
    readonly property string configPath: homePath + "/.config/omarchy/shell.json"
    readonly property string cachePath: homePath + "/.cache/varhop"
    readonly property string libraryPath: cachePath + "/library.json"
    readonly property string stateDir: homePath + "/.local/state/varhop"
    property string usagePath: ""
    readonly property string syncBin: {
        var dir = manifest && manifest.__sourceDir ? manifest.__sourceDir : ""
        return dir !== "" ? dir + "/bin/varhop-sync" : "varhop-sync"
    }

    // ---- helpers --------------------------------------------------------------
    function pluginEntry(config) {
        var arr = config && config.plugins
        if (!Array.isArray(arr)) return null
        for (var i = 0; i < arr.length; i++)
            if (arr[i] && arr[i].id === "ivan.varhop") return arr[i]
        return null
    }

    function parseConfig(text) {
        var parsed = null
        try { parsed = JSON.parse(text) } catch (e) { parsed = null }
        var entry = pluginEntry(parsed)
        if (entry && entry.repo) {
            selection = {repo: entry.repo, login: entry.login, accountId: entry.accountId, repoId: entry.repoId}
        } else {
            selection = null
        }
        usagePath = selection ? stateDir + "/usage-" + selection.repoId + ".json" : ""
    }

    onUsagePathChanged: usageFile.reload()

    function importBundle(text) {
        // Accept only a bundle whose repoId equals the saved selection.
        var b = null
        try { b = JSON.parse(text) } catch (e) { b = null }
        if (!b) { libraryMismatch = "library.json is unreadable"; return null }
        if (!selection || String(b.repoId) !== String(selection.repoId)) {
            libraryMismatch = "cached library belongs to a different repo (" +
                (b.repo || "?") + " id " + b.repoId + "); pick Sync now"
            return null
        }
        libraryMismatch = ""
        var out = Imp.importLibrary(b.files || [])
        library = out
        var errs = []
        for (var i = 0; i < (b.errors || []).length; i++) {
            var be = b.errors[i]
            errs.push({kind: "bundle", path: be.path || "?", line: null, message: be.message || "?"})
        }
        for (var j = 0; j < out.errors.length; j++) {
            var pe = out.errors[j]
            errs.push({kind: "prompt", path: pe.path || "?", line: pe.line, message: pe.message || "?"})
        }
        loadErrors = errs
        bundle = b
        lastPull = b.fetchedAt ? new Date(b.fetchedAt).toISOString().slice(0, 16).replace("T", " ") : ""
        if (b.status === "empty-repo") { lastError = "repo has no prompts" }
        if (b.status === "no-prompts") { lastError = "repo has no prompts/ directory" }
        rebuildRows("")
        return b
    }

    function fileNameStem(id) {
        var base = id.slice(id.lastIndexOf("/") + 1)
        return base
    }

    function rebuildRows(query) {
        var ranked = Sea.rank(library.prompts, query, usage, Date.now())
        var out = []
        for (var i = 0; i < ranked.length; i++) {
            var p = null
            for (var k = 0; k < library.prompts.length; k++)
                if (library.prompts[k].id === ranked[i].id) { p = library.prompts[k]; break }
            if (!p) continue
            var cat = p.subcategory ? p.category + " / " + p.subcategory : p.category
            var detail = cat + (p.description ? " — " + p.description : "")
            var stem = fileNameStem(p.id)
            var showFile = Fold.fold(p.title).indexOf(Fold.fold(stem.replace(/\.md$/, ""))) === -1
            out.push({
                id: p.id, title: p.title, detail: detail,
                fileName: showFile ? stem : "",
                draft: draft !== null && draft.promptId === p.id,
                snippet: ranked[i].snippet || ""
            })
        }
        rows = out
    }

    function refreshStatus() {
        if (!statusProc.running) statusProc.running = true
    }

    function refreshRepos() {
        if (!reposProc.running) reposProc.running = true
    }

    function refreshBinds() {
        if (!bindsProc.running) bindsProc.running = true
    }

    function route() {
        console.log("varhop-view " + view + " sel=" + (selection ? selection.repo : "none") + " draft=" + (draft ? draft.promptId : "none"))
        if (draft !== null) {
            var p = null
            for (var i = 0; i < library.prompts.length; i++)
                if (library.prompts[i].id === draft.promptId) { p = library.prompts[i]; break }
            if (p) { currentPrompt = p; view = "editor"; editorLoader.item.openPrompt(); return }
            draft = null
        }
        if (!selection) view = "settings"
        else view = "search"
        cameFrom = ""
    }

    // ---- shell API ------------------------------------------------------------
    function open(payloadJson) {
        opened = true
        route()
        console.log("varhop-view " + view)
        refreshStatus()
        if (!selection) refreshRepos()
        refreshBinds()
        rebuildRows(searchLoader.item ? searchLoader.item.query : "")
        if (view === "editor" && editorLoader.item) editorLoader.item.openPrompt()
    }

    function close() {
        if (view === "editor" && editorLoader.item && draft === null && currentPrompt) {
            // Keep an in-progress edit as the draft.
            if (currentPrompt.names.length > 0) draft = editorLoader.item.captureDraft()
        }
        opened = false
    }

    function hide() {
        close()
        if (shell && typeof shell.hide === "function")
            shell.hide(manifest && manifest.id ? manifest.id : "ivan.varhop")
        else
            opened = false
    }

    function toggle() { opened ? hide() : open("{}") }

    // ---- sync flow -------------------------------------------------------------
    property var repoRe: new RegExp("^[A-Za-z0-9][A-Za-z0-9-]{0,38}/[A-Za-z0-9._-]{1,100}$")

    function startSync(fullName, opts) {
        // opts: {expect:{accountId,repoId}|null, repoChange:bool}
        if (syncing) { lastError = "a sync is already running"; return }
        syncing = true
        lastError = ""
        syncGen += 1
        pendingGen = syncGen
        pendingSync = {fullName: fullName, repoChange: !!(opts && opts.repoChange), staged: ""}
        var cmd = [syncBin, "sync", fullName, cachePath, "--generation", String(syncGen)]
        if (opts && opts.expect)
            cmd = cmd.concat(["--expect-account", String(opts.expect.accountId), "--expect-repo", String(opts.expect.repoId)])
        syncProc.command = cmd
        syncProc.running = true
    }

    function chooseRepo(fullName, expect) {
        // Choosing a different repo warns when a draft exists.
        if (draft !== null && selection && fullName !== selection.repo) {
            libraryMismatch = "reconfirm: switching repos discards the current draft"
            pendingMismatch = {fullName: fullName, expect: expect || null}
            view = "settings"
            return
        }
        startSync(fullName, {expect: expect || null, repoChange: true})
    }

    function saveSelection(entry) {
        pendingSave = entry
        if (!shell || typeof shell.updateEntryInline !== "function") {
            lastError = "no shell api"
            pendingSave = null
            return false
        }
        shell.updateEntryInline("ivan.varhop", {
            repo: entry.repo, login: entry.login,
            accountId: entry.accountId, repoId: entry.repoId
        })
        configFile.reload()
        return true
    }

    function confirmSaved(entry) {
        // Called after configFile reloads: verify the write landed.
        if (!pendingSave) return false
        if (!selection || selection.repo !== pendingSave.repo
            || String(selection.accountId) !== String(pendingSave.accountId)
            || String(selection.repoId) !== String(pendingSave.repoId)) return false
        pendingSave = null
        return true
    }

    function acceptStaged() {
        if (!pendingSync || pendingSync.staged === "") return
        acceptProc.command = [syncBin, "accept", cachePath, String(pendingGen)]
        acceptProc.running = true
    }

    function finishSync() {
        // Accept landed: swap the in-memory library with the staged bundle.
        if (!pendingSync || pendingSync.staged === "") { syncing = false; return }
        var stagedPath = pendingSync.staged
        var wasRepoChange = pendingSync.repoChange
        pendingSync = null
        syncing = false
        if (wasRepoChange) draft = null   // confirmed switch discards the draft
        libraryFile.path = stagedPath
        libraryFile.reload()
        usagePath = selection ? stateDir + "/usage-" + selection.repoId + ".json" : ""
        rebuildRows(searchLoader.item ? searchLoader.item.query : "")
    }

    function failSync(msg) {
        syncing = false
        pendingSync = null
        pendingSave = null
        lastError = msg
    }

    // ---- usage -----------------------------------------------------------------
    function recordUsage(promptId) {
        usage = Use.recordCopy(usage, promptId, Date.now())
        usageFile.blockWrites = false
        usageFile.setText(JSON.stringify(usage))
    }

    // ---- FileViews ---------------------------------------------------------------
    FileView {
        id: configFile
        path: root.configPath
        watchChanges: true
        printErrors: false
        onLoaded: {
            root.parseConfig(text())
            if (root.confirmSaved(root.pendingSave)) {
                root.acceptStaged()
            }
        }
        onLoadFailed: root.parseConfig("")
        onFileChanged: reload()
    }

    FileView {
        id: libraryFile
        path: root.libraryPath
        watchChanges: false
        printErrors: false
        onLoaded: {
            var accepted = root.importBundle(text())
            // path returns to the stable library location after a staged read.
            if (libraryFile.path !== root.libraryPath) libraryFile.path = root.libraryPath
        }
        onLoadFailed: {
            if (libraryFile.path !== root.libraryPath) libraryFile.path = root.libraryPath
            root.library = ({prompts: [], errors: []})
            root.loadErrors = []
            root.rebuildRows("")
        }
    }

    FileView {
        id: usageFile
        path: root.usagePath
        watchChanges: true
        atomicWrites: true
        printErrors: false
        onLoaded: {
            var r = Use.parseUsage(text())
            if (r.state !== undefined) { root.usage = r.state; root.usageError = "" }
            else root.usageError = "usage file unreadable: " + r.error
            root.rebuildRows(searchLoader.item ? searchLoader.item.query : "")
        }
        onLoadFailed: { root.usage = Use.resetUsage(); root.rebuildRows("") }
        onSaved: root.usageError = ""
        onSaveFailed: function(error) { root.usageError = "usage write failed (" + error + ")" }
        onFileChanged: reload()
    }

    // ---- processes -------------------------------------------------------------
    Process {
        id: statusProc
        command: [root.syncBin, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.syncStatus = JSON.parse(text) } catch (e) { root.syncStatus = ({}) }
            }
        }
        onExited: function(code) { if (code !== 0) root.syncStatus = ({authenticated: false, fix: "gh auth login"}) }
    }

    Process {
        id: reposProc
        command: [root.syncBin, "repos"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.repos = JSON.parse(text).repos || [] } catch (e) { root.repos = [] }
            }
        }
        onExited: function(code) { if (code !== 0) root.repos = [] }
    }

    Process {
        id: repoProc
        property string typed: ""
        command: [root.syncBin, "repo", repoProc.typed]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var r = JSON.parse(text)
                    if (r.fullName) root.chooseRepo(r.fullName, {accountId: r.accountId, repoId: r.id})
                } catch (e) { root.lastError = "repo lookup failed" }
            }
        }
        onExited: function(code) { if (code !== 0) root.lastError = "repo lookup failed" }
    }

    Process {
        id: bindsProc
        command: ["bash", "-c", "hyprctl binds -j 2>/dev/null | tr -d '\\000'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.binds = JSON.parse(text) } catch (e) { root.binds = [] }
            }
        }
        onExited: function(code) { if (code !== 0) root.binds = [] }
    }

    Process {
        id: syncProc
        stdout: StdioCollector {
            onStreamFinished: {
                try { syncProc.lastOut = JSON.parse(text) } catch (e) { syncProc.lastOut = null }
            }
        }
        property var lastOut: null
        onExited: function(code, status) {
            var gen = root.pendingGen
            var out = lastOut
            if (code === 0 && out) {
                if (gen !== root.syncGen) { root.syncing = false; return }  // stale
                if (out.status === "empty-repo" || out.status === "no-prompts") {
                    root.failSync(out.status === "empty-repo" ? "repo is empty" : "repo has no prompts/")
                    return
                }
                root.pendingSync.staged = out.staged || ""
                if (root.pendingSync.repoChange) {
                    var entry = {repo: out.repo, login: out.login, accountId: out.accountId, repoId: out.repoId}
                    if (!root.saveSelection(entry)) { root.failSync("save failed"); return }
                    // configFile's onLoaded/onFileChanged drives confirmSaved → acceptStaged.
                    if (root.confirmSaved(entry)) root.acceptStaged()
                } else {
                    root.acceptStaged()
                }
            } else if (code === 5 && out && out.actual) {
                root.syncing = false
                root.pendingMismatch = {fullName: root.pendingSync ? root.pendingSync.fullName : "",
                                        actual: out.actual}
                root.libraryMismatch = "reconfirm: account " + out.actual.accountId + " / repo " + out.actual.repoId + " differs from the saved selection"
                root.view = "settings"
                root.pendingSync = null
            } else {
                var msg = out && out.message ? out.message : ("sync failed (exit " + code + ")")
                root.failSync(msg)
            }
        }
    }

    Process {
        id: acceptProc
        stdout: StdioCollector { onStreamFinished: {} }
        onExited: function(code) {
            if (code === 0) root.finishSync()
            else root.failSync("accept failed (exit " + code + ")")
        }
    }

    Process {
        id: mkdirProc
        command: ["mkdir", "-p", root.stateDir]
        onExited: usageFile.reload()
    }

    Copier {
        id: copier
        onSucceeded: {
            if (root.currentPrompt) root.recordUsage(root.currentPrompt.id)
            root.draft = null
            root.hide()
        }
        onFailed: function(reason) { root.lastError = reason }
    }

    Copier {
        id: bindCopier
    }

    Component.onCompleted: {
        mkdirProc.running = true
        refreshStatus()
    }

    // ---- overlay ----------------------------------------------------------------
    OverlayWindow {
        id: panel
        shown: root.opened
        WlrLayershell.namespace: "varhop"

        // First frame after a keystroke: log the search latency pair.
        FrameAnimation {
            running: root.opened
            onTriggered: {
                if (root.firstFramePending && root.lastKeyAt > 0) {
                    root.firstFramePending = false
                    console.log("varhop-search " + JSON.stringify({key: root.lastKeyAt, frame: Date.now()}))
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Commons.Color.menu.scrim
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.hide()
        }

        Rectangle {
            id: card
            width: Math.min(560, panel.width - 40)
            height: Math.min(480, panel.height - 40)
            anchors.centerIn: parent
            radius: 6
            color: Commons.Color.menu.background
            border.color: Commons.Color.menu.border
            border.width: 1

            MouseArea { anchors.fill: parent; onClicked: {} }

            Item {
                anchors.fill: parent
                anchors.margins: 16
                focus: true

                Keys.onPressed: function(event) {
                    var v = root.view === "search" ? searchLoader.item
                        : root.view === "editor" ? editorLoader.item
                        : settingsLoader.item
                    if (v && v.handleKey) v.handleKey(event)
                    if (event.accepted) return
                    if (event.key === Qt.Key_Comma && event.modifiers === Qt.ControlModifier) {
                        if (root.view === "settings") {
                            root.view = root.cameFrom === "" ? "search" : root.cameFrom
                            if (root.cameFrom === "" && !root.selection) root.view = "settings"
                            root.cameFrom = ""
                        } else {
                            root.cameFrom = root.view
                            root.view = "settings"
                            root.refreshRepos()
                        }
                        event.accepted = true
                    }
                }

                Loader {
                    id: searchLoader
                    anchors.fill: parent
                    active: root.view === "search"
                    source: "qml/SearchBody.qml"
                    onLoaded: {
                        item.rows = Qt.binding(function() { return root.rows })
                        item.draftPromptId = Qt.binding(function() { return root.draft ? root.draft.promptId : "" })
                        item.colors = root.colors
                        item.queryEdited.connect(function(q) {
                            root.lastKeyAt = item.keyTime
                            root.firstFramePending = true
                            root.rebuildRows(q)
                        })
                        item.queryCleared.connect(function() { root.rebuildRows("") })
                        item.hideRequested.connect(root.hide)
                        item.accepted.connect(function(id) {
                            for (var i = 0; i < root.library.prompts.length; i++) {
                                if (root.library.prompts[i].id === id) {
                                    root.prevSearch = {query: item.query, selectedId: id}
                                    root.currentPrompt = root.library.prompts[i]
                                    root.view = "editor"
                                    Qt.callLater(function() { if (editorLoader.item) editorLoader.item.openPrompt() })
                                    break
                                }
                            }
                        })
                        item.resumeDraft.connect(function() { root.route() })
                        item.pullRequested.connect(function() {
                            if (root.selection) root.startSync(root.selection.repo, {expect: {accountId: root.selection.accountId, repoId: root.selection.repoId}})
                        })
                    }
                }

                Loader {
                    id: editorLoader
                    anchors.fill: parent
                    active: root.view === "editor"
                    source: "qml/EditorBody.qml"
                    onLoaded: {
                        item.prompt = Qt.binding(function() { return root.currentPrompt })
                        item.draft = Qt.binding(function() { return root.draft })
                        item.copier = copier
                        item.colors = root.colors
                        item.copyRequested.connect(function() {})
                        item.hideRequested.connect(root.hide)
                        item.findAnother.connect(function() {
                            root.draft = item.captureDraft()
                            root.view = "search"
                            if (root.prevSearch) root.rebuildRows(root.prevSearch.query)
                            Qt.callLater(function() {
                                if (searchLoader.item) {
                                    searchLoader.item.query = root.prevSearch ? root.prevSearch.query : ""
                                    var f = searchLoader.item.children[0]
                                }
                            })
                        })
                        item.pullRequested.connect(function() {
                            if (root.selection) root.startSync(root.selection.repo, {expect: {accountId: root.selection.accountId, repoId: root.selection.repoId}})
                        })
                    }
                }

                Loader {
                    id: settingsLoader
                    anchors.fill: parent
                    active: root.view === "settings"
                    source: "qml/SettingsBody.qml"
                    onLoaded: {
                        item.syncStatus = Qt.binding(function() { return root.syncStatus })
                        item.lastPull = Qt.binding(function() { return root.lastPull })
                        item.lastError = Qt.binding(function() { return root.lastError + (root.usageError ? " · " + root.usageError : "") })
                        item.loadErrors = Qt.binding(function() { return root.loadErrors })
                        item.selection = Qt.binding(function() { return root.selection })
                        item.binds = Qt.binding(function() { return root.binds })
                        item.repos = Qt.binding(function() { return root.repos })
                        item.libraryMismatch = Qt.binding(function() { return root.libraryMismatch })
                        item.colors = root.colors
                        item.copyText = function(t) { bindCopier.copy(t) }
                        item.repoChosen.connect(function(fullName) {
                            var r = null
                            for (var i = 0; i < root.repos.length; i++)
                                if (root.repos[i].fullName === fullName) { r = root.repos[i]; break }
                            root.chooseRepo(fullName, r ? {accountId: root.syncStatus.accountId, repoId: r.id} : null)
                        })
                        item.repoTyped.connect(function(name) {
                            if (!root.repoRe.test(name)) { root.lastError = "invalid owner/repo"; return }
                            repoProc.typed = name
                            repoProc.running = true
                        })
                        item.syncNow.connect(function() {
                            if (root.selection) root.startSync(root.selection.repo, {expect: {accountId: root.selection.accountId, repoId: root.selection.repoId}})
                        })
                        item.resetUsage.connect(function() {
                            root.usage = Use.resetUsage()
                            usageFile.blockWrites = false
                            usageFile.setText(JSON.stringify(root.usage))
                            root.rebuildRows("")
                        })
                        item.backRequested.connect(function() {
                            if (root.cameFrom !== "") { root.view = root.cameFrom; root.cameFrom = "" }
                            else if (root.selection || root.draft) root.view = root.draft ? "editor" : "search"
                            else root.hide()
                        })
                        item.resumeRequested.connect(function() { if (root.draft) root.route() })
                        item.confirmReimport.connect(function() {
                            if (root.pendingMismatch && root.pendingMismatch.fullName) {
                                var m = root.pendingMismatch
                                root.pendingMismatch = null
                                root.libraryMismatch = ""
                                root.startSync(m.fullName, {expect: m.expect || null, repoChange: true})
                            }
                        })
                        item.pullRequested.connect(function() {
                            if (root.selection) root.startSync(root.selection.repo, {expect: {accountId: root.selection.accountId, repoId: root.selection.repoId}})
                        })
                    }
                }
            }
        }
    }
}
