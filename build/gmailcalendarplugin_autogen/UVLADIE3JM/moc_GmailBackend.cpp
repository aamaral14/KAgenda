/****************************************************************************
** Meta object code from reading C++ file 'GmailBackend.h'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.9.2)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../src/GmailBackend.h"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'GmailBackend.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 69
#error "This file was generated using the moc from 6.9.2. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

#ifndef Q_CONSTINIT
#define Q_CONSTINIT
#endif

QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
QT_WARNING_DISABLE_GCC("-Wuseless-cast")
namespace {
struct qt_meta_tag_ZN12GmailBackendE_t {};
} // unnamed namespace

template <> constexpr inline auto GmailBackend::qt_create_metaobjectdata<qt_meta_tag_ZN12GmailBackendE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "GmailBackend",
        "QML.Element",
        "auto",
        "calendarListChanged",
        "",
        "accessTokenChanged",
        "authenticationChanged",
        "statusMessageChanged",
        "calendarsReady",
        "authenticationSucceeded",
        "authenticationFailed",
        "error",
        "onGranted",
        "onError",
        "errorDescription",
        "uri",
        "onCalendarListReceived",
        "signIn",
        "signOut",
        "calendarList",
        "accessToken",
        "isAuthenticated",
        "statusMessage"
    };

    QtMocHelpers::UintData qt_methods {
        // Signal 'calendarListChanged'
        QtMocHelpers::SignalData<void()>(3, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'accessTokenChanged'
        QtMocHelpers::SignalData<void()>(5, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'authenticationChanged'
        QtMocHelpers::SignalData<void()>(6, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'statusMessageChanged'
        QtMocHelpers::SignalData<void()>(7, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'calendarsReady'
        QtMocHelpers::SignalData<void()>(8, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'authenticationSucceeded'
        QtMocHelpers::SignalData<void()>(9, 4, QMC::AccessPublic, QMetaType::Void),
        // Signal 'authenticationFailed'
        QtMocHelpers::SignalData<void(const QString &)>(10, 4, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 11 },
        }}),
        // Slot 'onGranted'
        QtMocHelpers::SlotData<void()>(12, 4, QMC::AccessPrivate, QMetaType::Void),
        // Slot 'onError'
        QtMocHelpers::SlotData<void(const QString &, const QString &, const QUrl &)>(13, 4, QMC::AccessPrivate, QMetaType::Void, {{
            { QMetaType::QString, 11 }, { QMetaType::QString, 14 }, { QMetaType::QUrl, 15 },
        }}),
        // Slot 'onCalendarListReceived'
        QtMocHelpers::SlotData<void()>(16, 4, QMC::AccessPrivate, QMetaType::Void),
        // Method 'signIn'
        QtMocHelpers::MethodData<void()>(17, 4, QMC::AccessPublic, QMetaType::Void),
        // Method 'signOut'
        QtMocHelpers::MethodData<void()>(18, 4, QMC::AccessPublic, QMetaType::Void),
    };
    QtMocHelpers::UintData qt_properties {
        // property 'calendarList'
        QtMocHelpers::PropertyData<QStringList>(19, QMetaType::QStringList, QMC::DefaultPropertyFlags, 0),
        // property 'accessToken'
        QtMocHelpers::PropertyData<QString>(20, QMetaType::QString, QMC::DefaultPropertyFlags, 1),
        // property 'isAuthenticated'
        QtMocHelpers::PropertyData<bool>(21, QMetaType::Bool, QMC::DefaultPropertyFlags, 2),
        // property 'statusMessage'
        QtMocHelpers::PropertyData<QString>(22, QMetaType::QString, QMC::DefaultPropertyFlags, 3),
    };
    QtMocHelpers::UintData qt_enums {
    };
    QtMocHelpers::UintData qt_constructors {};
    QtMocHelpers::ClassInfos qt_classinfo({
            {    1,    2 },
    });
    return QtMocHelpers::metaObjectData<GmailBackend, void>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums, qt_constructors, qt_classinfo);
}
Q_CONSTINIT const QMetaObject GmailBackend::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN12GmailBackendE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN12GmailBackendE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN12GmailBackendE_t>.metaTypes,
    nullptr
} };

void GmailBackend::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<GmailBackend *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->calendarListChanged(); break;
        case 1: _t->accessTokenChanged(); break;
        case 2: _t->authenticationChanged(); break;
        case 3: _t->statusMessageChanged(); break;
        case 4: _t->calendarsReady(); break;
        case 5: _t->authenticationSucceeded(); break;
        case 6: _t->authenticationFailed((*reinterpret_cast< std::add_pointer_t<QString>>(_a[1]))); break;
        case 7: _t->onGranted(); break;
        case 8: _t->onError((*reinterpret_cast< std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast< std::add_pointer_t<QString>>(_a[2])),(*reinterpret_cast< std::add_pointer_t<QUrl>>(_a[3]))); break;
        case 9: _t->onCalendarListReceived(); break;
        case 10: _t->signIn(); break;
        case 11: _t->signOut(); break;
        default: ;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (GmailBackend::*)()>(_a, &GmailBackend::calendarListChanged, 0))
            return;
        if (QtMocHelpers::indexOfMethod<void (GmailBackend::*)()>(_a, &GmailBackend::accessTokenChanged, 1))
            return;
        if (QtMocHelpers::indexOfMethod<void (GmailBackend::*)()>(_a, &GmailBackend::authenticationChanged, 2))
            return;
        if (QtMocHelpers::indexOfMethod<void (GmailBackend::*)()>(_a, &GmailBackend::statusMessageChanged, 3))
            return;
        if (QtMocHelpers::indexOfMethod<void (GmailBackend::*)()>(_a, &GmailBackend::calendarsReady, 4))
            return;
        if (QtMocHelpers::indexOfMethod<void (GmailBackend::*)()>(_a, &GmailBackend::authenticationSucceeded, 5))
            return;
        if (QtMocHelpers::indexOfMethod<void (GmailBackend::*)(const QString & )>(_a, &GmailBackend::authenticationFailed, 6))
            return;
    }
    if (_c == QMetaObject::ReadProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast<QStringList*>(_v) = _t->calendarList(); break;
        case 1: *reinterpret_cast<QString*>(_v) = _t->accessToken(); break;
        case 2: *reinterpret_cast<bool*>(_v) = _t->isAuthenticated(); break;
        case 3: *reinterpret_cast<QString*>(_v) = _t->statusMessage(); break;
        default: break;
        }
    }
}

const QMetaObject *GmailBackend::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *GmailBackend::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN12GmailBackendE_t>.strings))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int GmailBackend::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 12)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 12;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 12)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 12;
    }
    if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 4;
    }
    return _id;
}

// SIGNAL 0
void GmailBackend::calendarListChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}

// SIGNAL 1
void GmailBackend::accessTokenChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 1, nullptr);
}

// SIGNAL 2
void GmailBackend::authenticationChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 2, nullptr);
}

// SIGNAL 3
void GmailBackend::statusMessageChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 3, nullptr);
}

// SIGNAL 4
void GmailBackend::calendarsReady()
{
    QMetaObject::activate(this, &staticMetaObject, 4, nullptr);
}

// SIGNAL 5
void GmailBackend::authenticationSucceeded()
{
    QMetaObject::activate(this, &staticMetaObject, 5, nullptr);
}

// SIGNAL 6
void GmailBackend::authenticationFailed(const QString & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 6, nullptr, _t1);
}
QT_WARNING_POP
