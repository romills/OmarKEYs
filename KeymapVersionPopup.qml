import QtQuick
import qs.Commons

// Which version is installed, read from the manifest and nothing else.
//
// This was the channel picker: Channel and Versions tabs, a 1.0/2.0 track
// row, a tree of every tagged release, and a cloud button that fetched and
// checked out. All of it is moving to OmarVerTester, a tool for picking and
// installing versions of any Omarchy plugin -- which is where it belongs. A
// keymap overlay reporting its version needs a label, not a package
// manager's privileges.
//
// Going through the manifest rather than git also means this works on every
// install. Not every plugin directory is a git clone -- several on a normal
// machine are plain directories -- and the version is a fact the install
// already states either way.
//
// The intended end state is that this corner finds OmarVerTester if it is
// installed and offers what that tool knows: which channel, which commit,
// whether something newer is waiting. Until it exists, this reports and
// stops there.
Rectangle {
  id: popup

  property var host: null
  property color foreground: Color.menu.text
  property color background: Color.menu.background
  property color borderColor: Color.menu.border
  property color chipFg: Color.menu.selectedText
  property string fontFamily: Style.font.menuFamily

  readonly property int labelSize: Style.font.caption
  readonly property string version: (host && host.pluginVersion) ? host.pluginVersion : "unknown"
  readonly property string pluginId: host ? host.pluginId() : ""

  width: Style.space(220)
  implicitHeight: content.implicitHeight + Style.spacing.sm * 2
  height: implicitHeight
  radius: 6
  color: popup.background
  border.width: 1
  border.color: popup.borderColor

  // Swallow clicks, so one inside the popup does not reach the scrim behind
  // it and dismiss the overlay.
  MouseArea { anchors.fill: parent; onClicked: {} }

  Column {
    id: content
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: Style.spacing.sm
    spacing: Style.space(3)

    Text {
      width: content.width
      text: "Version " + popup.version
      textFormat: Text.PlainText
      color: popup.chipFg
      font.family: popup.fontFamily
      font.pixelSize: Math.round(popup.labelSize * 1.3)
      font.bold: true
      elide: Text.ElideRight
    }

    // The id, because a bug report wants to name the thing it is about and
    // "OmarKEYS" is not what the plugin is called on disk.
    Text {
      width: content.width
      visible: popup.pluginId.length > 0
      text: popup.pluginId
      textFormat: Text.PlainText
      color: popup.foreground
      opacity: 0.6
      font.family: popup.fontFamily
      font.pixelSize: popup.labelSize
      elide: Text.ElideRight
    }
  }
}
