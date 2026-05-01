#ifndef AUTH_SERVICE_H
#define AUTH_SERVICE_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QSettings>

class AuthService : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool isAuthenticated READ isAuthenticated NOTIFY authStateChanged)
public:
    explicit AuthService(const QString& apiKey, QObject *parent = nullptr);

    Q_INVOKABLE void login(const QString& email, const QString& password);
    Q_INVOKABLE void signup(const QString& email, const QString& password);
    Q_INVOKABLE void logout();
    Q_INVOKABLE void autoLogin();

    bool isAuthenticated() const;
    QString getCurrentUserId() const;
    QString getIdToken() const;

signals:
    void authStateChanged(bool isAuthenticated);
    void authError(const QString& errorMessage);

private slots:
    void onLoginReply(QNetworkReply* reply);

private:
    void saveTokens(const QString& idToken, const QString& refreshToken, const QString& userId);
    void clearTokens();

    bool m_isAuthenticated;
    QString m_currentUserId;
    QString m_idToken;
    QString m_refreshToken;
    QNetworkAccessManager m_networkManager;
    QString m_apiKey;
};

#endif // AUTH_SERVICE_H
