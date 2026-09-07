import QtQuick
import qs.Commons

Item {
  id: popup

  property Item host: null
  visible: !!(host && host.recordOpen)
  z: 30

  readonly property color fg: host ? host.foreground : Color.menu.text
  readonly property color bg: host ? host.background : Color.menu.background
  readonly property color bd: host ? host.border : Color.menu.border
  readonly property color chipBg: host ? host.chipBg : Color.menu.selectedBackground
  readonly property color chipFg: host ? host.chipFg : Color.menu.selectedText
  readonly property string fontFamily: host ? host.fontFamily : Style.font.menuFamily
  readonly property bool canSave: !!(host && host.recordCanSave)
  readonly property bool remapped: !!(host && host.recordRemapped)
  readonly property var occupant: host ? host.recordOccupant : null
  readonly property string captured: host ? (host.recordCaptured || "") : ""
  readonly property string actionName: host && host.recordRow ? (host.recordRow.action || "") : ""
  readonly property string currentKeys: host && host.recordRow ? (host.recordRow.keys || "") : ""
  readonly property string defaultKeys: host ? (host.recordDefaultKeys || "") : ""

  Rectangle {
    anchors.fill: parent
    color: host ? host.scrim : Color.menu.scrim
    opacity: 0.55
    MouseArea {
      anchors.fill: parent
      onClicked: if (host) host.closeRecord()
    }
  }

  Rectangle {
    id: card
    width: Math.min(520, parent.width - Style.space(48))
    implicitHeight: cardCol.implicitHeight + Style.spacing.md * 2
    height: implicitHeight
    radius: host && host.cornerRadius ? host.cornerRadius : 8
    anchors.centerIn: parent
    color: popup.bg
    border.width: 1
    border.color: popup.bd

    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }

    Column {
      id: cardCol
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: Style.spacing.md
      spacing: Style.spacing.sm

      Text {
        width: parent.width
        text: popup.actionName ? ("Record “" + popup.actionName + "”") : "Record shortcut"
        textFormat: Text.PlainText
        color: popup.fg
        font.family: popup.fontFamily
        font.pixelSize: Style.font.heading
        wrapMode: Text.WordWrap
      }

      Text {
        width: parent.width
        visible: popup.defaultKeys.length > 0
        text: "Default: " + popup.defaultKeys
        textFormat: Text.PlainText
        color: popup.fg
        opacity: 0.7
        font.family: popup.fontFamily
        font.pixelSize: Style.font.caption
      }

      Text {
        width: parent.width
        text: "Now: " + (popup.currentKeys || "—")
        textFormat: Text.PlainText
        color: popup.fg
        opacity: 0.7
        font.family: popup.fontFamily
        font.pixelSize: Style.font.caption
      }

      Rectangle {
        width: parent.width
        height: Math.max(Style.space(40), capturedLabel.implicitHeight + Style.spacing.sm)
        radius: 6
        color: popup.chipBg
        border.width: 1
        border.color: popup.bd

        Text {
          id: capturedLabel
          anchors.fill: parent
          anchors.margins: Style.spacing.sm
          text: popup.captured
            ? popup.captured
            : (host && host.recordListening ? "Press a shortcut…" : "Waiting…")
          textFormat: Text.PlainText
          color: popup.chipFg
          font.family: popup.fontFamily
          font.pixelSize: Style.font.body
          font.bold: true
          verticalAlignment: Text.AlignVCenter
          wrapMode: Text.WordWrap
        }
      }

      Rectangle {
        width: parent.width
        visible: !!(popup.occupant && popup.occupant.action)
        implicitHeight: conflictCol.implicitHeight + Style.spacing.sm
        radius: 6
        color: "transparent"
        border.width: 1
        border.color: popup.chipFg

        Column {
          id: conflictCol
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: Style.spacing.sm
          spacing: Style.space(6)

          Text {
            width: parent.width
            text: popup.occupant
              ? ("Already used by “" + popup.occupant.action + "” (" + (popup.occupant.keys || "") + ")")
              : ""
            textFormat: Text.PlainText
            color: popup.fg
            font.family: popup.fontFamily
            font.pixelSize: Style.font.body
            wrapMode: Text.WordWrap
          }

          Text {
            width: parent.width
            text: "Resolve the conflict before saving."
            textFormat: Text.PlainText
            color: popup.fg
            opacity: 0.7
            font.family: popup.fontFamily
            font.pixelSize: Style.font.caption
          }

          Row {
            spacing: Style.spacing.sm

            Text {
              text: "Swap"
              textFormat: Text.PlainText
              color: popup.chipFg
              font.family: popup.fontFamily
              font.pixelSize: Style.font.body
              font.bold: true
              MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: if (host) host.recordSwap()
              }
            }

            Text {
              text: "Move the other"
              textFormat: Text.PlainText
              color: popup.chipFg
              font.family: popup.fontFamily
              font.pixelSize: Style.font.body
              font.bold: true
              MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: if (host) host.recordMoveOther()
              }
            }
          }
        }
      }

      Text {
        width: parent.width
        visible: !!(host && host.recordStatus)
        text: host ? host.recordStatus : ""
        textFormat: Text.PlainText
        color: popup.fg
        opacity: 0.8
        font.family: popup.fontFamily
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
      }

      Row {
        width: parent.width
        spacing: Style.spacing.md

        Text {
          text: "Cancel"
          textFormat: Text.PlainText
          color: popup.fg
          opacity: 0.75
          font.family: popup.fontFamily
          font.pixelSize: Style.font.body
          MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: if (host) host.closeRecord()
          }
        }

        Text {
          visible: popup.remapped
          text: "Restore default"
          textFormat: Text.PlainText
          color: popup.fg
          font.family: popup.fontFamily
          font.pixelSize: Style.font.body
          MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: if (host) host.recordRestoreDefault()
          }
        }

        Item {
          width: Math.max(0, cardCol.width - 280)
          height: 1
        }

        Text {
          text: "Save"
          textFormat: Text.PlainText
          color: popup.canSave ? popup.chipFg : popup.fg
          opacity: popup.canSave ? 1 : 0.35
          font.family: popup.fontFamily
          font.pixelSize: Style.font.body
          font.bold: popup.canSave
          MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            enabled: popup.canSave
            cursorShape: popup.canSave ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (host) host.recordSave()
          }
        }
      }
    }
  }
}
