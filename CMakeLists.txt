cmake_minimum_required(VERSION 3.16)

project(moveV VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Multimedia)
find_package(Qt6 REQUIRED COMPONENTS Core)
find_package(Qt6 REQUIRED COMPONENTS Core)
find_package(Qt6 REQUIRED COMPONENTS Core)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appmoveV
    main.cpp
)

qt_add_qml_module(appmoveV
    URI moveV
    VERSION 1.0
    QML_FILES
        Main.qml
        QML_FILES SubtitleUtils.js
        SOURCES subtitleextractor.h subtitleextractor.cpp
        QML_FILES
RESOURCES CustomComponents/qmldir
QML_FILES CustomComponents/CustomButton.qml CustomComponents/CustomButtonWithIcon.qml CustomComponents/CustomCheckBox.qml CustomComponents/CustomCollapsiblePanel.qml CustomComponents/CustomCombobox.qml CustomComponents/CustomComboboxWithIcon.qml CustomComponents/CustomPopupMenu.qml CustomComponents/CustomPopupMessage.qml CustomComponents/CustomProccessBar.qml CustomComponents/CustomSwitch.qml CustomComponents/CustomSwitchText.qml CustomComponents/CustomTextInput.qml CustomComponents/CustomTimer.qml
SOURCES subtitlefinder.h subtitlefinder.cpp
SOURCES
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appmoveV PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appmoveV
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appmoveV
    PRIVATE Qt6::Quick Qt6::Multimedia
)
target_link_libraries(appmoveV PRIVATE Qt6::Core)
target_link_libraries(appmoveV PRIVATE Qt6::Core)
target_link_libraries(appmoveV PRIVATE Qt6::Core)

include(GNUInstallDirs)
install(TARGETS appmoveV
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
