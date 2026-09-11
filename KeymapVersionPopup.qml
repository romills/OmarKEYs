import QtQuick
import qs.Commons

// What is running, and nothing you can do about it from here.
//
// This used to be the channel picker: tabs for Channel and Versions, a
// release-track row, a tree of every tagged release, and a cloud button
// that fetched and switched. All of that is moving to OmarVerTester, a
// tool whose job is picking and installing versions of any Omarchy
// plugin -- which is where it belongs. A keymap overlay answering
// "which version am I running" is a label; a keymap overlay fetching and
// executing remote git is a package manager wearing a costume.
//
// The intended end state for this corner is that clicking it opens
// OmarVerTester. Until that exists, it reports and stops there.
Rectangle {
  id: popup

  property var host: null
  property color foreground: Color.menu.text
  property color background: Color.menu.background
  property color borderColor: Color.menu.border
  property color chipFg: Color.menu.selectedText
  property string fontFamily: Style.font.menuFamily

  readonly property int labelSize: Style.font.caption

  width: Style.space(260)
  implicitHeight: content.implicitHeight + Style.spacing.sm * 2
  height: implicitHeight
  radius: 6
  color: popup.background
  border.width: 1
  border.color: popup.borderColor

  // Swallow clicks so one inside the popup does not reach the scrim behind
  // it and dismiss the overlay.
  MouseArea { anchors.fill: parent; onClicked: {} }

  Column {
    id: content
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: Style.spacing.sm
    spacing: Style.space(3)

    // One fact per line, each labelled. As a single run they ran together
    // into something that had to be parsed rather than read.
    //
    // Version leads: it is the question the corner asks. The rest says
    // which build of it, for anyone reporting a bug.
    Repeater {
      model: [
        { label: "Version", value: (host && host.pluginVersion) ? host.pluginVersion : "—",
          lead: true },
        { label: "Updated", value: (host && host.gitDate) ? host.gitDate : "—",
          lead: false },
        { label: "Channel", value: !host ? "—"
          : host.channelLabel(host.gitChannel)
            + (host.gitChannel === "untested" && host.gitBranch
              ? "  ·  " + host.gitBranch : ""),
          lead: false },
        { label: "Hash", value: (host && host.gitHash) ? host.gitHash : "—",
          lead: false }
      ]
      delegate: Text {
        required property var modelData
        width: content.width
        text: modelData.label + ": " + modelData.value
        textFormat: Text.PlainText
        color: modelData.lead ? popup.chipFg : popup.foreground
        opacity: modelData.lead ? 1 : 0.85
        font.family: popup.fontFamily
        font.pixelSize: popup.labelSize
        font.bold: modelData.lead
        elide: Text.ElideRight
      }
    }

    // The checkout moved after this shell loaded, so the hash above is not
    // the code on screen. Worth saying outright: it looks exactly like a
    // change that failed to arrive. Still true with nothing here to switch
    // with -- something else moved the checkout, and this is the only
    // place that would notice.
    Text {
      width: content.width
      visible: !!(host && host.shellStale)
      text: "Running " + (host ? host.loadedHash : "") + " — restart the shell to load "
        + (host ? host.gitHash : "")
      textFormat: Text.PlainText
      color: popup.chipFg
      wrapMode: Text.WordWrap
      font.family: popup.fontFamily
      font.pixelSize: popup.labelSize
    }

    Text {
      width: content.width
      visible: !!(host && host.gitError)
      text: host ? host.gitError : ""
      textFormat: Text.PlainText
      color: popup.foreground
      opacity: 0.85
      wrapMode: Text.WordWrap
      font.family: popup.fontFamily
      font.pixelSize: popup.labelSize
    }
  }
}
