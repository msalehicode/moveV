// Copyright (C) 2023 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Effects
import Config
CheckBox
{
    property string theText: ""
    text:theText
    // checked: true
    onHoveredChanged:
    {
        backend.setAppCursor(hovered?Config.mouseCursorOnControls:Config.mouseCursorNormal); //hand icon, blank mouse
    }
}
