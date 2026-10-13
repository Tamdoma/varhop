import QtQuick
import QtQuick.Controls
import QtTest
import "testing"

// Component checks for the card: the fixed header, view routing and focus
// between header and body. Card imports no Quickshell module; Varhop.qml wraps
// it in the Omarchy surface and feeds it Commons.Color and Style.
TestCase {
    id: tc
    name: "VarhopCard"
    when: windowShown
    width: 900
    height: 700
    visible: true

    Component { id: themeComp; FakeTheme {} }
    Component { id: tokensComp; FakeTokens {} }
    Component { id: cardComp; Card {} }
    Component { id: spyComp; SignalSpy {} }

    function allChildren(root) {
        var out = []
        var kids = root.children || []
        for (var i = 0; i < kids.length; i++) {
            out.push(kids[i])
            out = out.concat(allChildren(kids[i]))
        }
        return out
    }

    function textItems(root) {
        return allChildren(root).filter(function(it) {
            return it.visible && it.text !== undefined && it.font !== undefined && it.color !== undefined
        })
    }

    function textsUnder(root, needle) {
        return textItems(root).filter(function(it) { return String(it.text).indexOf(needle) !== -1 })
    }

    function prompts() {
        return [
            {id: "prompts/dev/deploy.md", title: "Deploy prod", body: "Ship {{X}} now", names: ["X"]},
            {id: "prompts/dev/notes.md", title: "Notes", body: "Plain notes", names: []}
        ]
    }

    function rows() {
        return [
            {id: "prompts/dev/deploy.md", title: "Deploy prod", detail: "dev", fileName: "deploy.md", draft: false, snippet: ""},
            {id: "prompts/dev/notes.md", title: "Notes", detail: "dev", fileName: "notes.md", draft: false, snippet: ""}
        ]
    }

    function makeCard(props) {
        var theme = themeComp.createObject(tc)
        var tokens = tokensComp.createObject(tc)
        var init = {
            width: 560, height: 480, visible: true, focus: true,
            theme: theme, tokens: tokens,
            library: {prompts: prompts()}, rows: rows(),
            selection: {repo: "Tamdoma/varhop-prompts"}, libraryMismatch: "",
            syncStatus: {authenticated: true, login: "u", scopes: []},
            repos: [{fullName: "Tamdoma/varhop-prompts", id: 1, private: false}], reposState: "ready",
            binds: [], lastPull: "", lastError: "", loadErrors: [],
            copier: null, copyText: function(t) {}
        }
        for (var k in props) init[k] = props[k]
        var c = createTemporaryObject(cardComp, tc, init)
        verify(c, "card instantiates")
        c.forceActiveFocus()
        c.route()
        tryVerify(function() { return c.body !== null && c.body !== undefined }, 1000, "the view body loads")
        return c
    }

    function header(c, name) {
        var it = findChild(c, name)
        verify(it, name + " exists")
        return it
    }

    function headerFocused(c) {
        return header(c, "backButton").activeFocus || header(c, "settingsButton").activeFocus
    }

    function bodyHasFocus(c) {
        return c.body && (c.body.activeFocus || allChildren(c.body).some(function(i) { return i.activeFocus }))
    }

    // Search with query "de", Deploy prod opened, value X typed as "v".
    function toEditor(c) {
        var q = findChild(c.body, "queryField")
        tryVerify(function() { return q.activeFocus }, 1000)
        keyClick("d")
        keyClick("e")
        tryCompare(c, "lastQuery", "de")
        keyClick(Qt.Key_Return)
        tryCompare(c, "view", "editor")
        var f = findChild(c.body, "editorText")
        tryVerify(function() { return f && f.activeFocus }, 1000)
        keyClick("v")
        tryVerify(function() { return c.body.valueOf("X") === "v" }, 1000)
    }

    function snapshot(c) {
        return JSON.stringify({
            view: c.view, cameFrom: c.cameFrom, lastQuery: c.lastQuery, selectedId: c.selectedId,
            draft: c.draft ? {promptId: c.draft.promptId, values: c.draft.values} : null,
            value: c.view === "editor" ? c.body.valueOf("X") : null
        })
    }

    function pressBy(c, how, buttonName, key, mods) {
        if (how === "click") {
            mouseClick(header(c, buttonName))
        } else if (how === "enter") {
            keyClick(Qt.Key_Tab, Qt.ControlModifier)
            var b = header(c, buttonName)
            for (var i = 0; i < 4 && !b.activeFocus; i++) keyClick(Qt.Key_Tab)
            verify(b.activeFocus, buttonName + " takes focus in the header")
            keyClick(Qt.Key_Return)
        } else {
            keyClick(key, mods)
        }
    }

    // ------- Header per view -------

    function test_header_rows_titles_and_shortcuts() {
        var c = makeCard({})
        compare(c.view, "search")
        var title = header(c, "headerTitle")
        var back = header(c, "backButton")
        var settings = header(c, "settingsButton")
        compare(title.text, "Prompts")
        verify(!back.visible, "search has no Back")
        verify(settings.visible)
        verify(textsUnder(settings, "Settings").length > 0)
        var sc = textsUnder(settings, "Ctrl+,")
        verify(sc.length > 0, "the shortcut is printed")
        verify(Qt.colorEqual(sc[0].color, c.theme.muted), "the shortcut is muted")
        verify(header(c, "header").y < c.body.mapToItem(c, 0, 0).y, "the header sits above the body")

        toEditor(c)
        compare(title.text, "Deploy prod")
        compare(title.textFormat, Text.PlainText)
        compare(title.elide, Text.ElideLeft, "the prompt title elides first")
        verify(back.visible && settings.visible)
        verify(textsUnder(back, "Back").length > 0)
        var bsc = textsUnder(back, "Ctrl+P")
        verify(bsc.length > 0 && Qt.colorEqual(bsc[0].color, c.theme.muted))

        keyClick(Qt.Key_Comma, Qt.ControlModifier)
        tryCompare(c, "view", "settings")
        compare(title.text, "Settings")
        verify(back.visible && !settings.visible, "settings has Back and an empty right side")
        verify(textsUnder(back, "Back").length > 0)
        verify(textsUnder(back, "Ctrl+,").length > 0)
    }

    function test_settings_without_return_shows_close() {
        var c = makeCard({selection: null})
        compare(c.view, "settings")
        var back = header(c, "backButton")
        verify(back.visible)
        verify(textsUnder(back, "Close").length > 0, "Close when backRequested would hide")
        var hidden = spyComp.createObject(tc, {target: c, signalName: "hideRequested"})
        mouseClick(back)
        compare(hidden.count, 1)
        pressBy(c, "enter", "backButton")
        compare(hidden.count, 2)
        keyClick(Qt.Key_Comma, Qt.ControlModifier)
        compare(hidden.count, 3, "click, header Enter and Ctrl+, act alike")
    }

    // ------- Same state by click, header Enter and shortcut -------

    function test_editor_back_same_state_three_ways() {
        var seen = []
        var ways = ["click", "enter", "key"]
        for (var i = 0; i < ways.length; i++) {
            var c = makeCard({})
            toEditor(c)
            pressBy(c, ways[i], "backButton", Qt.Key_P, Qt.ControlModifier)
            tryCompare(c, "view", "search")
            seen.push(snapshot(c))
            c.destroy()
        }
        compare(seen[1], seen[0], "header Enter matches the click")
        compare(seen[2], seen[0], "Ctrl+P matches the click")
        var s = JSON.parse(seen[0])
        compare(s.lastQuery, "de")
        compare(s.selectedId, "prompts/dev/deploy.md")
        compare(s.draft.values.X, "v")
    }

    function test_settings_round_trip_from_editor_three_ways() {
        var seen = []
        var ways = ["click", "enter", "key"]
        for (var i = 0; i < ways.length; i++) {
            var c = makeCard({})
            toEditor(c)
            pressBy(c, ways[i], "settingsButton", Qt.Key_Comma, Qt.ControlModifier)
            tryCompare(c, "view", "settings")
            compare(c.cameFrom, "editor")
            pressBy(c, ways[i], "backButton", Qt.Key_Comma, Qt.ControlModifier)
            tryCompare(c, "view", "editor")
            tryVerify(function() { return c.body.valueOf && c.body.valueOf("X") === "v" }, 1000, "the draft value survives")
            seen.push(snapshot(c))
            c.destroy()
        }
        compare(seen[1], seen[0])
        compare(seen[2], seen[0])
    }

    function test_search_settings_round_trip_three_ways() {
        var seen = []
        var ways = ["click", "enter", "key"]
        for (var i = 0; i < ways.length; i++) {
            var c = makeCard({})
            keyClick("n")
            tryCompare(c, "lastQuery", "n")
            pressBy(c, ways[i], "settingsButton", Qt.Key_Comma, Qt.ControlModifier)
            tryCompare(c, "view", "settings")
            pressBy(c, ways[i], "backButton", Qt.Key_Comma, Qt.ControlModifier)
            tryCompare(c, "view", "search")
            tryCompare(findChild(c.body, "queryField"), "text", "n")
            seen.push(snapshot(c))
            c.destroy()
        }
        compare(seen[1], seen[0])
        compare(seen[2], seen[0])
    }

    function test_library_mismatch_route() {
        var c = makeCard({libraryMismatch: "reconfirm: switching repos discards the current draft"})
        compare(c.view, "settings", "a mismatch lands on settings")
        compare(c.cameFrom, "")
        var back = header(c, "backButton")
        verify(textsUnder(back, "Back").length > 0, "with a selection, Back leads to search")
        mouseClick(back)
        tryCompare(c, "view", "search")
    }

    // ------- Focus between body and header -------

    function test_ctrl_tab_round_trip_keeps_body_state() {
        var c = makeCard({})
        verify(!headerFocused(c), "nothing gives a header button the initial focus")
        keyClick(Qt.Key_Down)
        var sel = c.selectedId
        keyClick(Qt.Key_Tab, Qt.ControlModifier)
        verify(headerFocused(c), "Ctrl+Tab reaches the header from search")
        keyClick(Qt.Key_Escape)
        verify(!headerFocused(c) && bodyHasFocus(c), "Esc returns to the body")
        compare(c.selectedId, sel)
        compare(c.view, "search", "Esc in the header does not act on the body")

        var hidden = spyComp.createObject(tc, {target: c, signalName: "hideRequested"})
        toEditor(c)
        var f = findChild(c.body, "editorText")
        keyClick(Qt.Key_Left, Qt.ShiftModifier)
        var cur = f.cursorPosition, a = f.selectionStart, b = f.selectionEnd, name = c.body.activeName
        verify(b > a, "a selection exists")
        keyClick(Qt.Key_Tab, Qt.ControlModifier)
        verify(headerFocused(c), "Ctrl+Tab reaches the header from the editor")
        keyClick(Qt.Key_Tab, Qt.ControlModifier)
        tryVerify(function() { return f.activeFocus }, 500, "Ctrl+Tab returns to the body")
        compare(f.cursorPosition, cur)
        compare(f.selectionStart, a)
        compare(f.selectionEnd, b)
        compare(c.body.activeName, name)
        compare(hidden.count, 0)

        keyClick(Qt.Key_Comma, Qt.ControlModifier)
        tryCompare(c, "view", "settings")
        keyClick(Qt.Key_Down)
        var pick = c.body.pickerIndex
        verify(pick >= 0)
        keyClick(Qt.Key_Tab, Qt.ControlModifier)
        verify(headerFocused(c), "Ctrl+Tab reaches the header from settings")
        keyClick(Qt.Key_Escape)
        compare(c.view, "settings")
        compare(c.body.pickerIndex, pick, "the picker highlight is unchanged")
    }

    function test_plain_tab_reaches_header_and_space_presses() {
        var c = makeCard({})
        for (var i = 0; i < 4 && !headerFocused(c); i++) keyClick(Qt.Key_Tab)
        verify(headerFocused(c), "plain Tab reaches the header in search")
        verify(header(c, "settingsButton").activeFocus)
        keyClick(Qt.Key_Space)
        tryCompare(c, "view", "settings", 1000, "Space presses the focused button")
        for (var j = 0; j < 20 && !headerFocused(c); j++) keyClick(Qt.Key_Tab)
        verify(headerFocused(c), "plain Tab reaches the header in settings")
        keyClick(Qt.Key_Enter)
        tryCompare(c, "view", "search", 1000, "Enter presses the focused button")
    }

    function test_esc_in_body_keeps_its_meaning() {
        var c = makeCard({})
        var hidden = spyComp.createObject(tc, {target: c, signalName: "hideRequested"})
        keyClick("n")
        keyClick(Qt.Key_Escape)
        compare(findChild(c.body, "queryField").text, "", "search Esc clears the query first")
        compare(hidden.count, 0)
        keyClick(Qt.Key_Escape)
        compare(hidden.count, 1, "search Esc on an empty query hides")
        toEditor(c)
        keyClick(Qt.Key_Escape)
        compare(hidden.count, 2, "editor Esc hides")
        c.view = "search"
        keyClick(Qt.Key_Comma, Qt.ControlModifier)
        tryCompare(c, "view", "settings")
        keyClick(Qt.Key_Escape)
        tryCompare(c, "view", "search", 1000, "settings Esc on an empty filter goes back")
    }

    // ------- Look -------

    function eachView(c, check) {
        check("search")
        toEditor(c)
        check("editor")
        keyClick(Qt.Key_Comma, Qt.ControlModifier)
        tryCompare(c, "view", "settings")
        check("settings")
    }

    function test_fonts_follow_menu_family_and_size_tokens() {
        var c = makeCard({})
        var t = c.tokens
        eachView(c, function(view) {
            var items = textItems(c)
            verify(items.length > 0)
            for (var i = 0; i < items.length; i++)
                compare(items[i].font.family, t.font.menuFamily, view + ": " + items[i] + " uses menuFamily")
            compare(header(c, "headerTitle").font.pixelSize, t.font.heading, view + ": header title is heading size")
            var button = header(c, view === "search" ? "settingsButton" : "backButton")
            var label = textsUnder(button, view === "search" ? "Settings" : "Back")[0]
            compare(label.font.pixelSize, t.font.title, view + ": button labels are title size")
            var shortcut = textsUnder(button, "Ctrl+")[0]
            compare(shortcut.font.pixelSize, t.font.body, view + ": shortcuts are body size")
        })
        // Body roles per view.
        var c2 = makeCard({})
        compare(findChild(c2.body, "queryField").font.pixelSize, t.font.heading, "query is heading size")
        toEditor(c2)
        compare(findChild(c2.body, "editorText").font.pixelSize, t.font.heading, "editor body is heading size")
    }

    function test_theme_roles_bind_live() {
        var c = makeCard({})
        verify(Qt.colorEqual(c.theme.menu.text, "#00ff00") && !Qt.colorEqual(c.theme.foreground, c.theme.menu.text),
               "the test palette separates menu.text from foreground")
        eachView(c, function(view) {
            var title = header(c, "headerTitle")
            verify(Qt.colorEqual(title.color, c.theme.menu.text), view + ": title uses menu.text")
            var items = textItems(c)
            for (var i = 0; i < items.length; i++)
                verify(!Qt.colorEqual(items[i].color, c.theme.foreground), view + ": " + items[i].text + " avoids foreground")
            c.theme.menu.text = view === "search" ? "#00ffff" : view === "editor" ? "#ff00ff" : "#ffff00"
            c.theme.muted = view === "search" ? "#111111" : view === "editor" ? "#222222" : "#333333"
            verify(Qt.colorEqual(title.color, c.theme.menu.text), view + ": title follows a live menu.text change")
            var muted = textsUnder(c, "Ctrl+")
            verify(muted.length > 0)
            verify(Qt.colorEqual(muted[0].color, c.theme.muted), view + ": shortcut follows a live muted change")
        })
    }

    function test_larger_base_does_not_clip() {
        var c = makeCard({width: 800, height: 700})
        c.tokens.base = 24
        eachView(c, function(view) {
            waitForRendering(c)
            var items = textItems(c)
            for (var i = 0; i < items.length; i++) {
                var it = items[i]
                if (it.height <= 0 || it.contentHeight === undefined) continue
                verify(it.contentHeight <= it.height + 1,
                       view + ": '" + it.text + "' fits its height, " + it.contentHeight + " > " + it.height)
            }
            var h = header(c, "header")
            var buttons = [header(c, "backButton"), header(c, "settingsButton")]
            for (var j = 0; j < buttons.length; j++)
                if (buttons[j].visible)
                    verify(buttons[j].height <= h.height + 0.5, view + ": header buttons fit the header row")
        })
    }
}
