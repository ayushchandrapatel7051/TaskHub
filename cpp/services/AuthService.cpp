#include "AuthService.h"
#include <QNetworkRequest>
#include <QUrl>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QDebug>

AuthService::AuthService(const QString& apiKey, QObject *parent)
    : QObject(parent), m_isAuthenticated(false), m_apiKey(apiKey) {
}

void AuthService::saveTokens(const QString& idToken, const QString& refreshToken, const QString& userId) {
    m_idToken = idToken;
    m_refreshToken = refreshToken;
    m_currentUserId = userId;
    m_isAuthenticated = true;

    QSettings settings;
    settings.setValue("auth/refreshToken", m_refreshToken);
    settings.setValue("auth/userId", m_currentUserId);
    
    emit authStateChanged(true);
}

void AuthService::clearTokens() {
    m_idToken.clear();
    m_refreshToken.clear();
    m_currentUserId.clear();
    m_isAuthenticated = false;

    QSettings settings;
    settings.remove("auth/refreshToken");
    settings.remove("auth/userId");
    
    emit authStateChanged(false);
}

void AuthService::login(const QString& email, const QString& password) {
    QString urlStr = QString("https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=%1").arg(m_apiKey);
    QUrl url(urlStr);
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QJsonObject json;
    json["email"] = email;
    json["password"] = password;
    json["returnSecureToken"] = true;

    QJsonDocument doc(json);
    QByteArray data = doc.toJson();

    QNetworkReply* reply = m_networkManager.post(request, data);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() { onLoginReply(reply); });
}

void AuthService::signup(const QString& email, const QString& password) {
    QString urlStr = QString("https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=%1").arg(m_apiKey);
    QUrl url(urlStr);
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QJsonObject json;
    json["email"] = email;
    json["password"] = password;
    json["returnSecureToken"] = true;

    QJsonDocument doc(json);
    QByteArray data = doc.toJson();

    QNetworkReply* reply = m_networkManager.post(request, data);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() { onLoginReply(reply); });
}

void AuthService::onLoginReply(QNetworkReply* reply) {
    reply->deleteLater();
    if (reply->error() == QNetworkReply::NoError) {
        QByteArray response = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(response);
        QJsonObject obj = doc.object();
        
        QString idToken = obj["idToken"].toString();
        QString refreshToken = obj["refreshToken"].toString();
        QString userId = obj["localId"].toString();
        
        saveTokens(idToken, refreshToken, userId);
    } else {
        QByteArray response = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(response);
        QJsonObject obj = doc.object();
        QString errorMsg = obj["error"].toObject()["message"].toString();
        if (errorMsg.isEmpty()) errorMsg = reply->errorString();
        
        emit authError(errorMsg);
    }
}

void AuthService::autoLogin() {
    QSettings settings;
    QString savedRefreshToken = settings.value("auth/refreshToken").toString();
    QString savedUserId = settings.value("auth/userId").toString();

    if (savedRefreshToken.isEmpty()) {
        emit authStateChanged(false);
        return;
    }

    QString urlStr = QString("https://securetoken.googleapis.com/v1/token?key=%1").arg(m_apiKey);
    QUrl url(urlStr);
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");

    QString payload = QString("grant_type=refresh_token&refresh_token=%1").arg(savedRefreshToken);
    QByteArray data = payload.toUtf8();

    QNetworkReply* reply = m_networkManager.post(request, data);
    connect(reply, &QNetworkReply::finished, this, [this, reply, savedUserId]() { 
        reply->deleteLater();
        if (reply->error() == QNetworkReply::NoError) {
            QByteArray response = reply->readAll();
            QJsonDocument doc = QJsonDocument::fromJson(response);
            QJsonObject obj = doc.object();
            
            QString newIdToken = obj["id_token"].toString();
            QString newRefreshToken = obj["refresh_token"].toString();
            QString userId = obj["user_id"].toString();
            
            if (userId.isEmpty()) userId = savedUserId;

            saveTokens(newIdToken, newRefreshToken, userId);
        } else {
            qWarning() << "Auto-login failed:" << reply->errorString();
            clearTokens();
        }
    });
}

void AuthService::logout() {
    clearTokens();
}

bool AuthService::isAuthenticated() const {
    return m_isAuthenticated;
}

QString AuthService::getCurrentUserId() const {
    return m_currentUserId;
}

QString AuthService::getIdToken() const {
    return m_idToken;
}
