#include <QtQml>
#include <QQmlEngine>
#include "GmailBackend.h"

class GmailCalendarPlugin : public QQmlEngineExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QQmlEngineExtensionInterface_iid)

public:
    void initializeEngine(QQmlEngine *engine, const char *uri) override
    {
        Q_UNUSED(engine);
        Q_UNUSED(uri);
    }

    void registerTypes(const char *uri) override
    {
        qmlRegisterType<GmailBackend>(uri, 1, 0, "GmailBackend");
    }
};

#include "plugin.moc"