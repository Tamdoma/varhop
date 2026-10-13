import QtQuick
import QtQuick.Controls
import QtTest

// Component checks for the varhop views. The views import no Quickshell module,
// so qmltestrunner loads them; all shell services (copier, repo list, binds)
// arrive as injected props. The clipboard is the real Wayland clipboard.
TestCase {
    id: tc
    name: "VarhopViews"
    when: windowShown
    width: 900
    height: 700
    visible: true

    function allChildren(root) {
        var out = []
        var kids = root.children || []
        for (var i = 0; i < kids.length; i++) {
            out.push(kids[i])
            out = out.concat(allChildren(kids[i]))
        }
        return out
    }

    function textsUnder(root, needle) {
        var found = []
        var all = allChildren(root)
        for (var i = 0; i < all.length; i++) {
            var it = all[i]
            if (it.text !== undefined && String(it.text).indexOf(needle) !== -1)
                found.push(it)
        }
        return found
    }

    function hasText(root, needle) {
        return textsUnder(root, needle).length > 0
    }

    // prompt: {id, title, body, names}; the view derives segments via lib/tokens.mjs.
    function prompt(body, names) {
        return {id: "prompts/dev/x.md", title: "X prompt", body: body, names: names}
    }

    Component { id: searchComp; SearchBody {} }
    Component { id: editorComp; EditorBody {} }
    Component { id: settingsComp; SettingsBody {} }
    Component { id: spyComp; SignalSpy {} }
    Component { id: failingCopierComponent
        QtObject {
            signal failed(string reason)
            function copy(t) { failed("copy failed"); return false }
        }
    }

    // ------- SearchBody -------

    function test_search_rows_show_details() {
        var s = createTemporaryObject(searchComp, tc, {
            width: 700, height: 500, visible: true,
            rows: [
                {id: "p1", title: "Deploy prod", detail: "ops / release — ship the build", fileName: "deploy-prod.md", draft: false, snippet: ""},
                {id: "p2", title: "Body hit", detail: "ops / misc — other", fileName: "misc.md", draft: false, snippet: "…needle inside body…"},
                {id: "p3", title: "Drafty", detail: "ops / d — draft row", fileName: "drafty.md", draft: true, snippet: ""}
            ],
            draftPromptId: "p3",
            colors: ({}), query: ""
        })
        verify(s)
        // ListView creates delegates asynchronously.
        tryVerify(function() { return hasText(s, "needle inside body") }, 2000)
        verify(hasText(s, "Deploy prod"), "title row")
        verify(hasText(s, "ops / release"), "category path")
        verify(hasText(s, "ship the build"), "description")
        verify(hasText(s, "deploy-prod.md"), "file name when title does not identify it")
        verify(hasText(s, "Draft"), "draft marker")
        s.destroy()
    }

    function test_search_resume_row_and_result_click() {
        var s = createTemporaryObject(searchComp, tc, {
            width: 700, height: 500, visible: true,
            rows: [{id: "p1", title: "One", detail: "c — d", fileName: "one.md", draft: false, snippet: ""}],
            draftPromptId: "p1",
            colors: ({}), query: ""
        })
        verify(s)
        var spyResume = spyComp.createObject(tc, {target: s, signalName: "resumeDraft"})
        var spyOpen = spyComp.createObject(tc, {target: s, signalName: "accepted"})
        var resume = findChild(s, "resumeDraftRow")
        verify(resume, "pinned resume row exists")
        verify(hasText(s, "Ctrl+Shift+P") || hasText(s, "Resume draft"), "resume row shows its chord")
        mouseClick(resume)
        compare(spyResume.count, 1)
        tryVerify(function() { return findChild(s, "resultRow0") !== null }, 2000)
        waitForRendering(s)
        var row0 = findChild(s, "resultRow0")
        verify(row0, "result row exists")
        mouseClick(row0)
        compare(spyOpen.count, 1)
        compare(spyOpen.signalArguments[0][0], "p1")
        s.destroy()
    }

    function test_search_esc_clear_then_hide() {
        var s = createTemporaryObject(searchComp, tc, {
            width: 700, height: 500, visible: true,
            rows: [], draftPromptId: "", colors: ({}), query: ""
        })
        verify(s)
        var spyClear = spyComp.createObject(tc, {target: s, signalName: "queryCleared"})
        var spyHide = spyComp.createObject(tc, {target: s, signalName: "hideRequested"})
        var field = findChild(s, "queryField")
        verify(field, "query field")
        field.forceActiveFocus()
        keyClick(Qt.Key_A)
        keyClick(Qt.Key_Escape)
        compare(spyClear.count, 1, "first Esc clears non-empty query")
        compare(spyHide.count, 0)
        keyClick(Qt.Key_Escape)
        compare(spyHide.count, 1, "Esc on empty query hides")
        s.destroy()
    }

    function test_search_field_paste_copy_chords() {
        var s = createTemporaryObject(searchComp, tc, {
            width: 700, height: 500, visible: true,
            rows: [], draftPromptId: "", colors: ({}), query: ""
        })
        verify(s)
        var field = findChild(s, "queryField")
        field.forceActiveFocus()
        field.text = "abcd"
        field.selectAll()
        field.copy() // seed the real clipboard directly
        field.text = ""
        keyClick(Qt.Key_V, Qt.ControlModifier)
        compare(field.text, "abcd", "Ctrl+V pastes")
        field.text = "xy"
        field.selectAll()
        keyClick(Qt.Key_C, Qt.ControlModifier) // Ctrl+C copies the field selection, no export
        field.text = ""
        keyClick(Qt.Key_V, Qt.ControlModifier | Qt.ShiftModifier)
        compare(field.text, "xy", "Ctrl+Shift+V pastes the selection copied by Ctrl+C")
        field.text = "w"
        field.selectAll()
        keyClick(Qt.Key_C, Qt.ControlModifier | Qt.ShiftModifier)
        field.text = ""
        keyClick(Qt.Key_V, Qt.ControlModifier)
        compare(field.text, "w", "Ctrl+Shift+C copies the field selection")
        s.destroy()
    }

    // ------- EditorBody -------

    function test_editor_tab_wrap_and_mirror() {
        var e = createTemporaryObject(editorComp, tc, {
            width: 700, height: 500, visible: true,
            prompt: prompt("A {{X}} mid {{Y}} end {{X}}", ["X", "Y"]),
            draft: null, copier: null, colors: ({})
        })
        verify(e)
        e.openPrompt()
        var v1 = findChild(e, "value0")
        var v2 = findChild(e, "value1")
        verify(v1 && v2, "one stop per unique name")
        v1.forceActiveFocus()
        keyClick(Qt.Key_Tab)
        verify(v2.activeFocus, "Tab to next unique name")
        keyClick(Qt.Key_Tab)
        verify(v1.activeFocus, "Tab wraps to first")
        keyClick(Qt.Key_Tab, Qt.ShiftModifier)
        verify(v2.activeFocus, "Shift+Tab wraps back")
        keyClick(Qt.Key_Tab)
        v1.forceActiveFocus()
        keyClick(Qt.Key_H)
        keyClick(Qt.Key_I)
        compare(v1.text, "hi")
        var mir = findChild(e, "mirror0")
        verify(mir, "second {{X}} occurrence is a mirror")
        compare(String(mir.text), "hi", "typed value mirrors to every occurrence")
        e.destroy()
    }

    function test_editor_delete_reset_and_undo() {
        var e = createTemporaryObject(editorComp, tc, {
            width: 700, height: 500, visible: true,
            prompt: prompt("A {{X}}", ["X"]),
            draft: null, copier: null, colors: ({})
        })
        verify(e)
        e.openPrompt()
        var v = findChild(e, "value0")
        v.forceActiveFocus()
        v.text = "val"
        keyClick(Qt.Key_Delete)
        compare(v.text, "", "Delete on a value empties it")
        keyClick(Qt.Key_Delete)
        verify(hasText(e, "{{X}}"), "Delete again restores unset {{NAME}}")
        keyClick(Qt.Key_Z, Qt.ControlModifier)
        compare(v.text, "", "first undo returns to the empty state")
        keyClick(Qt.Key_Z, Qt.ControlModifier)
        compare(v.text, "val", "second undo restores the value")
        keyClick(Qt.Key_Y, Qt.ControlModifier)
        compare(v.text, "", "redo returns to the empty state")
        keyClick(Qt.Key_Y, Qt.ControlModifier)
        verify(hasText(e, "{{X}}"), "redo restores the reset")
        e.destroy()
    }

    function test_editor_undo_is_chronological() {
        var e = createTemporaryObject(editorComp, tc, {
            width: 700, height: 500, visible: true,
            prompt: prompt("A {{X}}", ["X"]),
            draft: null, copier: null, colors: ({})
        })
        verify(e)
        e.openPrompt()
        var v = findChild(e, "value0")
        v.forceActiveFocus()
        keyClick(Qt.Key_Delete)          // empty
        keyClick(Qt.Key_Delete)          // reset to unset {{X}}
        v.text = "abc"                    // programmatic write stands in for typing
        keyClick(Qt.Key_Z, Qt.ControlModifier)
        compare(v.text, "", "undo removes the typed text before touching the reset")
        keyClick(Qt.Key_Z, Qt.ControlModifier)
        compare(v.text, "", "next undo returns to the empty state, not empty-again")
        verify(hasText(e, "{{X}}"), "empty values still mirror as set")
        e.destroy()
    }

    function test_editor_undo_redo_stays_with_the_active_variable() {
        var e = createTemporaryObject(editorComp, tc, {
            width: 700, height: 500, visible: true,
            prompt: prompt("{{LANGUAGE}} {{DIFF}} {{LANGUAGE}}", ["LANGUAGE", "DIFF"])
        })
        e.openPrompt()
        var language = findChild(e, "value0")
        var diff = findChild(e, "value1")
        language.forceActiveFocus()
        keyClick(Qt.Key_P)
        keyClick(Qt.Key_Tab)
        keyClick(Qt.Key_D)
        keyClick(Qt.Key_Tab, Qt.ShiftModifier)
        keyClick(Qt.Key_Z, Qt.ControlModifier)
        compare(language.text, "", "undo applies to the focused variable")
        compare(diff.text, "d", "undo leaves the other variable unchanged")
        keyClick(Qt.Key_Tab)
        keyClick(Qt.Key_F)
        keyClick(Qt.Key_Tab, Qt.ShiftModifier)
        keyClick(Qt.Key_Y, Qt.ControlModifier)
        compare(language.text, "p", "editing another variable preserves this variable's redo")
        compare(diff.text, "df")
        compare(findChild(e, "mirror0").text, "p")
        keyClick(Qt.Key_Tab)
        keyClick(Qt.Key_Z, Qt.ControlModifier)
        compare(diff.text, "d", "each variable keeps chronological edits")
        compare(language.text, "p")
        e.destroy()
    }

    function test_editor_draft_only_restores_its_own_prompt() {
        var e = createTemporaryObject(editorComp, tc, {
            width: 700, height: 500, visible: true,
            prompt: prompt("A {{X}}", ["X"]),
            draft: {promptId: "other/prompt.md", values: {X: "stale"},
                    activeName: "X", cursor: 0, selection: null},
            copier: null, colors: ({})
        })
        verify(e)
        e.openPrompt()
        var v = findChild(e, "value0")
        compare(v.text, "", "a draft for another prompt must not fill this one")
        e.destroy()
    }

    function test_search_refresh_retains_selection() {
        var s = createTemporaryObject(searchComp, tc, {
            width: 700, height: 500, visible: true,
            rows: [
                {id: "p1", title: "One", detail: "d", fileName: "", draft: false, snippet: ""},
                {id: "p2", title: "Two", detail: "d", fileName: "", draft: false, snippet: ""}
            ],
            draftPromptId: "", colors: ({}), query: ""
        })
        verify(s)
        s.selectedIndex = 1
        s.retainSelection = true
        s.rows = s.rows.slice()           // same query, refreshed rows (Ctrl+R)
        compare(s.rows[s.selectedIndex].id, "p2", "refresh retains the selected id")
        s.retainSelection = false
        s.rows = s.rows.slice()           // a query edit resets to the top
        compare(s.selectedIndex, 0, "query edits reset to the top")
        s.destroy()
    }

    function test_editor_zero_variable_requests_copy() {
        var e = createTemporaryObject(editorComp, tc, {
            width: 700, height: 500, visible: true,
            prompt: prompt("plain body", []),
            draft: null, copier: null, colors: ({})
        })
        verify(e)
        var spy = spyComp.createObject(tc, {target: e, signalName: "copyRequested"})
        e.openPrompt()
        tryVerify(function() { return spy.count === 1 }, 1000)
        compare(spy.count, 1, "zero-variable prompt opens ready and copies")
        e.destroy()
    }

    function test_editor_zero_variable_calls_copier() {
        var calls = []
        var e = createTemporaryObject(editorComp, tc, {
            width: 700, height: 500, visible: true,
            prompt: prompt("plain body", []),
            copier: {copy: function(text) { calls.push(text); return true }}
        })
        e.openPrompt()
        tryVerify(function() { return calls.length === 1 }, 1000)
        compare(calls[0], "plain body")
        e.destroy()
    }

    function test_editor_empty_mirror_and_unset_count() {
        var e = createTemporaryObject(editorComp, tc, {
            width: 700, height: 500, visible: true,
            prompt: prompt("{{X}} repeated {{X}} then {{Y}}", ["X", "Y"])
        })
        e.openPrompt()
        e.setValue("X", "")
        compare(findChild(e, "mirror0").text, "")
        verify(hasText(e, "1 unset variable"), "present-empty values are not counted as unset")
        e.unsetValue("X")
        compare(findChild(e, "mirror0").text, "{{X}}")
        verify(hasText(e, "2 unset variables"))
        e.destroy()
    }

    function test_editor_paste_multiline_and_mirror_click() {
        var e = createTemporaryObject(editorComp, tc, {
            width: 700, height: 500, visible: true,
            prompt: prompt("A {{X}} mid {{Y}} end {{X}}", ["X", "Y"]),
            draft: null, copier: null, colors: ({})
        })
        verify(e)
        e.openPrompt()
        var v = findChild(e, "value0")
        v.forceActiveFocus()
        v.text = "zz"
        v.selectAll()
        v.copy() // seed the real clipboard
        v.text = ""
        keyClick(Qt.Key_V, Qt.ControlModifier | Qt.ShiftModifier)
        compare(v.text, "zz", "Ctrl+Shift+V pastes literally into a value")
        keyClick(Qt.Key_Return)
        compare(v.text, "zz\n", "Enter inserts a newline in a value")
        var mir = findChild(e, "mirror0")
        mouseClick(mir)
        compare(e.activeName, "X", "clicking a mirror makes it the active value")
        keyClick(Qt.Key_Tab)
        compare(e.activeName, "Y", "next Tab goes to the next unique name")
        var prose = textsUnder(e, "mid")
        verify(prose.length > 0, "prose rendered")
        var before = String(prose[0].text)
        keyClick(Qt.Key_B)
        compare(String(prose[0].text), before, "typing leaves the prose unchanged")
        e.destroy()
    }

    function test_editor_right_click_paste() {
        var e = createTemporaryObject(editorComp, tc, {
            width: 700, height: 500, visible: true,
            prompt: prompt("A {{X}}", ["X"]),
            draft: null, copier: null, colors: ({})
        })
        verify(e)
        e.openPrompt()
        var v = findChild(e, "value0")
        v.forceActiveFocus()
        v.text = "clip"
        v.selectAll()
        v.copy()
        v.text = ""
        // A synthetic right-click instantiates the attached context menu but
        // does not synthesize QContextMenuEvent, so it stays closed; open the
        // same TextEditingContextMenu a real right-click opens and trigger Paste.
        mouseClick(v, v.width / 2, v.height / 2, Qt.RightButton)
        tryVerify(function() { return v.ContextMenu && v.ContextMenu.menu !== null }, 1000)
        var menu = v.ContextMenu.menu
        verify(menu, "value field has an attached context menu")
        menu.open()
        tryVerify(function() { return menu.opened }, 500)
        var pasteItem = null
        for (var i = 0; i < menu.count; i++) {
            var it = menu.itemAt(i)
            if (it && it.text === "Paste") { pasteItem = it; break }
        }
        verify(pasteItem, "menu has Paste")
        if (pasteItem.action && typeof pasteItem.action.trigger === "function")
            pasteItem.action.trigger()
        else
            pasteItem.clicked()
        tryVerify(function() { return v.text === "clip" }, 500)
        compare(v.text, "clip", "right-click paste lands in the value")
        e.destroy()
    }

    function test_editor_copy_failure_keeps_draft() {
        var stub = failingCopierComponent.createObject(tc)
        var e = createTemporaryObject(editorComp, tc, {
            width: 700, height: 500, visible: true,
            prompt: prompt("A {{X}}", ["X"]),
            draft: null, copier: stub, colors: ({})
        })
        verify(e)
        e.openPrompt()
        var v = findChild(e, "value0")
        v.forceActiveFocus()
        v.text = "keepme"
        keyClick(Qt.Key_C, Qt.ControlModifier)
        wait(50)
        compare(v.text, "keepme", "a reported copy failure keeps the draft")
        verify(hasText(e, "copy failed") || hasText(e, "failed"), "the failure is shown")
        e.destroy()
        stub.destroy()
    }

    // ------- SettingsBody -------

    function test_settings_logged_out_shows_fix() {
        var s = createTemporaryObject(settingsComp, tc, {
            width: 700, height: 500, visible: true,
            syncStatus: {authenticated: false, fix: "gh auth login"},
            lastPull: "", lastError: "", loadErrors: [],
            selection: null, binds: [], repos: [], colors: ({})
        })
        verify(s)
        verify(hasText(s, "gh auth login"), "logged-out status renders the fix")
        s.destroy()
    }

    function test_settings_failed_pull_and_merged_errors() {
        var s = createTemporaryObject(settingsComp, tc, {
            width: 700, height: 500, visible: true,
            syncStatus: {authenticated: true, login: "ivanjuras", scopes: ["repo", "read:org"]},
            lastPull: "2026-10-13 10:00",
            lastError: "network: fetch failed",
            loadErrors: [
                {kind: "bundle", path: "prompts/a/b.md", line: null, message: "invalid UTF-8"},
                {kind: "prompt", path: "prompts/a/c.md", line: 4, message: "duplicate key"}
            ],
            selection: {repo: "Tamdoma/varhop-prompts"}, binds: [], repos: [], colors: ({})
        })
        verify(s)
        verify(hasText(s, "ivanjuras"), "gh login shown")
        verify(hasText(s, "repo"), "scopes shown")
        verify(hasText(s, "2026-10-13"), "last successful pull shown")
        verify(hasText(s, "fetch failed"), "failed pull error shown")
        verify(hasText(s, "invalid UTF-8"), "repo-sync error merged without line")
        verify(hasText(s, "duplicate key"), "prompt-core error merged with line")
        s.destroy()
    }

    function test_chord_field_states() {
        var s = createTemporaryObject(settingsComp, tc, {
            width: 700, height: 500, visible: true,
            syncStatus: {authenticated: true, login: "u", scopes: []},
            lastPull: "", lastError: "", loadErrors: [],
            selection: {repo: "a/b"},
            binds: [{modmask: 68, key: "P", description: "Power", submap: ""}],
            repos: [], colors: ({})
        })
        verify(s)
        var f = findChild(s, "chordField")
        verify(f, "chord field")
        f.forceActiveFocus()
        f.text = "SUPER+CTRL+P"
        verify(hasText(s, "Power"), "SUPER+CTRL+P warns with the existing description")
        f.text = "SUPER+ALT+P"
        verify(hasText(s, "o.bind(") , "SUPER+ALT+P shows the ready bind line")
        f.text = "SUPER+ALT+"
        keyClick(Qt.Key_At)
        compare(s.chordState === "ready", false, "out-of-vocabulary characters refused")
        s.destroy()
    }

    function test_chord_suggested_syntax_and_character_rejection() {
        var s = createTemporaryObject(settingsComp, tc, {width: 700, height: 500, visible: true})
        var field = findChild(s, "chordField")
        field.text = "SUPER + ALT + P"
        field.forceActiveFocus()
        field.cursorPosition = field.text.length
        keyClick(Qt.Key_At)
        compare(field.text, "SUPER + ALT + P", "characters outside the vocabulary are refused")
        compare(s.chordState, "ready", "the displayed spaced syntax is accepted")
        s.destroy()
    }

    function test_settings_field_paste_copy_chords() {
        var s = createTemporaryObject(settingsComp, tc, {
            width: 700, height: 500, visible: true,
            syncStatus: {authenticated: true, login: "u", scopes: []},
            lastPull: "", lastError: "", loadErrors: [],
            selection: {repo: "a/b"}, binds: [], repos: [], colors: ({})
        })
        verify(s)
        var f = findChild(s, "repoField")
        verify(f, "typed repo field")
        f.forceActiveFocus()
        f.text = "abcd"
        f.selectAll()
        keyClick(Qt.Key_C, Qt.ControlModifier | Qt.ShiftModifier)
        f.text = ""
        keyClick(Qt.Key_V, Qt.ControlModifier)
        compare(f.text, "abcd", "Ctrl+Shift+C copies selection, Ctrl+V pastes")
        f.text = "xy"
        f.selectAll()
        keyClick(Qt.Key_C, Qt.ControlModifier)
        f.text = ""
        keyClick(Qt.Key_V, Qt.ControlModifier | Qt.ShiftModifier)
        compare(f.text, "xy", "Ctrl+Shift+V pastes")
        s.destroy()
    }

    // ------- Plain text everywhere -------

    function test_plain_text_format() {
        var hostile = "<b>x</b> and <img src='http://127.0.0.1:9/x'>"
        var s = createTemporaryObject(searchComp, tc, {
            width: 700, height: 500, visible: true,
            rows: [{id: "p1", title: hostile, detail: hostile, fileName: "f.md", draft: false, snippet: hostile}],
            draftPromptId: "", colors: ({}), query: ""
        })
        verify(s)
        var items = textsUnder(s, "<b>x</b>")
        verify(items.length > 0, "markup renders as literal text")
        for (var i = 0; i < items.length; i++) {
            if (items[i].textFormat !== undefined)
                compare(items[i].textFormat, Text.PlainText, "textFormat is PlainText")
        }
        var all = allChildren(s)
        for (var j = 0; j < all.length; j++) {
            if (all[j].source !== undefined && String(all[j].source).indexOf("127.0.0.1") !== -1)
                fail("Image source fed from user text")
        }
        s.destroy()
    }
}
