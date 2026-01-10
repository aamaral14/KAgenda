#include "GmailBackend.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QUrlQuery>
#include <QDebug>
#include <QVariantMap>

GmailBackend::GmailBackend(QObject *parent)
    : QObject(parent)
    , m_isAuthenticated(false)
    , m_oauth2(nullptr)
    , m_networkManager(new QNetworkAccessManager(this))
{
    // Initialize OAuth2 flow
    m_oauth2 = new QOAuth2AuthorizationCodeFlow(this);
    m_oauth2->setAuthorizationUrl(QUrl("https://accounts.google.com/o/oauth2/auth"));
    m_oauth2->setAccessTokenUrl(QUrl("https://oauth2.googleapis.com/token"));
    m_oauth2->setClientIdentifier("your-client-id"); // Should be configured
    m_oauth2->setClientIdentifierSharedKey("your-client-secret"); // Should be configured
    m_oauth2->setScope("https://www.googleapis.com/auth/calendar.readonly https://www.googleapis.com/auth/tasks");

    connect(m_oauth2, &QOAuth2AuthorizationCodeFlow::granted, this, &GmailBackend::onGranted);
    connect(m_oauth2, &QOAuth2AuthorizationCodeFlow::error, this, &GmailBackend::onError);
}

GmailBackend::~GmailBackend()
{
}

QStringList GmailBackend::calendarList() const
{
    return m_calendarList;
}

QString GmailBackend::accessToken() const
{
    return m_accessToken;
}

bool GmailBackend::isAuthenticated() const
{
    return m_isAuthenticated;
}

QString GmailBackend::statusMessage() const
{
    return m_statusMessage;
}

QVariantList GmailBackend::taskLists() const
{
    return m_taskLists;
}

QVariantList GmailBackend::tasks() const
{
    return m_tasks;
}

void GmailBackend::signIn()
{
    setStatusMessage("Starting authentication...");
    m_oauth2->grant();
}

void GmailBackend::signOut()
{
    m_oauth2->setToken("");
    m_accessToken = "";
    m_isAuthenticated = false;
    m_calendarList.clear();
    m_taskLists.clear();
    m_tasks.clear();
    emit accessTokenChanged();
    emit authenticationChanged();
    emit calendarListChanged();
    emit taskListsChanged();
    emit tasksChanged();
    setStatusMessage("Signed out");
}

void GmailBackend::fetchTasks(const QString &taskListId)
{
    if (!m_isAuthenticated) return;

    if (taskListId.isEmpty()) {
        // Fetch all task lists first
        fetchTaskLists();
    } else {
        // Fetch tasks for specific task list
        QUrl url(QString("https://www.googleapis.com/tasks/v1/lists/%1/tasks").arg(taskListId));
        QNetworkRequest request(url);
        request.setRawHeader("Authorization", QString("Bearer %1").arg(m_accessToken).toUtf8());

        QNetworkReply *reply = m_networkManager->get(request);
        connect(reply, &QNetworkReply::finished, this, &GmailBackend::onTasksReceived);

        setStatusMessage("Loading tasks...");
    }
}

void GmailBackend::createTask(const QString &taskListId, const QString &title, const QString &notes)
{
    if (!m_isAuthenticated || taskListId.isEmpty() || title.isEmpty()) return;

    QUrl url(QString("https://www.googleapis.com/tasks/v1/lists/%1/tasks").arg(taskListId));
    QNetworkRequest request(url);
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_accessToken).toUtf8());
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QJsonObject taskObject;
    taskObject["title"] = title;
    if (!notes.isEmpty()) {
        taskObject["notes"] = notes;
    }

    QJsonDocument doc(taskObject);
    QByteArray data = doc.toJson();

    QNetworkReply *reply = m_networkManager->post(request, data);
    connect(reply, &QNetworkReply::finished, this, [this, taskListId]() {
        QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
        if (reply->error() == QNetworkReply::NoError) {
            // Refresh tasks after creation
            fetchTasks(taskListId);
            setStatusMessage("Task created successfully");
        } else {
            setStatusMessage("Failed to create task: " + reply->errorString());
        }
        reply->deleteLater();
    });

    setStatusMessage("Creating task...");
}

void GmailBackend::updateTask(const QString &taskListId, const QString &taskId, const QString &title, const QString &notes, bool completed)
{
    if (!m_isAuthenticated || taskListId.isEmpty() || taskId.isEmpty()) return;

    QUrl url(QString("https://www.googleapis.com/tasks/v1/lists/%1/tasks/%2").arg(taskListId, taskId));
    QNetworkRequest request(url);
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_accessToken).toUtf8());
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QJsonObject taskObject;
    taskObject["title"] = title;
    if (!notes.isEmpty()) {
        taskObject["notes"] = notes;
    }
    if (completed) {
        taskObject["status"] = "completed";
    } else {
        taskObject["status"] = "needsAction";
    }

    QJsonDocument doc(taskObject);
    QByteArray data = doc.toJson();

    QNetworkReply *reply = m_networkManager->put(request, data);
    connect(reply, &QNetworkReply::finished, this, [this, taskListId]() {
        QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
        if (reply->error() == QNetworkReply::NoError) {
            // Refresh tasks after update
            fetchTasks(taskListId);
            setStatusMessage("Task updated successfully");
        } else {
            setStatusMessage("Failed to update task: " + reply->errorString());
        }
        reply->deleteLater();
    });

    setStatusMessage("Updating task...");
}

void GmailBackend::deleteTask(const QString &taskListId, const QString &taskId)
{
    if (!m_isAuthenticated || taskListId.isEmpty() || taskId.isEmpty()) return;

    QUrl url(QString("https://www.googleapis.com/tasks/v1/lists/%1/tasks/%2").arg(taskListId, taskId));
    QNetworkRequest request(url);
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_accessToken).toUtf8());

    QNetworkReply *reply = m_networkManager->deleteResource(request);
    connect(reply, &QNetworkReply::finished, this, [this, taskListId]() {
        QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
        if (reply->error() == QNetworkReply::NoError) {
            // Refresh tasks after deletion
            fetchTasks(taskListId);
            setStatusMessage("Task deleted successfully");
        } else {
            setStatusMessage("Failed to delete task: " + reply->errorString());
        }
        reply->deleteLater();
    });

    setStatusMessage("Deleting task...");
}

void GmailBackend::onGranted()
{
    m_accessToken = m_oauth2->token();
    m_isAuthenticated = true;
    emit accessTokenChanged();
    emit authenticationChanged();
    emit authenticationSucceeded();
    setStatusMessage("Authentication successful");

    // Fetch calendar list
    fetchCalendarList();
}

void GmailBackend::onError(const QString &error, const QString &errorDescription, const QUrl &uri)
{
    Q_UNUSED(uri)
    m_isAuthenticated = false;
    emit authenticationChanged();
    emit authenticationFailed(error + ": " + errorDescription);
    setStatusMessage("Authentication failed: " + error);
}

void GmailBackend::onCalendarListReceived()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;

    if (reply->error() == QNetworkReply::NoError) {
        QByteArray data = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(data);
        QJsonObject obj = doc.object();
        QJsonArray items = obj["items"].toArray();

        m_calendarList.clear();
        for (const QJsonValue &value : items) {
            QJsonObject calendar = value.toObject();
            QString summary = calendar["summary"].toString();
            if (!summary.isEmpty()) {
                m_calendarList.append(summary);
            }
        }

        emit calendarListChanged();
        emit calendarsReady();
        setStatusMessage("Calendar list loaded");

        // Also fetch task lists
        fetchTaskLists();
    } else {
        setStatusMessage("Failed to load calendar list: " + reply->errorString());
    }

    reply->deleteLater();
}

void GmailBackend::onTaskListsReceived()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;

    if (reply->error() == QNetworkReply::NoError) {
        QByteArray data = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(data);
        QJsonObject obj = doc.object();
        QJsonArray items = obj["items"].toArray();

        m_taskLists.clear();
        for (const QJsonValue &value : items) {
            QJsonObject taskList = value.toObject();
            QVariantMap taskListMap;
            taskListMap["id"] = taskList["id"].toString();
            taskListMap["title"] = taskList["title"].toString();
            m_taskLists.append(taskListMap);
        }

        emit taskListsChanged();
        setStatusMessage("Task lists loaded");
    } else {
        setStatusMessage("Failed to load task lists: " + reply->errorString());
    }

    reply->deleteLater();
}

void GmailBackend::onTasksReceived()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;

    if (reply->error() == QNetworkReply::NoError) {
        QByteArray data = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(data);
        QJsonObject obj = doc.object();
        QJsonArray items = obj["items"].toArray();

        m_tasks.clear();
        for (const QJsonValue &value : items) {
            QJsonObject task = value.toObject();
            QVariantMap taskMap;
            taskMap["id"] = task["id"].toString();
            taskMap["title"] = task["title"].toString();
            taskMap["notes"] = task["notes"].toString();
            taskMap["status"] = task["status"].toString();
            taskMap["completed"] = (task["status"].toString() == "completed");
            // Parse due date if available
            if (task.contains("due")) {
                taskMap["due"] = task["due"].toString();
            }
            m_tasks.append(taskMap);
        }

        emit tasksChanged();
        emit tasksReady();
        setStatusMessage("Tasks loaded");
    } else {
        setStatusMessage("Failed to load tasks: " + reply->errorString());
    }

    reply->deleteLater();
}

void GmailBackend::fetchCalendarList()
{
    if (!m_isAuthenticated) return;

    QUrl url("https://www.googleapis.com/calendar/v3/users/me/calendarList");
    QNetworkRequest request(url);
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_accessToken).toUtf8());

    QNetworkReply *reply = m_networkManager->get(request);
    connect(reply, &QNetworkReply::finished, this, &GmailBackend::onCalendarListReceived);

    setStatusMessage("Loading calendar list...");
}

void GmailBackend::fetchTaskLists()
{
    if (!m_isAuthenticated) return;

    QUrl url("https://www.googleapis.com/tasks/v1/users/@me/lists");
    QNetworkRequest request(url);
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_accessToken).toUtf8());

    QNetworkReply *reply = m_networkManager->get(request);
    connect(reply, &QNetworkReply::finished, this, &GmailBackend::onTaskListsReceived);

    setStatusMessage("Loading task lists...");
}

void GmailBackend::setStatusMessage(const QString &message)
{
    if (m_statusMessage != message) {
        m_statusMessage = message;
        emit statusMessageChanged();
    }
}