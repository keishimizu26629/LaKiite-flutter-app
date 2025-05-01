const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

/**
 * プッシュ通知を送信するCloud Function
 *
 * リクエストボディの形式:
 * {
 *   "token": "FCMトークン",
 *   "notification": {
 *     "title": "通知タイトル",
 *     "body": "通知本文"
 *   },
 *   "data": {
 *     "type": "通知タイプ",
 *     ... その他の必要なデータ
 *   }
 * }
 */
exports.sendNotification = functions.region('us-central1').https.onRequest(async (req, res) => {
  try {
    // リクエストは必ずPOSTでなければならない
    if (req.method !== 'POST') {
      res.status(405).send('Method Not Allowed');
      return;
    }

    const payload = req.body;

    // パラメータのバリデーション
    if (!payload.token || !payload.notification || !payload.data) {
      console.error('必須パラメータが不足しています:', payload);
      res.status(400).send('必須パラメータ（token, notification, data）が不足しています');
      return;
    }

    // 通知タイプに基づいた処理
    const type = payload.data.type;

    // 通知データが正しいか追加のバリデーション
    if (type === 'friend_request' && (!payload.data.fromUserId || !payload.data.toUserId)) {
      console.error('友達申請通知に必要なパラメータが不足しています:', payload.data);
      res.status(400).send('友達申請通知に必要なパラメータが不足しています');
      return;
    }

    if (type === 'group_invitation' && (!payload.data.groupId || !payload.data.fromUserId)) {
      console.error('グループ招待通知に必要なパラメータが不足しています:', payload.data);
      res.status(400).send('グループ招待通知に必要なパラメータが不足しています');
      return;
    }

    if (type === 'reaction' && (!payload.data.fromUserId || !payload.data.scheduleId || !payload.data.interactionId)) {
      console.error('リアクション通知に必要なパラメータが不足しています:', payload.data);
      res.status(400).send('リアクション通知に必要なパラメータが不足しています');
      return;
    }

    if (type === 'comment' && (!payload.data.fromUserId || !payload.data.scheduleId || !payload.data.interactionId)) {
      console.error('コメント通知に必要なパラメータが不足しています:', payload.data);
      res.status(400).send('コメント通知に必要なパラメータが不足しています');
      return;
    }

    // FCM通知の送信
    const message = {
      token: payload.token,
      notification: {
        title: payload.notification.title,
        body: payload.notification.body,
      },
      data: payload.data,
      android: {
        notification: {
          icon: 'notification_icon',
          color: '#ffa600',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
      apns: {
        payload: {
          aps: {
            badge: 1,
            sound: 'default',
          },
        },
      },
    };

    console.log('送信する通知:', message);

    const response = await admin.messaging().send(message);
    console.log('通知送信成功:', response);

    res.status(200).send({ success: true, messageId: response });
  } catch (error) {
    console.error('通知送信エラー:', error);
    res.status(500).send({
      error: error.message,
      code: error.code || 'unknown_error'
    });
  }
});

/**
 * 新しい友達申請が作成された時に自動的にプッシュ通知を送信する
 */
exports.onNewFriendRequest = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snapshot, context) => {
    try {
      const notification = snapshot.data();

      // 友達申請通知かどうかを確認
      if (notification.type !== 'friend') {
        console.log('友達申請以外の通知のため、処理をスキップします');
        return null;
      }

      // 受信者のFCMトークンを取得
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(notification.receiveUserId)
        .get();

      if (!userDoc.exists) {
        console.error('受信者が存在しません:', notification.receiveUserId);
        return null;
      }

      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;

      if (!fcmToken) {
        console.log('受信者のFCMトークンがありません:', notification.receiveUserId);
        return null;
      }

      // 通知メッセージを作成
      const message = {
        token: fcmToken,
        notification: {
          title: '友達申請が届きました',
          body: `${notification.sendUserDisplayName || '新しいユーザー'}さんから友達申請が届いています`,
        },
        data: {
          type: 'friend_request',
          notificationId: context.params.notificationId,
          fromUserId: notification.sendUserId,
          toUserId: notification.receiveUserId,
          timestamp: Date.now().toString(),
        },
        android: {
          notification: {
            icon: 'notification_icon',
            color: '#ffa600',
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          },
        },
        apns: {
          payload: {
            aps: {
              badge: 1,
              sound: 'default',
            },
          },
        },
      };

      // 通知送信
      const response = await admin.messaging().send(message);
      console.log('友達申請通知送信成功:', response);

      return null;
    } catch (error) {
      console.error('友達申請通知送信エラー:', error);
      return null;
    }
  });

/**
 * 新しいグループ招待が作成された時に自動的にプッシュ通知を送信する
 */
exports.onNewGroupInvitation = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snapshot, context) => {
    try {
      const notification = snapshot.data();

      // グループ招待通知かどうかを確認
      if (notification.type !== 'groupInvitation') {
        console.log('グループ招待以外の通知のため、処理をスキップします');
        return null;
      }

      // 受信者のFCMトークンを取得
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(notification.receiveUserId)
        .get();

      if (!userDoc.exists) {
        console.error('受信者が存在しません:', notification.receiveUserId);
        return null;
      }

      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;

      if (!fcmToken) {
        console.log('受信者のFCMトークンがありません:', notification.receiveUserId);
        return null;
      }

      // グループ情報を取得
      const groupDoc = await admin.firestore()
        .collection('groups')
        .doc(notification.groupId)
        .get();

      if (!groupDoc.exists) {
        console.error('グループが存在しません:', notification.groupId);
        return null;
      }

      const groupData = groupDoc.data();

      // 通知メッセージを作成
      const message = {
        token: fcmToken,
        notification: {
          title: 'グループ招待が届きました',
          body: `${notification.sendUserDisplayName || '新しいユーザー'}さんから「${groupData.name}」グループへの招待が届いています`,
        },
        data: {
          type: 'group_invitation',
          notificationId: context.params.notificationId,
          fromUserId: notification.sendUserId,
          toUserId: notification.receiveUserId,
          groupId: notification.groupId,
          groupName: groupData.name,
          timestamp: Date.now().toString(),
        },
        android: {
          notification: {
            icon: 'notification_icon',
            color: '#ffa600',
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          },
        },
        apns: {
          payload: {
            aps: {
              badge: 1,
              sound: 'default',
            },
          },
        },
      };

      // 通知送信
      const response = await admin.messaging().send(message);
      console.log('グループ招待通知送信成功:', response);

      return null;
    } catch (error) {
      console.error('グループ招待通知送信エラー:', error);
      return null;
    }
  });

/**
 * 新しいリアクション通知が作成された時に自動的にプッシュ通知を送信する
 */
exports.onNewReactionNotification = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snapshot, context) => {
    try {
      const notification = snapshot.data();

      // リアクション通知かどうかを確認
      if (notification.type !== 'reaction') {
        console.log('リアクション以外の通知のため、処理をスキップします');
        return null;
      }

      // 受信者のFCMトークンを取得
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(notification.receiveUserId)
        .get();

      if (!userDoc.exists) {
        console.error('受信者が存在しません:', notification.receiveUserId);
        return null;
      }

      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;

      if (!fcmToken) {
        console.log('受信者のFCMトークンがありません:', notification.receiveUserId);
        return null;
      }

      // 通知メッセージを作成
      const message = {
        token: fcmToken,
        notification: {
          title: '新しいリアクション',
          body: `${notification.sendUserDisplayName || '新しいユーザー'}さんがあなたの投稿にリアクションしました`,
        },
        data: {
          type: 'reaction',
          notificationId: context.params.notificationId,
          fromUserId: notification.sendUserId,
          toUserId: notification.receiveUserId,
          relatedItemId: notification.relatedItemId,
          interactionId: notification.interactionId,
          timestamp: Date.now().toString(),
        },
        android: {
          notification: {
            icon: 'notification_icon',
            color: '#ffa600',
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          },
        },
        apns: {
          payload: {
            aps: {
              badge: 1,
              sound: 'default',
            },
          },
        },
      };

      // 通知送信
      const response = await admin.messaging().send(message);
      console.log('リアクション通知送信成功:', response);

      return null;
    } catch (error) {
      console.error('リアクション通知送信エラー:', error);
      return null;
    }
  });

/**
 * 新しいコメント通知が作成された時に自動的にプッシュ通知を送信する
 */
exports.onNewCommentNotification = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snapshot, context) => {
    try {
      const notification = snapshot.data();

      // コメント通知かどうかを確認
      if (notification.type !== 'comment') {
        console.log('コメント以外の通知のため、処理をスキップします');
        return null;
      }

      // 受信者のFCMトークンを取得
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(notification.receiveUserId)
        .get();

      if (!userDoc.exists) {
        console.error('受信者が存在しません:', notification.receiveUserId);
        return null;
      }

      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;

      if (!fcmToken) {
        console.log('受信者のFCMトークンがありません:', notification.receiveUserId);
        return null;
      }

      // コメントのコンテンツを取得
      let commentContent = '';
      if (notification.interactionId) {
        try {
          const commentDoc = await admin.firestore()
            .collection('schedules')
            .doc(notification.relatedItemId)
            .collection('comments')
            .doc(notification.interactionId)
            .get();

          if (commentDoc.exists) {
            const commentData = commentDoc.data();
            commentContent = commentData.content || '';

            // コメントが長すぎる場合はトリミング
            if (commentContent.length > 50) {
              commentContent = `${commentContent.substring(0, 47)}...`;
            }
          }
        } catch (e) {
          console.error('コメントデータ取得エラー:', e);
        }
      }

      // 通知メッセージを作成
      const message = {
        token: fcmToken,
        notification: {
          title: '新しいコメント',
          body: `${notification.sendUserDisplayName || '新しいユーザー'}さんがあなたの投稿にコメントしました${commentContent ? ': ' + commentContent : ''}`,
        },
        data: {
          type: 'comment',
          notificationId: context.params.notificationId,
          fromUserId: notification.sendUserId,
          toUserId: notification.receiveUserId,
          relatedItemId: notification.relatedItemId,
          interactionId: notification.interactionId,
          commentContent: commentContent,
          timestamp: Date.now().toString(),
        },
        android: {
          notification: {
            icon: 'notification_icon',
            color: '#ffa600',
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          },
        },
        apns: {
          payload: {
            aps: {
              badge: 1,
              sound: 'default',
            },
          },
        },
      };

      // 通知送信
      const response = await admin.messaging().send(message);
      console.log('コメント通知送信成功:', response);

      return null;
    } catch (error) {
      console.error('コメント通知送信エラー:', error);
      return null;
    }
  });
