// Copyright (C) 2023 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

import QtQuick
import QtQuick.Controls.Fusion
// import Config

Slider {
    id: slider

    property alias backgroundColor: backgroundRec.color
    property alias backgroundOpacity: backgroundRec.opacity

    background: Rectangle {
        id: backgroundRec
        x: slider.leftPadding
        y: slider.topPadding + slider.availableHeight / 2 - height / 2
        implicitWidth: 120
        implicitHeight: 8
        width: slider.availableWidth
        height: implicitHeight
        radius: 10
        color: "#41CD52"//Config.highlightColor
        opacity: 0.2
        border.color: "#41CD52"//Config.highlightColor
        border.width: 1
    }

    handle: Rectangle {
        x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
        y: slider.topPadding + slider.availableHeight / 2 - height / 2
        implicitWidth: 20
        implicitHeight: 25
        radius: 15

        color: "green"
    }
    onHoveredChanged:
    {
        // if(hovered)
            // backend.changeCursor("hand")
        // else
            // backend.changeCursor()
    }

    Rectangle {
        width: slider.visualPosition * slider.availableWidth
        x: slider.leftPadding
        y: slider.topPadding + slider.availableHeight / 2 - height / 2
        height: 8
        color:  "darkgreen"//"#41CD52"// Config.highlightColor
        radius: 10
    }
}
