import QtQuick
import "import.mjs" as Imp
import "tokens.mjs" as Tok
import "rebuild.mjs" as Reb
import "search.mjs" as Sea
import "usage.mjs" as Use

Item {
    // Qt.exit schedules quit; the last scheduled code wins. Collect failures
    // and exit exactly once at the end.
    Component.onCompleted: {
        var failures = [];
        function ok(cond, label) {
            if (!cond)
                failures.push(label);
        }

        var lib = Imp.importLibrary([{path: "prompts/c/x.md", text: "---\ntitle: Q\n---\nhi {{A}}"}]);
        ok(lib.prompts.length === 1 && lib.prompts[0].title === "Q", "importLibrary");
        ok(lib.prompts[0].names.length === 1 && lib.prompts[0].names[0] === "A", "names");

        var segs = Tok.splitSegments("a {{B}}");
        ok(segs.length === 2 && segs[1].kind === "token" && segs[1].name === "B", "splitSegments");
        var names = Tok.uniqueNames("{{B}} {{A}} {{B}}");
        ok(names.length === 2 && names[0] === "B" && names[1] === "A", "uniqueNames");

        var built = Reb.rebuild(segs, {B: "v"});
        ok(built.text === "a v" && built.unset.length === 0, "rebuild");

        ok(Sea.fold("Đorđe") === "dorde", "fold");
        ok(Sea.DISPLAY_CHUNK === 50, "DISPLAY_CHUNK");
        var usage = Use.resetUsage();
        var rows = Sea.rank(lib.prompts, "q", usage, Date.now());
        ok(rows.length === 1 && rows[0].id === "prompts/c/x.md", "rank");

        var u1 = Use.recordCopy(usage, "prompts/c/x.md", 1000);
        ok(u1.entries["prompts/c/x.md"].score === 1, "recordCopy");
        ok(Use.HALF_LIFE_MS === 1209600000, "HALF_LIFE_MS");
        var parsed = Use.parseUsage(JSON.stringify(u1));
        ok(parsed.state !== undefined && parsed.state.entries["prompts/c/x.md"].score === 1, "parseUsage");

        if (failures.length > 0) {
            console.error("smoke failures: " + failures.join(", "));
            Qt.exit(1);
        } else {
            console.log("smoke ok");
            Qt.exit(0);
        }
    }
}
