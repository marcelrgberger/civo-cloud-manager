<!-- doc-id: PUSH_NOTIFICATION_CONSENT | lang: ru | app-version: 2.3.0 | updated: 2026-11-23 | source-version: 1.0.0 | source: apps/screens/PUSH_NOTIFICATION_CONSENT.en.md | adapted: replaced by a notice for local notifications only, because the app has no push delivery; company identity and contacts from the legal repository -->
# УВЕДОМЛЕНИЕ ОБ УВЕДОМЛЕНИЯХ

## Локальные уведомления в Civo Cloud Manager

**Дата вступления в силу:** ноябрь 2026

**Поставщик:**
DigitalFreedom
Бренд компании DigitalFreedom Global LLC
30 N Gould St, Ste N
Sheridan, WY 82801
Соединённые Штаты Америки
Контакт: hello@digitalfreedom.co.za
Защита данных: data-protection@digitalfreedom.co.za
Веб-сайт: https://digitalfreedom.co.za

---

## 1. О ЧЁМ ПРИЛОЖЕНИЕ ЗАПРАШИВАЕТ РАЗРЕШЕНИЕ

При первом запуске приложения macOS спрашивает, может ли Civo Cloud Manager показывать оповещения и воспроизводить звуки. Приложение запрашивает только это разрешение. Оно использует его, чтобы показывать локальное уведомление на вашем Mac, например когда перезапустился под кластера Kubernetes, к которому вы подключены.

## 2. ЧЕГО ПРИЛОЖЕНИЕ НЕ ДЕЛАЕТ

- Оно не использует удалённые push-уведомления. Ничего не отправляется на ваш Mac с сервера.
- Оно не использует Apple Push Notification service (APNs) и Firebase Cloud Messaging (FCM) и не регистрирует и не хранит push-токен.
- Оно не отправляет маркетинговых уведомлений.
- Оно не распространяется для iOS или Android.

Уведомления создаются на вашем Mac на основе данных, которые приложение уже получило от подключённых вами сервисов. Они не отправляются нам, и мы их не получаем.

## 3. КАК ИЗМЕНИТЬ ВАШ ВЫБОР

Вы можете разрешить или прекратить уведомления в любое время в Системных настройках, в разделе «Уведомления», выбрав Civo Cloud Manager. Если вы не разрешите уведомления, приложение работает как прежде и не показывает оповещений.

## 4. ДОПОЛНИТЕЛЬНАЯ ИНФОРМАЦИЯ И КОНТАКТЫ

Как приложение обращается с данными, описано в [Политике конфиденциальности](PrivacyPolicy.md). По вопросам об этом уведомлении пишите на hello@digitalfreedom.co.za. Запросы по защите данных направляйте на data-protection@digitalfreedom.co.za.
