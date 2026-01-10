#ifndef GMAILBACKEND_H
#define GMAILBACKEND_H

#include <QObject>
#include <QString>
#include <QStringList>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QOAuth2AuthorizationCodeFlow>
#include <QUrl>
#include <QVariantList>

class GmailBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList calendarList READ calendarList NOTIFY calendarListChanged)
    Q_PROPERTY(QString accessToken READ accessToken NOTIFY accessTokenChanged)
    Q_PROPERTY(bool isAuthenticated READ isAuthenticated NOTIFY authenticationChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusMessageChanged)
    Q_PROPERTY(QVariantList taskLists READ taskLists NOTIFY taskListsChanged)
    Q_PROPERTY(QVariantList tasks READ tasks NOTIFY tasksChanged)

public:
    explicit GmailBackend(QObject *parent = nullptr);
    ~GmailBackend();

    QStringList calendarList() const;
    QString accessToken() const;
    bool isAuthenticated() const;
    QString statusMessage() const;
    QVariantList taskLists() const;
    QVariantList tasks() const;

    Q_INVOKABLE void signIn();
    Q_INVOKABLE void signOut();
    Q_INVOKABLE void fetchTasks(const QString &taskListId = QString());
    Q_INVOKABLE void createTask(const QString &taskListId, const QString &title, const QString &notes = QString());
    Q_INVOKABLE void updateTask(const QString &taskListId, const QString &taskId, const QString &title, const QString &notes = QString(), bool completed = false);
    Q_INVOKABLE void deleteTask(const QString &taskListId, const QString &taskId);

public slots:
    void onGranted();
    void onError(const QString &error, const QString &errorDescription, const QUrl &uri);
    void onCalendarListReceived();
    void onTaskListsReceived();
    void onTasksReceived();

signals:
    void calendarListChanged();
    void accessTokenChanged();
    void authenticationChanged();
    void statusMessageChanged();
    void calendarsReady();
    void authenticationSucceeded();
    void authenticationFailed(const QString &error);
    void taskListsChanged();
    void tasksChanged();
    void tasksReady();

private:
    QStringList m_calendarList;
    QString m_accessToken;
    bool m_isAuthenticated;
    QString m_statusMessage;
    QVariantList m_taskLists;
    QVariantList m_tasks;

    QOAuth2AuthorizationCodeFlow *m_oauth2;
    QNetworkAccessManager *m_networkManager;

    void setStatusMessage(const QString &message);
    void fetchCalendarList();
    void fetchTaskLists();
};

#endif // GMAILBACKEND_H