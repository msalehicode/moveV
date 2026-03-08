// Copyright (C) 2023 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Effects
import Config

Button {
    id: control
    flat: true

    contentItem: Image {
        id: image
        source: control.icon.source
    }

    background: MultiEffect {
        source: image
        anchors.fill: control
        visible: control.down
        opacity: 0.5
        shadowEnabled: true
        blurEnabled: true
        blur: 0.5
    }

    onHoveredChanged:
    {
        backend.setAppCursor(hovered?Config.mouseCursorOnControls:Config.mouseCursorNormal); //hand icon, blank mouse
    }
}
