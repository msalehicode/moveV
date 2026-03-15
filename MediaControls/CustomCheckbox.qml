// Copyright (C) 2023 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Effects

CheckBox
{
    property string theText: ""
    property bool initialCheckedState:false;
    text:theText
    // checked: true
    checked: initialCheckedState

    signal statusChangeAction(bool newStatus);

    onCheckedChanged:
    {
        if (initialCheckedState !== checked)
        {
            statusChangeAction(checked)

            // After setting, update initialCheckedState to prevent re-triggering on next load
            initialCheckedState = checked;
        }
    }

    Component.onCompleted:
    {
        if (checked !== initialCheckedState)
            checked = initialCheckedState;
    }

    onHoveredChanged:
    {
        if(hovered)
            backend.changeCursor("hand")
        else
            backend.changeCursor()
    }


}
