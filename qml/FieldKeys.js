// Shared text-field key handling. Sets event.accepted; unhandled keys stay
// unaccepted so they reach the item's native handling or parent Keys.
//   paste both chords natively (Qt never pastes Ctrl+Shift+V itself)
//   copySelection: Ctrl+C/Ctrl+Shift+C copy the field's text selection
//   inertCtrlR: picker fields swallow Ctrl+R; others let it propagate
function handle(event, field, opts) {
    var ctrl = event.modifiers === Qt.ControlModifier
    var ctrlShift = event.modifiers === (Qt.ControlModifier | Qt.ShiftModifier)
    if ((ctrl || ctrlShift) && event.key === Qt.Key_V) {
        field.paste()
        event.accepted = true
        return
    }
    if ((ctrl || ctrlShift) && event.key === Qt.Key_C) {
        if (opts.copySelection && field.selectedText !== "") {
            field.copy()
            event.accepted = true
        }
        return
    }
    if (ctrl && event.key === Qt.Key_R) {
        event.accepted = opts.inertCtrlR === true
        return
    }
}
