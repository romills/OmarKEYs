import QtQuick
import qs.Commons

Rectangle {
  id: section

  property string title: ""
  property int sectionNumber: 0
  property var rows: []
  property string selectedKeys: ""
  property string selectedAction: ""
  property string fontFamily: Style.font.menuFamily
  property color foreground: Color.menu.text
  property color borderColor: Color.menu.border
  property color chipBg: Color.menu.selectedBackground
  property color chipFg: Color.menu.selectedText
  property color selectedBg: Color.menu.selectedBackground
  property color selectedFg: Color.menu.selectedText
  property string chipStyle: "full"
  property string rowLayout: "keys"
  property real fontScale: 1.0
  property real iconScale: 1.35
  property bool omarchyActive: false
  signal rowClicked(string keys, string action)
  signal rowHighlighted(var item)
  signal recordRequested(var item)
  signal restoreRequested(var item)

  readonly property string numberLabel: {
    if (section.sectionNumber >= 1 && section.sectionNumber <= 9)
      return "[Ctrl-" + section.sectionNumber + "]"
    if (section.sectionNumber === 10)
      return "[Ctrl-0]"
    return ""
  }

  implicitHeight: sectionCol.implicitHeight + Style.spacing.md
  radius: 6
  color: "transparent"
  border.width: 1
  border.color: section.borderColor

  Column {
    id: sectionCol
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: Style.spacing.sm
    spacing: Style.space(5)

    Item {
      width: sectionCol.width
      height: titleRow.height

      Row {
        id: titleRow
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 8

        Text {
          text: section.title
          textFormat: Text.PlainText
          color: Color.menu.selectedText
          font.family: section.fontFamily
          font.pixelSize: Math.round(Style.font.caption * section.fontScale)
          font.bold: true
          font.capitalization: Font.AllUppercase
        }

        Text {
          visible: section.numberLabel.length > 0
          text: section.numberLabel
          textFormat: Text.PlainText
          color: section.selectedFg
          font.family: section.fontFamily
          font.pixelSize: Math.round(Style.font.caption * section.fontScale)
          font.bold: true
          opacity: 0.8
        }
      }
    }

    Repeater {
      model: section.rows
      delegate: KeymapRow {
        width: sectionCol.width
        selected: modelData.keys === section.selectedKeys
          && modelData.action === section.selectedAction
        fontFamily: section.fontFamily
        foreground: section.foreground
        borderColor: section.borderColor
        chipBg: section.chipBg
        chipFg: section.chipFg
        selectedBg: section.selectedBg
        selectedFg: section.selectedFg
        chipStyle: section.chipStyle
        rowLayout: section.rowLayout
        fontScale: section.fontScale
        iconScale: section.iconScale
        omarchyActive: section.omarchyActive
        onClicked: function(keys, action) { section.rowClicked(keys, action) }
        onHighlighted: function(item) { section.rowHighlighted(item) }
        onRecordRequested: function(item) { section.recordRequested(item) }
        onRestoreRequested: function(item) { section.restoreRequested(item) }
      }
    }
  }
}
