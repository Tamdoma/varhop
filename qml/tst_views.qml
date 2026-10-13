import QtQuick
import QtQuick.Controls
import QtTest
import "testing"
import "../lib/search.mjs" as Sea

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

    // Views receive the live theme and token objects; these stand-ins have the
    // same shape as Commons.Color and Style.
    property FakeTheme fakeTheme: FakeTheme {}
    property FakeTokens fakeTokens: FakeTokens {}

    Component { id: searchComp; SearchBody { theme: tc.fakeTheme; tokens: tc.fakeTokens } }
    Component { id: editorComp; EditorBody { theme: tc.fakeTheme; tokens: tc.fakeTokens } }
    Component { id: settingsComp; SettingsBody { theme: tc.fakeTheme; tokens: tc.fakeTokens } }
    Component { id: seedComp; TextEdit {} }
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
            query: ""
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
            query: ""
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
            rows: [], draftPromptId: "", query: ""
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

    function test_search_query_property_tracks_typing() {
        // Root-side rebuilds (import, config reload, Ctrl+R) read the public
        // query; a field that types without updating it leaves the root
        // rebuilding an empty list after every refresh.
        var s = createTemporaryObject(searchComp, tc, {
            width: 700, height: 500, visible: true,
            rows: [], draftPromptId: "", query: ""
        })
        verify(s)
        var field = findChild(s, "queryField")
        field.forceActiveFocus()
        keyClick(Qt.Key_C)
        keyClick(Qt.Key_O)
        compare(s.query, "co", "typing updates the public query")
        keyClick(Qt.Key_Backspace)
        compare(s.query, "c", "backspace updates the public query")
        s.destroy()
    }

    function test_search_field_paste_copy_chords() {
        var s = createTemporaryObject(searchComp, tc, {
            width: 700, height: 500, visible: true,
            rows: [], draftPromptId: "", query: ""
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
    // The editor is one PlainText TextArea (objectName editorText) showing the
    // whole prompt with values inline. `ranges` lists every value occurrence in
    // display order as {name, start, end}; `valueOf(name)` is undefined while
    // the name is unset. Edits sync through a deferred guard, so value checks wait.

    // The plugin root replaces library.prompts on every import and usage on
    // every usage write, then ranks again. The live shell segfaulted in
    // WeakMap.get on a freed key (coredumps of 2026-10-13 13:27 and 14:02).
    function test_search_rank_survives_replaced_libraries() {
        for (var r = 0; r < 20; r++) {
            var prompts = []
            for (var i = 0; i < 40; i++)
                prompts.push({id: "r" + r + "/p" + i + ".md", title: "T " + i, body: "b",
                              search: {title: "t " + i, fileName: "p" + i, category: "c",
                                       subcategory: "", description: "", tags: [], body: "b"}})
            var usage = {entries: {}}
            compare(Sea.rank(prompts, "", usage, Date.now()).length, 40)
            verify(Sea.rank(prompts, "t " + (r % 9), usage, Date.now()).length > 0)
            gc()
        }
    }

    function seedClipboard(text) {
        var t = createTemporaryObject(seedComp, tc, {text: text})
        t.selectAll()
        t.copy()
        t.destroy()
    }

    function openEditor(body, names, props) {
        var init = {width: 700, height: 500, visible: true, prompt: prompt(body, names), draft: null, copier: null}
        for (var k in props) init[k] = props[k]
        var e = createTemporaryObject(editorComp, tc, init)
        verify(e)
        e.openPrompt()
        var f = findChild(e, "editorText")
        verify(f, "the editor is one text box")
        tryVerify(function() { return f.activeFocus }, 1000, "the text box takes focus on open")
        return e
    }

    function textBox(e) { return findChild(e, "editorText") }

    function occurrence(e, name, n) {
        var seen = 0
        for (var i = 0; i < e.ranges.length; i++) {
            if (e.ranges[i].name !== name) continue
            if (seen === n) return e.ranges[i]
            seen++
        }
        fail("no occurrence " + n + " of " + name)
    }

    function typeText(s) {
        for (var i = 0; i < s.length; i++) keyClick(s[i])
    }

    function waitValue(e, name, value) {
        tryVerify(function() { return e.valueOf(name) === value }, 1000,
                  name + " should be " + JSON.stringify(value) + ", is " + JSON.stringify(e.valueOf(name)))
    }

    function test_editor_one_plain_text_box_with_inline_values() {
        var e = openEditor("A {{X}} mid {{Y}} end {{X}}", ["X", "Y"])
        var f = textBox(e)
        compare(f.textFormat, TextEdit.PlainText)
        compare(f.text, "A {{X}} mid {{Y}} end {{X}}", "the whole prompt shows, unset values as {{NAME}}")
        var editors = allChildren(e).filter(function(it) { return it.cursorPosition !== undefined })
        compare(editors.length, 1, "one text box, no per-value fields")
        compare(e.activeName, "X")
        compare(f.selectedText, "{{X}}", "the active unset value is wholly selected")
        compare(f.selectionStart, 2)
        typeText("hi")
        waitValue(e, "X", "hi")
        compare(f.text, "A hi mid {{Y}} end hi", "mirrors of a value update together")
        compare(e.valueOf("Y"), undefined)
    }

    function test_editor_tab_walks_unique_names_with_wrap() {
        var e = openEditor("A {{X}} mid {{Y}} end {{X}}", ["X", "Y"])
        var f = textBox(e)
        keyClick(Qt.Key_Tab)
        compare(e.activeName, "Y")
        compare(f.selectedText, "{{Y}}")
        keyClick(Qt.Key_Tab)
        compare(e.activeName, "X", "Tab wraps to the first name")
        keyClick(Qt.Key_Tab, Qt.ShiftModifier)
        compare(e.activeName, "Y", "Shift+Tab wraps back")
        compare(f.text, "A {{X}} mid {{Y}} end {{X}}", "Tab inserts nothing")
    }

    function test_editor_prose_never_changes() {
        var e = openEditor("ab {{X}} cd", ["X"])
        var f = textBox(e)
        keyClick("v")
        waitValue(e, "X", "v")
        compare(f.text, "ab v cd")
        var r = occurrence(e, "X", 0)
        compare(r.start, 3)
        compare(r.end, 4)
        f.cursorPosition = r.start
        keyClick(Qt.Key_Backspace)
        wait(50)
        compare(f.text, "ab v cd", "Backspace at the value's start edge is rejected")
        keyClick(Qt.Key_Home, Qt.ControlModifier)
        keyClick("q")
        wait(50)
        compare(f.text, "ab v cd", "typing in prose is rejected")
        f.select(1, 4)
        keyClick("q")
        wait(50)
        compare(f.text, "ab v cd", "typing over a selection across a boundary is rejected")
        seedClipboard("PP")
        f.select(1, 4)
        keyClick(Qt.Key_V, Qt.ControlModifier)
        wait(50)
        compare(f.text, "ab v cd", "paste across a boundary is rejected")
        f.select(1, 4)
        keyClick(Qt.Key_X, Qt.ControlModifier)
        wait(50)
        compare(f.text, "ab v cd", "cut across a boundary is rejected")
        f.insert(0, "MID")   // the route a middle-click paste onto prose takes
        tryCompare(f, "text", "ab v cd", 1000, "an insertion into prose is reverted")
        compare(f.canUndo, false, "native text undo is unreachable")
        r = occurrence(e, "X", 0)
        f.select(r.start, r.end)
        keyClick(Qt.Key_V, Qt.ControlModifier)
        waitValue(e, "X", "PP")
        compare(f.text, "ab PP cd", "the rejected cut left the clipboard unchanged")
    }

    function test_editor_rejected_shift_delete_keeps_clipboard() {
        seedClipboard("SENTINEL")
        var e = openEditor("A {{X}} b", ["X"])
        var f = textBox(e)
        typeText("value")
        waitValue(e, "X", "value")
        keyClick(Qt.Key_Home, Qt.ControlModifier)
        keyClick(Qt.Key_End, Qt.ShiftModifier)
        compare(f.selectedText, "A value b")
        keyClick(Qt.Key_Delete, Qt.ShiftModifier)
        tryCompare(f, "text", "A value b", 1000, "the cut across prose is rejected")
        var r = occurrence(e, "X", 0)
        f.select(r.start, r.end)
        keyClick(Qt.Key_V, Qt.ControlModifier)
        waitValue(e, "X", "SENTINEL")
    }

    function test_editor_click_edits_that_occurrence_in_place() {
        var e = openEditor("A {{X}} mid {{Y}} end {{X}}", ["X", "Y"])
        var f = textBox(e)
        keyClick(Qt.Key_Tab)
        compare(e.activeName, "Y")
        var r = occurrence(e, "X", 1)
        var rect = f.positionToRectangle(r.start + 2)
        mouseClick(f, rect.x + 1, rect.y + rect.height / 2)
        tryCompare(e, "activeName", "X")
        r = occurrence(e, "X", 1)
        compare(f.selectionStart, r.start, "the clicked occurrence is the one selected")
        compare(f.selectedText, "{{X}}")
        keyClick("q")
        waitValue(e, "X", "q")
        compare(f.text, "A q mid {{Y}} end q")
        r = occurrence(e, "X", 1)
        compare(f.cursorPosition, r.end, "editing continues in the clicked occurrence")
        keyClick(Qt.Key_Tab)
        compare(e.activeName, "Y", "Tab order stays by unique name")
    }

    function test_editor_per_name_undo_and_redo_across_tab() {
        var e = openEditor("{{L}} {{D}} {{L}}", ["L", "D"])
        var f = textBox(e)
        keyClick("p")
        waitValue(e, "L", "p")
        keyClick(Qt.Key_Tab)
        keyClick("d")
        waitValue(e, "D", "d")
        keyClick(Qt.Key_Tab, Qt.ShiftModifier)
        keyClick(Qt.Key_Z, Qt.ControlModifier)
        waitValue(e, "L", undefined)
        compare(e.valueOf("D"), "d", "undo leaves the other name unchanged")
        compare(f.text, "{{L}} d {{L}}")
        keyClick(Qt.Key_Tab)
        keyClick("f")
        waitValue(e, "D", "df")
        keyClick(Qt.Key_Tab, Qt.ShiftModifier)
        keyClick(Qt.Key_Y, Qt.ControlModifier)
        waitValue(e, "L", "p")
        compare(e.valueOf("D"), "df", "editing another name keeps this name's redo")
        compare(f.text, "p df p")
        keyClick(Qt.Key_Tab)
        keyClick(Qt.Key_Z, Qt.ControlModifier)
        waitValue(e, "D", "d")
        compare(e.valueOf("L"), "p", "each name keeps its own chronological history")
    }

    function test_editor_delete_empties_then_unsets_with_undo() {
        var e = openEditor("A {{X}}", ["X"])
        var f = textBox(e)
        keyClick(Qt.Key_Backspace)
        wait(50)
        compare(e.valueOf("X"), undefined, "Backspace on an unset value keeps it unset")
        compare(f.text, "A {{X}}")
        keyClick(Qt.Key_Delete)
        wait(50)
        compare(e.valueOf("X"), undefined, "Delete on an unset value keeps it unset")
        typeText("val")
        waitValue(e, "X", "val")
        keyClick(Qt.Key_Delete)
        waitValue(e, "X", "")
        compare(f.text, "A ", "Delete empties the value")
        keyClick(Qt.Key_Delete)
        waitValue(e, "X", undefined)
        compare(f.text, "A {{X}}", "Delete on an empty value unsets it")
        keyClick(Qt.Key_Z, Qt.ControlModifier)
        waitValue(e, "X", "")
        keyClick(Qt.Key_Z, Qt.ControlModifier)
        waitValue(e, "X", "val")
        keyClick(Qt.Key_Y, Qt.ControlModifier)
        waitValue(e, "X", "")
        keyClick(Qt.Key_Y, Qt.ControlModifier)
        waitValue(e, "X", undefined)
        compare(f.text, "A {{X}}", "redo restores the reset")
    }

    function test_editor_delete_on_unset_adds_no_history() {
        var e = openEditor("A {{X}}", ["X"])
        keyClick(Qt.Key_Delete)
        keyClick(Qt.Key_Delete)
        typeText("ab")
        waitValue(e, "X", "ab")
        keyClick(Qt.Key_Z, Qt.ControlModifier)
        keyClick(Qt.Key_Z, Qt.ControlModifier)
        waitValue(e, "X", undefined)
        keyClick(Qt.Key_Z, Qt.ControlModifier)
        wait(50)
        compare(e.valueOf("X"), undefined, "the Delete presses on the unset value left no history")
        keyClick(Qt.Key_Y, Qt.ControlModifier)
        waitValue(e, "X", "a")
    }

    function test_editor_value_highlights() {
        var e = openEditor("{{A}}{{B}} x {{C}} {{D}}", ["A", "B", "C", "D"])
        keyClick(Qt.Key_Tab)
        keyClick("b")
        waitValue(e, "B", "b")
        keyClick(Qt.Key_Tab)
        keyClick("c")
        waitValue(e, "C", "c")
        keyClick(Qt.Key_Backspace)
        waitValue(e, "C", "")
        keyClick(Qt.Key_Tab)
        keyClick(Qt.Key_Tab)
        compare(e.activeName, "A")
        wait(50)
        var kinds = {}
        var boxes = {}
        var lights = allChildren(e).filter(function(it) { return it.objectName === "valueHighlight" && it.visible })
        for (var i = 0; i < lights.length; i++) {
            var h = lights[i]
            kinds[h.name] = h.kind
            var x = h.mapToItem(e, 0, 0).x
            var b = boxes[h.name] || {left: x, right: x + h.width}
            boxes[h.name] = {left: Math.min(b.left, x), right: Math.max(b.right, x + h.width)}
        }
        compare(kinds.A, "active", "the active value has the strongest highlight")
        compare(kinds.B, "filled", "a filled value keeps a faint highlight")
        compare(kinds.C, "empty", "an empty value keeps a marker")
        compare(kinds.D, "unset", "an unset value shows muted")
        verify(boxes.A.right < boxes.B.left, "adjacent values do not visually merge")
    }

    function test_editor_copy_rebuilds_from_segments() {
        var calls = []
        var e = openEditor("Say {{X}} to {{Y}} and \\{{X}}", ["X", "Y"],
                           {copier: {copy: function(t) { calls.push(t); return true }}})
        var f = textBox(e)
        compare(f.text, "Say {{X}} to {{Y}} and {{X}}", "an escaped token shows as prose")
        compare(e.ranges.length, 2, "the escaped token is not a value")
        typeText("hi")
        waitValue(e, "X", "hi")
        keyClick(Qt.Key_C, Qt.ControlModifier)
        compare(calls.length, 1)
        compare(calls[0], "Say hi to {{Y}} and {{X}}", "copy rebuilds from segments and values")
    }

    function test_editor_draft_restores_values_history_and_exact_selection() {
        var e = openEditor("A {{X}} b", ["X"])
        var f = textBox(e)
        typeText("abcdef")
        waitValue(e, "X", "abcdef")
        keyClick(Qt.Key_Left, Qt.ShiftModifier)
        keyClick(Qt.Key_Left, Qt.ShiftModifier)
        compare(f.selectedText, "ef")
        compare(f.cursorPosition, 6)
        var d = e.captureDraft()
        compare(d.promptId, e.prompt.id)
        var e2 = openEditor("A {{X}} b", ["X"], {draft: d})
        var f2 = textBox(e2)
        compare(f2.text, "A abcdef b")
        tryCompare(f2, "cursorPosition", 6)
        compare(f2.selectionStart, 6)
        compare(f2.selectionEnd, 8)
        compare(e2.activeName, "X")
        keyClick(Qt.Key_Left, Qt.ShiftModifier)
        compare(f2.selectedText, "def", "the selection keeps its anchor and active end")
        keyClick("x")
        waitValue(e2, "X", "abcx")
        keyClick(Qt.Key_Z, Qt.ControlModifier)
        waitValue(e2, "X", "abcdef")
        keyClick(Qt.Key_Z, Qt.ControlModifier)
        waitValue(e2, "X", "abcde")
    }

    function test_editor_draft_only_restores_its_own_prompt() {
        var e = openEditor("A {{X}}", ["X"], {
            draft: {promptId: "other/prompt.md", values: {X: "stale"}, activeName: "X",
                    cursor: 0, anchor: 0, histories: {}, redos: {}}
        })
        compare(e.valueOf("X"), undefined, "a draft for another prompt must not fill this one")
        compare(textBox(e).text, "A {{X}}")
    }

    function test_search_refresh_retains_selection() {
        var s = createTemporaryObject(searchComp, tc, {
            width: 700, height: 500, visible: true,
            rows: [
                {id: "p1", title: "One", detail: "d", fileName: "", draft: false, snippet: ""},
                {id: "p2", title: "Two", detail: "d", fileName: "", draft: false, snippet: ""}
            ],
            draftPromptId: "", query: ""
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
            draft: null, copier: null
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
        var e = openEditor("{{X}} repeated {{X}} then {{Y}}", ["X", "Y"])
        e.setValue("X", "")
        tryCompare(textBox(e), "text", " repeated  then {{Y}}")
        verify(hasText(e, "1 unset variable"), "present-empty values are not counted as unset")
        e.unsetValue("X")
        tryCompare(textBox(e), "text", "{{X}} repeated {{X}} then {{Y}}")
        verify(hasText(e, "2 unset variables"))
    }

    function test_editor_paste_multiline_and_enter() {
        var e = openEditor("A {{X}} mid {{X}}", ["X"])
        var f = textBox(e)
        seedClipboard("zz\nyy")
        keyClick(Qt.Key_V, Qt.ControlModifier | Qt.ShiftModifier)
        waitValue(e, "X", "zz\nyy")
        compare(f.text, "A zz\nyy mid zz\nyy", "a multi-line paste lands in the value and its mirror")
        keyClick(Qt.Key_Return)
        waitValue(e, "X", "zz\nyy\n")
    }

    function test_editor_right_click_paste_and_disabled_undo() {
        var e = openEditor("A {{X}} b", ["X"])
        var f = textBox(e)
        seedClipboard("clip")
        var r = occurrence(e, "X", 0)
        var rect = f.positionToRectangle(r.start + 2)
        // A synthetic right-click instantiates the attached context menu but
        // does not synthesize QContextMenuEvent, so it stays closed; open the
        // same TextEditingContextMenu a real right-click opens and trigger Paste.
        mouseClick(f, rect.x + 1, rect.y + rect.height / 2, Qt.RightButton)
        tryVerify(function() { return f.ContextMenu && f.ContextMenu.menu !== null }, 1000)
        var menu = f.ContextMenu.menu
        verify(menu, "the text box has an attached context menu")
        menu.open()
        tryVerify(function() { return menu.opened }, 500)
        var pasteItem = null
        var undoItem = null
        for (var i = 0; i < menu.count; i++) {
            var it = menu.itemAt(i)
            if (it && it.text === "Paste") pasteItem = it
            if (it && it.text === "Undo") undoItem = it
        }
        verify(pasteItem, "menu has Paste")
        verify(!undoItem || !undoItem.enabled, "the menu's native Undo is disabled")
        if (pasteItem.action && typeof pasteItem.action.trigger === "function")
            pasteItem.action.trigger()
        else
            pasteItem.clicked()
        waitValue(e, "X", "clip")
        compare(f.text, "A clip b", "right-click paste lands in the value")
    }

    function test_editor_copy_failure_keeps_draft() {
        var stub = failingCopierComponent.createObject(tc)
        var e = openEditor("A {{X}}", ["X"], {copier: stub})
        typeText("keepme")
        waitValue(e, "X", "keepme")
        keyClick(Qt.Key_C, Qt.ControlModifier)
        wait(50)
        compare(e.valueOf("X"), "keepme", "a reported copy failure keeps the draft")
        verify(hasText(e, "copy failed"), "the failure is shown")
        stub.destroy()
    }

    // ------- SettingsBody -------

    function test_settings_logged_out_shows_fix() {
        var s = createTemporaryObject(settingsComp, tc, {
            width: 700, height: 500, visible: true,
            syncStatus: {authenticated: false, fix: "gh auth login"},
            lastPull: "", lastError: "", loadErrors: [],
            selection: null, binds: [], repos: []
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
            selection: {repo: "Tamdoma/varhop-prompts"}, binds: [], repos: []
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
            repos: []
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
            selection: {repo: "a/b"}, binds: [], repos: []
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

    // ------- Repository picker -------
    // The picker is the repoField plus a bounded list (repoList, rows repoRow<i>
    // in filtered order). `filteredRepos` is the shown list, `pickerIndex` the
    // highlighted row or -1. `lookupDone(typed, fullName, repoId)` delivers a
    // typed owner/repo lookup and emits lookupAccepted only if the field still
    // holds the typed text.

    function repoFixture() {
        return [
            {fullName: "Zed/zeta", id: 1, private: false},
            {fullName: "ana/Čaj", id: 2, private: true},
            {fullName: "Bob/caj-two", id: 3, private: false},
            {fullName: "bob/caj", id: 4, private: false},
            {fullName: "ab/c", id: 5, private: false},
            {fullName: "b/c", id: 6, private: false}
        ]
    }

    function openSettings(props) {
        var init = {width: 700, height: 600, visible: true,
            syncStatus: {authenticated: true, login: "u", scopes: []},
            lastPull: "", lastError: "", loadErrors: [], selection: {repo: "bob/caj"},
            binds: [], repos: repoFixture(), reposState: "ready"}
        for (var k in props) init[k] = props[k]
        var s = createTemporaryObject(settingsComp, tc, init)
        verify(s)
        var f = findChild(s, "repoField")
        tryVerify(function() { return f.activeFocus }, 1000, "the picker field takes focus")
        return s
    }

    function listed(s) {
        return s.filteredRepos.map(function(r) { return r.fullName })
    }

    function highlighted(s) {
        return s.pickerIndex < 0 ? "" : s.filteredRepos[s.pickerIndex].fullName
    }

    function test_picker_filters_in_stable_order_with_highlight() {
        var s = openSettings({})
        var f = findChild(s, "repoField")
        var chosen = spyComp.createObject(tc, {target: s, signalName: "repoChosen"})
        var typed = spyComp.createObject(tc, {target: s, signalName: "repoTyped"})
        compare(listed(s), ["ab/c", "ana/Čaj", "b/c", "bob/caj", "Bob/caj-two", "Zed/zeta"],
                "A to Z by lowercased fullName")
        compare(s.pickerIndex, -1, "no highlight before typing or an arrow")
        keyClick(Qt.Key_Return)
        compare(chosen.count, 0, "Enter on an empty field does nothing")
        compare(typed.count, 0)
        typeText("caj")
        compare(listed(s), ["ana/Čaj", "bob/caj", "Bob/caj-two"],
                "case- and accent-insensitive substring, order kept")
        compare(highlighted(s), "ana/Čaj", "without an exact match the first match is highlighted")
        f.text = "B/C"
        compare(listed(s), ["ab/c", "b/c", "bob/caj", "Bob/caj-two"])
        compare(highlighted(s), "b/c", "the exact match is highlighted")
        keyClick(Qt.Key_Down)
        compare(highlighted(s), "bob/caj")
        keyClick(Qt.Key_Down)
        keyClick(Qt.Key_Down)
        compare(highlighted(s), "ab/c", "Down wraps")
        keyClick(Qt.Key_Up)
        compare(highlighted(s), "Bob/caj-two", "Up wraps")
        keyClick(Qt.Key_Return)
        compare(chosen.count, 1, "Enter takes the highlight")
        compare(chosen.signalArguments[0][0], "Bob/caj-two")
        compare(typed.count, 0)
    }

    function test_picker_lookup_and_state_lines() {
        var s = openSettings({})
        var f = findChild(s, "repoField")
        var line = findChild(s, "repoStateLine")
        verify(line, "the picker has a state line")
        var typed = spyComp.createObject(tc, {target: s, signalName: "repoTyped"})
        var accepted = spyComp.createObject(tc, {target: s, signalName: "lookupAccepted"})
        var chosen = spyComp.createObject(tc, {target: s, signalName: "repoChosen"})
        f.text = "Some/Other"
        compare(listed(s).length, 0)
        verify(line.visible && /looks up owner\/repo/i.test(line.text), "zero matches explain the lookup: " + line.text)
        keyClick(Qt.Key_Return)
        compare(typed.count, 1, "Enter with zero matches runs the lookup")
        compare(typed.signalArguments[0][0], "Some/Other")
        compare(chosen.count, 0)
        f.text = "Some/Otherx"
        s.lookupDone("Some/Other", "Some/Other", 99)
        compare(accepted.count, 0, "a lookup for text no longer in the field is dropped")
        f.text = "Some/Other"
        s.lookupDone("Some/Other", "Some/Other", 99)
        compare(accepted.count, 1, "a lookup for the unchanged field applies")
        compare(accepted.signalArguments[0][0], "Some/Other")
        compare(accepted.signalArguments[0][1], 99)
        f.text = ""
        s.reposState = "loading"
        verify(line.visible && /loading/i.test(line.text), "loading line: " + line.text)
        s.reposState = "failed"
        verify(line.visible && /could not list/i.test(line.text), "could-not-list line: " + line.text)
    }

    function test_picker_is_one_tab_stop_with_bounded_rows() {
        var many = []
        for (var i = 0; i < 20; i++)
            many.push({fullName: "org/repo" + (i < 10 ? "0" + i : i), id: 100 + i, private: false})
        var s = openSettings({repos: many, selection: {repo: "org/repo03"}})
        var f = findChild(s, "repoField")
        var list = findChild(s, "repoList")
        verify(list, "the picker list")
        tryVerify(function() { return findChild(s, "repoRow3") !== null }, 2000)
        var row0 = findChild(s, "repoRow0")
        var shown = list.height / row0.height
        verify(shown >= 7.5 && shown <= 8.5, "about 8 rows show, got " + shown)
        verify(hasText(findChild(s, "repoRow3"), "current"), "the selected repo is marked current")
        verify(!hasText(row0, "current"))
        for (var k = 0; k < 13; k++) keyClick(Qt.Key_Down)
        compare(s.pickerIndex, 12)
        tryVerify(function() { return findChild(s, "repoRow12") !== null }, 2000)
        var row12 = findChild(s, "repoRow12")
        waitForRendering(list)
        var y = row12.mapToItem(list, 0, 0).y
        verify(y >= -0.5 && y + row12.height <= list.height + 0.5, "the highlight stays in view, row at " + y)
        var chosen = spyComp.createObject(tc, {target: s, signalName: "repoChosen"})
        mouseClick(row12)
        compare(chosen.count, 1, "a click uses the repoChosen path")
        compare(chosen.signalArguments[0][0], "org/repo12")
        f.forceActiveFocus()
        var before = f.text
        keyClick(Qt.Key_Tab)
        verify(!f.activeFocus, "Tab leaves the picker")
        compare(f.text, before, "Tab inserts nothing")
        for (var r = 0; r < 20; r++) {
            var row = findChild(s, "repoRow" + r)
            if (row) verify(!row.activeFocus, "rows are not separate Tab stops")
        }
    }

    function test_picker_highlight_follows_repo_id_across_refresh() {
        var s = openSettings({})
        keyClick(Qt.Key_Down)
        compare(highlighted(s), "ab/c", "an arrow shows the highlight without typing")
        keyClick(Qt.Key_Down)
        keyClick(Qt.Key_Down)
        keyClick(Qt.Key_Down)
        compare(highlighted(s), "bob/caj")
        var refreshed = repoFixture().concat([{fullName: "aaa/new", id: 7, private: false}])
        s.repos = refreshed
        compare(highlighted(s), "bob/caj", "the highlight follows the repo id across a refresh")
        s.repos = refreshed.filter(function(r) { return r.id !== 4 })
        compare(s.pickerIndex, -1, "the highlight clears when its repo is gone")
    }

    function test_picker_esc_clears_filter_first() {
        var s = openSettings({})
        var back = spyComp.createObject(tc, {target: s, signalName: "backRequested"})
        keyClick("x")
        keyClick(Qt.Key_Escape)
        compare(findChild(s, "repoField").text, "", "Esc clears a non-empty filter")
        compare(back.count, 0)
        keyClick(Qt.Key_Escape)
        compare(back.count, 1, "Esc on an empty filter keeps its meaning")
    }

    function test_settings_tab_scrolls_focused_control_into_view() {
        var many = []
        for (var n = 0; n < 30; n++) many.push({fullName: "owner/repo-" + n, id: 100 + n, private: false})
        var s = openSettings({height: 420, repos: many})
        var names = ["syncNowButton", "chordField", "resetUsageButton"]
        for (var k = 0; k < names.length; k++) {
            var target = findChild(s, names[k])
            for (var i = 0; i < 12 && !target.activeFocus; i++) keyClick(Qt.Key_Tab)
            verify(target.activeFocus, names[k] + " is reachable by Tab")
            var top = target.mapToItem(s, 0, 0).y
            verify(top >= 0 && top + target.height <= s.height,
                   names[k] + " is inside the visible area, top " + top + " height " + target.height)
        }
    }

    function test_settings_controls_reachable_by_tab_and_enter() {
        var copied = []
        var s = openSettings({libraryMismatch: "reconfirm: switching repos discards the current draft",
                              copyText: function(t) { copied.push(t) }})
        var confirm = spyComp.createObject(tc, {target: s, signalName: "confirmReimport"})
        var sync = spyComp.createObject(tc, {target: s, signalName: "syncNow"})
        var reset = spyComp.createObject(tc, {target: s, signalName: "resetUsage"})
        function tabTo(name) {
            var target = findChild(s, name)
            verify(target && target.visible, name + " shows")
            for (var i = 0; i < 12 && !target.activeFocus; i++) keyClick(Qt.Key_Tab)
            verify(target.activeFocus, name + " is reachable by Tab")
        }
        tabTo("confirmReimportButton")
        keyClick(Qt.Key_Return)
        compare(confirm.count, 1)
        tabTo("syncNowButton")
        keyClick(Qt.Key_Enter)
        compare(sync.count, 1)
        tabTo("resetUsageButton")
        keyClick(Qt.Key_Space)
        compare(reset.count, 1)
        findChild(s, "chordField").text = "SUPER + ALT + P"
        tabTo("copyBindButton")
        keyClick(Qt.Key_Return)
        compare(copied.length, 1)
        compare(copied[0], 'o.bind("SUPER + ALT + P", "Varhop prompts", { panel = "ivan.varhop" })')
    }

    // ------- Plain text everywhere -------

    function test_plain_text_format() {
        var hostile = "<b>x</b> and <img src='http://127.0.0.1:9/x'>"
        var s = createTemporaryObject(searchComp, tc, {
            width: 700, height: 500, visible: true,
            rows: [{id: "p1", title: hostile, detail: hostile, fileName: "f.md", draft: false, snippet: hostile}],
            draftPromptId: "", query: ""
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
