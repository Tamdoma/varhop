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
    property string lastQuery: ""           // query the current rows were built for
    property string _lastKey: ""            // folded term key of lastQuery
    property bool retainSelection: false    // rows changed without a query edit
    property string _lastSelected: ""       // last selected row id, survives view switches
    property var currentPrompt: null
    property var rows: []
    property int syncGen: 0
    property int pendingGen: 0
    property bool stateDirReady: false
    property var pendingSync: null          // {fullName, repoChange, staged, parsed}
    property var pendingSave: null          // selection object awaiting read-back
    property var pendingMismatch: null      // {fullName, expect, actual}
    property var prevSelection: null        // selection before a repoChange save attempt
    property bool saveTried: false          // a saveSelection write was attempted this sync
    property var rollbackCheck: null        // previous selection awaiting rollback read-back
    property bool rollbackFailed: false     // read-back did not confirm the restore
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
        rebuildRows(searchLoader.item ? searchLoader.item.query : lastQuery)
    }

    // Parse a bundle and import its prompts without committing it as the
    // active library. Returns {bundle, out, errs} or null with a message in
    // libraryMismatch. expectedRepoId is the selection's repoId for the
    // stable cache and the sync output's repoId for a staged bundle.
    function parseBundle(text, expectedRepoId) {
        var b = null
        try { b = JSON.parse(text) } catch (e) { b = null }
        if (!b) return null
        if (String(b.repoId) !== String(expectedRepoId)) return null
        var out = Imp.importLibrary(b.files || [])
        var errs = []
        for (var i = 0; i < (b.errors || []).length; i++) {
            var be = b.errors[i]
            errs.push({kind: "bundle", path: be.path || "?", line: null, message: be.message || "?"})
        }
        for (var j = 0; j < out.errors.length; j++) {
            var pe = out.errors[j]
            errs.push({kind: "prompt", path: pe.path || "?", line: pe.line, message: pe.message || "?"})
        }
        return {bundle: b, out: out, errs: errs}
    }

    function applyParsed(p) {
        var b = p.bundle
        library = p.out
        loadErrors = p.errs
        bundle = b
        lastPull = b.fetchedAt ? new Date(b.fetchedAt).toISOString().slice(0, 16).replace("T", " ") : ""
        if (b.status === "empty-repo") { lastError = "repo has no prompts" }
        if (b.status === "no-prompts") { lastError = "repo has no prompts/ directory" }
        rebuildRows(searchLoader.item ? searchLoader.item.query : lastQuery)
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
            if (opened && view !== "settings") view = "settings"
            return null
        }
        libraryMismatch = ""
        applyParsed(parseBundle(text, selection.repoId))
        return b
    }

    function fileNameStem(id) {
        var base = id.slice(id.lastIndexOf("/") + 1)
        return base
    }

    // Rank + row-materialization are pure in (prompts, usage, canonical
    // query terms, draft), each an immutable snapshot, so equal inputs
    // replay cached rows. A small LRU covers backspacing and repeated
    // queries; snapshot identity invalidates without bookkeeping.
    property var _rowCacheMap: null
    readonly property int _rowCacheCap: 32
    // Detail strings and stem display decisions depend only on the prompt
    // object; caching them per id keeps each keystroke's row build linear
    // and small at multi-thousand-prompt libraries.
    property var _partCache: ({})
    property var _partCacheFor: null

    function _parts(p) {
        if (_partCacheFor !== library.prompts) {
            _partCache = {}
            _partCacheFor = library.prompts
        }
        var hit = _partCache[p.id]
        if (hit !== undefined) return hit
        var cat = p.subcategory ? p.category + " / " + p.subcategory : p.category
        var detail = cat + (p.description ? " — " + p.description : "")
        var stem = fileNameStem(p.id)
        var showFile = Fold.fold(p.title).indexOf(Fold.fold(stem.replace(/\.md$/, ""))) === -1
        hit = {detail: detail, fileName: showFile ? stem : ""}
        _partCache[p.id] = hit
        return hit
    }

    function rebuildRows(query) {
        query = query || ""
        // Ranking only reads folded terms, so whitespace-only differences
        // produce identical rows and share one cache entry.
        var key = Sea.fold(query).split(/\s+/).filter(function(t) { return t !== "" }).join(" ")
        retainSelection = (key === _lastKey)
        _lastKey = key
        lastQuery = query
        if (_rowCacheMap === null) _rowCacheMap = new Map()
        var c = _rowCacheMap.get(key)
        if (c && c.prompts === library.prompts && c.usage === usage && c.draft === draft) {
            // Refresh recency inside the LRU.
            _rowCacheMap.delete(key)
            _rowCacheMap.set(key, c)
            rows = c.rows
            return
        }
        var ranked = Sea.rank(library.prompts, query, usage, Date.now())
        // Linear scan per row was quadratic at large libraries; the map
        // lookup keeps each keystroke inside the frame budget.
        var byId = {}
        for (var m = 0; m < library.prompts.length; m++)
            byId[library.prompts[m].id] = library.prompts[m]
        var out = []
        for (var i = 0; i < ranked.length; i++) {
            var p = byId[ranked[i].id]
            if (!p) continue
            var parts = _parts(p)
            out.push({
                id: p.id, title: p.title, detail: parts.detail,
                fileName: parts.fileName,
                draft: draft !== null && draft.promptId === p.id,
                snippet: ranked[i].snippet || ""
            })
        }
        rows = out
        if (_rowCacheMap.size > _rowCacheCap)
            _rowCacheMap.delete(_rowCacheMap.keys().next().value)
        _rowCacheMap.set(key, {prompts: library.prompts, usage: usage, draft: draft, rows: out})
    }

    function refreshStatus() {
        if (!manifest || statusProc.running) return
        statusProc.running = true
    }

    function refreshRepos() {
        if (!manifest || reposProc.running) return
        reposProc.running = true
    }

    function refreshBinds() {
        if (!manifest || bindsProc.running) return
        bindsProc.running = true
    }




    function route() {
        if (draft !== null) {
            var p = null
            for (var i = 0; i < library.prompts.length; i++)
                if (library.prompts[i].id === draft.promptId) { p = library.prompts[i]; break }
            if (p) {
                currentPrompt = p
                view = "editor"
                // The loader activates on view change; the item may not exist yet.
                Qt.callLater(function() { if (view === "editor" && editorLoader.item) editorLoader.item.openPrompt() })
                return
            }
            draft = null
        }
        // A cache rejected while closed leaves libraryMismatch set; summon
        // must land on the settings recovery path, not stale search rows.
        if (!selection || libraryMismatch !== "") view = "settings"
        else view = "search"
        cameFrom = ""
    }

    function backToEditor() {
        // Returning to the editor after settings needs a fresh openPrompt:
        // the loader destroyed the item while the view was elsewhere.
        Qt.callLater(function() { if (view === "editor" && editorLoader.item) editorLoader.item.openPrompt() })
    }

    // ---- shell API ------------------------------------------------------------
    function open(payloadJson) {
        opened = true
        route()
        refreshStatus()
        if (!selection) refreshRepos()
        refreshBinds()
        rebuildRows(searchLoader.item ? searchLoader.item.query : lastQuery)
        if (view === "editor" && editorLoader.item) editorLoader.item.openPrompt()
    }

    function close() {
        // Copy completion is the only hide that must not capture: onSucceeded
        // clears the draft, and a capture would resurrect it.
        if (view === "editor" && editorLoader.item && !copySucceeded && currentPrompt) {
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
        pendingSync = {fullName: fullName, repoChange: !!(opts && opts.repoChange), staged: "", parsed: null}
        // false = there was no selection to return to (first sync).
        prevSelection = pendingSync.repoChange ? (selection === null ? false : selection) : null
        saveTried = false
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
        saveTried = true
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

    // Called by stagedFile after the staged bundle parsed and imported.
    function stagedReady(parsed, entry) {
        if (!pendingSync || pendingSync.parsed !== null) return
        pendingSync.parsed = parsed
        if (!pendingSync.repoChange) { acceptStaged(); return }
        var out = pendingSync.syncOut || {}
        var e = entry || {repo: out.repo, login: out.login,
                          accountId: out.accountId, repoId: out.repoId}
        if (!saveSelection(e)) { failSync("save failed"); restorePrevSelection(); return }
        // configFile's onLoaded/onFileChanged drives confirmSaved → acceptStaged;
        // saveWatchdog completes the failure when no confirming read lands.
        saveWatchdog.restart()
        if (confirmSaved(e)) { saveWatchdog.stop(); acceptStaged() }
    }

    function acceptStaged() {
        if (!pendingSync || pendingSync.staged === "") return
        acceptProc.command = [syncBin, "accept", cachePath, String(pendingGen)]
        acceptProc.running = true
    }

    function finishSync() {
        // Accept landed: swap in the already-imported staged bundle.
        if (!pendingSync || pendingSync.parsed === null) { syncing = false; return }
        var parsed = pendingSync.parsed
        var wasRepoChange = pendingSync.repoChange
        pendingSync = null
        syncing = false
        if (wasRepoChange) draft = null   // confirmed switch discards the draft
        applyParsed(parsed)
        usagePath = selection ? stateDir + "/usage-" + selection.repoId + ".json" : ""
        if (view === "settings" && cameFrom === "") view = "search"
    }

    function failSync(msg) {
        syncing = false
        pendingSync = null
        pendingSave = null
        lastError = msg
    }

    function restorePrevSelection() {
        // A repo-change failed after the entry was (maybe) written; put the
        // previous durable selection back so selection and library agree.
        if (!saveTried || prevSelection === null) return
        var prev = prevSelection
        prevSelection = null
        saveTried = false
        rollbackFailed = false
        if (shell && typeof shell.updateEntryInline === "function")
            shell.updateEntryInline("ivan.varhop", prev === false ? {}
                : {repo: prev.repo, login: prev.login, accountId: prev.accountId, repoId: prev.repoId})
        rollbackCheck = prev === false ? "none" : prev
        configFile.reload()
        rollbackWatchdog.restart()
        usagePath = prev === false ? "" : stateDir + "/usage-" + prev.repoId + ".json"
    }

    // Called from configFile.onLoaded after the rollback write: a selection
    // equal to the previous entry means the durable state was restored.
    function confirmRollback() {
        if (rollbackCheck === null) return true
        var want = rollbackCheck
        var got = selection
        var ok = (want === "none" && (!got || !got.repo)) ||
            (want !== "none" && got && got.repo === want.repo &&
             String(got.accountId) === String(want.accountId) &&
             String(got.repoId) === String(want.repoId))
        if (ok) {
            rollbackCheck = null
            rollbackWatchdog.stop()
            return true
        }
        return false
    }

    function noteRollbackFailed() {
        rollbackFailed = true
        rollbackCheck = null
        // The earlier sync error still stands; append the worse outcome.
        lastError = lastError ? lastError + "; could not restore the previous selection"
                              : "could not restore the previous selection"
    }

    // ---- usage -----------------------------------------------------------------
    property bool usageLoadFailed: false  // malformed/unreadable: writes gated

    function recordUsage(promptId) {
        if (usageLoadFailed) {
            // Never overwrite a history file we could not parse; the surfaced
            // error stays and the settings Reset action is the recovery.
            return
        }
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
            var hadSelection = !!root.selection
            root.parseConfig(text())
            // A rollback read is confirmed only when the restored selection
            // equals the previous entry; a pre-write snapshot is not a
            // failure, the watchdog decides after the file settles.
            if (root.rollbackCheck !== null) root.confirmRollback()
            if (root.confirmSaved(root.pendingSave)) {
                root.acceptStaged()
            } else if (!hadSelection && root.selection) {
                // First read may race the library load: selection landed after
                // the bundle was rejected as mismatched. Re-read it now.
                if (root.library.prompts.length === 0) libraryFile.reload()
            }
        }
        onLoadFailed: function(error) {
            // A missing file means no saved selection yet; other read
            // failures keep the previous in-memory selection.
            if (error === FileViewError.FileNotFound) root.parseConfig("")
        }
        onFileChanged: reload()
    }

    // Reads the staged bundle varhop-sync produced; imported against the
    // sync output's repoId so a repo change is accepted before the entry
    // flips. parseBundle failure completes the sync as an error.
    FileView {
        id: stagedFile
        watchChanges: false
        printErrors: false
        onLoaded: {
            if (!root.pendingSync || root.pendingSync.parsed !== null) return
            var p = root.parseBundle(text(), root.pendingSync.repoId)
            if (!p) { root.failSync("staged import failed"); root.restorePrevSelection(); return }
            root.stagedReady(p, null)
        }
        onLoadFailed: function(error) {
            if (root.pendingSync && root.pendingSync.parsed === null) {
                root.failSync("staged read failed")
                root.restorePrevSelection()
            }
        }
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
            if (r.state !== undefined) { root.usage = r.state; root.usageError = ""; root.usageLoadFailed = false }
            // A malformed file keeps the in-memory state and only shows the
            // error; a silent reset would lose per-repo history.
            else { root.usageError = "usage file unreadable: " + r.error; root.usageLoadFailed = true }
            root.rebuildRows(searchLoader.item ? searchLoader.item.query : lastQuery)
        }
        onLoadFailed: function(error) {
            if (error === FileViewError.FileNotFound) {
                // First run: nothing persisted yet.
                root.usage = Use.resetUsage()
                root.usageLoadFailed = false
                root.rebuildRows("")
            } else {
                root.usageError = "usage read failed (" + error + ")"
                root.usageLoadFailed = true
            }
        }
        onSaved: { if (!root.usageLoadFailed) root.usageError = "" }
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

    // Quickshell can refuse early Process starts while the shell is still
    // booting; keep retrying the lightweight probes until one lands.
    Timer {
        id: retryStatus
        interval: 1500
        repeat: true
        running: !!root.manifest && !statusProc.running && !root.syncStatus
        onTriggered: statusProc.running = true
    }
    Timer {
        id: retryRepos
        interval: 1500
        repeat: true
        running: !!root.manifest && !reposProc.running && root.repos.length === 0
        onTriggered: reposProc.running = true
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
                    if (r.fullName) root.chooseRepo(r.fullName, {accountId: root.syncStatus ? root.syncStatus.accountId : null, repoId: r.id})
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
                    root.restorePrevSelection()
                    return
                }
                // Read the staged bundle; its FileView imports it against
                // the sync output's repoId before anything is published.
                root.pendingSync.staged = out.staged || ""
                root.pendingSync.repoId = out.repoId
                root.pendingSync.syncOut = out
                stagedFile.path = out.staged
                stagedFile.reload()
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
            else { root.failSync("accept failed (exit " + code + ")"); root.restorePrevSelection() }
        }
    }

    Timer {
        id: saveWatchdog
        interval: 3000
        repeat: false
        onTriggered: {
            if (root.pendingSave) {
                root.failSync("selection save was not confirmed")
                root.restorePrevSelection()
            }
        }
    }

    Timer {
        id: rollbackWatchdog
        interval: 3000
        repeat: false
        onTriggered: { if (root.rollbackCheck !== null) root.noteRollbackFailed() }
    }

    Process {
        id: mkdirProc
        command: ["mkdir", "-p", root.stateDir]
        onExited: function(code) {
            if (code === 0) root.stateDirReady = true
            usageFile.reload()
        }
    }

    Timer {
        // Same early-spawn workaround as the sync probes.
        interval: 1500
        repeat: true
        running: !root.stateDirReady
        onTriggered: if (!mkdirProc.running) mkdirProc.running = true
    }

    property bool copySucceeded: false

    Copier {
        id: copier
        onSucceeded: {
            if (root.currentPrompt) root.recordUsage(root.currentPrompt.id)
            root.copySucceeded = true
            root.draft = null
            root.hide()
            root.copySucceeded = false
        }
        onFailed: function(reason) { root.lastError = reason }
    }

    Copier {
        id: bindCopier
    }

    Component.onCompleted: {
        mkdirProc.running = true
        // Probes spawn on first open: spawning this early fails while the
        // shell is still booting.
    }

    onOpenedChanged: if (opened) {
        refreshStatus()
        refreshBinds()
        if (!selection) refreshRepos()
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
                            if (root.view === "editor") root.backToEditor()
                        } else {
                            // Capture editor state before its loader destroys
                            // the item while settings is active. A resumed
                            // draft is re-captured too: edits made since the
                            // resume must survive the transition.
                            if (root.view === "editor" && editorLoader.item && root.currentPrompt)
                                root.draft = editorLoader.item.captureDraft()
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
                        item.setQuery(root.lastQuery)
                        item.selectionChanged.connect(function(id) { root._lastSelected = id })
                        if (root._lastSelected !== "") {
                            item.restoreId = root._lastSelected
                            item.resolveSelection()
                        }
                        item.queryEdited.connect(function(q) {
                            root.lastKeyAt = item.keyTime
                            root.firstFramePending = true
                            root.rebuildRows(q)
                        })
                        item.queryCleared.connect(function() { root.rebuildRows("") })
                        item.hideRequested.connect(root.hide)
                        item.retainSelection = Qt.binding(function() { return root.retainSelection })
                        item.accepted.connect(function(id) {
                            for (var i = 0; i < root.library.prompts.length; i++) {
                                if (root.library.prompts[i].id === id) {
                                    root.prevSearch = {query: root.lastQuery, selectedId: id}
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
                            if (searchLoader.item && root.prevSearch) {
                                // restoreId must land before setQuery: the
                                // text assignment emits queryEdited and the
                                // rebuild consumes the one-shot id.
                                searchLoader.item.restoreId = root.prevSearch.selectedId || ""
                                searchLoader.item.setQuery(root.prevSearch.query || "")
                            }
                            if (root.prevSearch) root.rebuildRows(root.prevSearch.query)
                            root.view = "search"
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
                            // The recovery for a failed load: the operator's
                            // explicit reset may overwrite the bad file.
                            root.usage = Use.resetUsage()
                            root.usageLoadFailed = false
                            usageFile.blockWrites = false
                            usageFile.setText(JSON.stringify(root.usage))
                            root.rebuildRows("")
                        })
                        item.backRequested.connect(function() {
                            if (root.cameFrom !== "") {
                                root.view = root.cameFrom
                                root.cameFrom = ""
                                if (root.view === "editor") root.backToEditor()
                            } else if (root.selection || root.draft) {
                                root.view = root.draft ? "editor" : "search"
                                if (root.view === "editor") root.backToEditor()
                            } else root.hide()
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
