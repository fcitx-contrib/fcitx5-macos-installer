file(GLOB ALERT_TOAST_FILES CONFIGURE_DEPENDS AlertToast/src/*.swift)
add_library(AlertToast STATIC ${ALERT_TOAST_FILES})
set_target_properties(AlertToast PROPERTIES Swift_MODULE_NAME AlertToast)
