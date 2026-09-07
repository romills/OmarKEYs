import QtQuick
import qs.Commons

Flickable {
  id: board
  property Item host: null

  clip: true
  contentWidth: width
  contentHeight: columnsRow.height
  boundsBehavior: Flickable.StopAtBounds
  activeFocusOnTab: false

  readonly property color selectedBg: host
    ? Qt.rgba(host.chipFg.r, host.chipFg.g, host.chipFg.b, 0.32)
    : "transparent"

  function revealItem(item) {
    if (!item || board.height <= 0)
      return
    var p = item.mapToItem(board.contentItem, 0, 0)
    if (!p)
      return
    var y = p.y
    if (y < 0 || y > board.contentHeight)
      return
    var bottom = y + Math.max(1, item.height)
    var pad = Style.spacing.sm
    if (y < board.contentY)
      board.contentY = Math.max(0, y - pad)
    else if (bottom > board.contentY + board.height)
      board.contentY = Math.min(
        Math.max(0, board.contentHeight - board.height),
        bottom - board.height + pad)
  }

  // One section card for both columns so a layout tweak cannot land on
  // the left Repeater and miss the right.
  component SectionCard: KeymapSection {
    required property int index
    required property var modelData
    required property int numberOffset

    title: modelData.title
    sectionNumber: index * 2 + numberOffset
    rows: modelData.rows
    selectedKeys: host.selectedKeys
    selectedAction: host.selectedAction
    fontFamily: host.fontFamily
    foreground: host.foreground
    borderColor: host.border
    chipBg: host.chipBg
    chipFg: host.chipFg
    selectedBg: board.selectedBg
    selectedFg: host.chipFg
    chipStyle: host.chipStyle
    rowLayout: host.rowLayout
    fontScale: host.fontScale
    iconScale: host.iconScale
    onRowClicked: function(keys, action) { host.activateRow(keys, action) }
    onRowHighlighted: function(item) { Qt.callLater(function() { board.revealItem(item) }) }
  }

  Row {
    id: columnsRow
    width: parent.width
    spacing: Style.spacing.md

    Column {
      id: leftCol
      width: (columnsRow.width - columnsRow.spacing) / 2
      spacing: Style.spacing.sm

      Repeater {
        model: host ? host.leftSections : []
        delegate: SectionCard {
          width: leftCol.width
          numberOffset: 1
        }
      }
    }

    Column {
      id: rightCol
      width: (columnsRow.width - columnsRow.spacing) / 2
      spacing: Style.spacing.sm

      Repeater {
        model: host ? host.rightSections : []
        delegate: SectionCard {
          width: rightCol.width
          numberOffset: 2
        }
      }
    }
  }
}
