// Copyright (C) 2004-2026 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import Qt.labs.qmlmodels
import Mobile
import BrickStore as BS
import BrickLink as BL

pragma ComponentBehavior: Bound

Control {
    id: root

    required property int mode // BrickLink.InventoryModel.Mode
    required property var simpleLots // [ { item: , color: , quantity: } ]

    // "Part out" and "Add item" need a document / a new document to work with, so the
    // owner of this widget has to opt-in and handle the signals below
    property bool documentActions: false

    signal partOutRequested(var item)
    signal addItemRequested(var item, var color)

    onSimpleLotsChanged: { delayedUpdateTimer.start() }

    Timer {
        id: delayedUpdateTimer
        interval: 100
        onTriggered: { listView.model = BL.BrickLink.inventoryModel(root.mode, root.simpleLots) }
    }

    // One shared context menu for all delegates, filled in on a long press
    AutoSizingMenu {
        id: contextMenu

        property BL.Item entryItem: BL.BrickLink.noItem
        property BL.Color entryColor: BL.BrickLink.noColor

        MenuItem {
            text: qsTr("Part out item...")
            visible: root.documentActions
            height: visible ? implicitHeight : 0
            enabled: contextMenu.entryItem.hasInventory
            onTriggered: root.partOutRequested(contextMenu.entryItem)
        }
        MenuItem {
            text: qsTr("Add item")
            visible: root.documentActions
            height: visible ? implicitHeight : 0
            onTriggered: root.addItemRequested(contextMenu.entryItem, contextMenu.entryColor)
        }
        MenuSeparator { visible: root.documentActions }
        MenuItem {
            text: qsTr("Show BrickLink Catalog Info...")
            enabled: BS.OnlineState.online
            onTriggered: Qt.openUrlExternally(BL.BrickLink.urlForCatalogInfo(contextMenu.entryItem))
        }
        MenuItem {
            text: qsTr("Show BrickLink Price Guide Info...")
            enabled: BS.OnlineState.online
            onTriggered: Qt.openUrlExternally(BL.BrickLink.urlForPriceGuideInfo(contextMenu.entryItem,
                                                                                 contextMenu.entryColor))
        }
        MenuItem {
            text: qsTr("Show Lots for Sale on BrickLink...")
            enabled: BS.OnlineState.online
            onTriggered: Qt.openUrlExternally(BL.BrickLink.urlForLotsForSale(contextMenu.entryItem,
                                                                              contextMenu.entryColor))
        }
        MenuItem {
            text: qsTr("Show in my Store on BrickLink...")
            enabled: BS.OnlineState.online
            onTriggered: Qt.openUrlExternally(BL.BrickLink.urlForStoreItemSearch(contextMenu.entryItem,
                                                                                  contextMenu.entryColor))
        }
    }

    ListView {
        id: listView
        anchors.fill: parent
        clip: true

        Label {
            anchors.fill: parent
            text: qsTr("No matches found")
            color: Style.hintTextColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            visible: listView.model ? (listView.model.count === 0) : true
        }

        ScrollIndicator.vertical: ScrollIndicator { }

        delegate: DelegateChooser {
            role: "isSectionHeader"
            DelegateChoice {
                roleValue: true
                ItemDelegate {
                    required property string sectionTitle
                    text: sectionTitle
                    font.bold: true
                    font.italic: true
                }
            }
            DelegateChoice {
                roleValue: false
                ItemDelegate {
                    id: delegate
                    required property string id
                    required property string name
                    required property int quantity
                    required property var itemPointer
                    required property var colorPointer

                    width: ListView.view.width
                    height: layout.height + 8

                    property BL.Item blitem: BL.BrickLink.item(itemPointer)
                    property BL.Color blcolor: (root.mode === BL.InventoryModel.Mode.ConsistsOf)
                                               ? BL.BrickLink.color(colorPointer) : BL.BrickLink.noColor
                    property int showQuantity: (root.mode === BL.InventoryModel.Mode.ConsistsOf)
                                               || (root.mode === BL.InventoryModel.Mode.AppearsIn)

                    onPressAndHold: {
                        // blcolor is only set in "Consists of" mode, otherwise it is "no color"
                        contextMenu.entryItem = delegate.blitem
                        contextMenu.entryColor = delegate.blcolor
                        contextMenu.popup(delegate, delegate.width / 2, delegate.height / 2)
                    }

                    GridLayout {
                        id: layout
                        width: parent.width - 16
                        x: 8
                        y: 4
                        columnSpacing: 0
                        columns: 3

                        PictureImage {
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                            Layout.leftMargin: 8

                            FontMetrics { id: fm; font: delegate.font }

                            implicitHeight: fm.height * 3
                            implicitWidth: height * 4 / 3

                            picture: BL.BrickLink.picture(delegate.blitem, BL.BrickLink.noColor)
                        }
                        Label {
                            id: description
                            Layout.fillWidth: true
                            Layout.leftMargin: 8
                            Layout.rightMargin: 8
                            textFormat: Text.RichText
                            text: BL.BrickLink.itemHtmlDescription(delegate.blitem, delegate.blcolor, Style.accentColor)
                            wrapMode: Text.Wrap
                        }
                        Label {
                            Layout.rightMargin: 8
                            font.bold: true
                            text: delegate.quantity
                            font.pointSize: description.font.pointSize * 1.75
                            visible: delegate.showQuantity && delegate.quantity > 0
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }
        }
    }
}
