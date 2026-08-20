# Firebase backend development

TRANSFER NOWのバックエンドは、`SPEC.md` §23〜§28、§36に従いFirebaseで構成する。

## 実装済み

- Firebase未設定時は`DummyTransferCaseRepository`の12案件で動作
- Firebase設定時は匿名認証し、Firestoreをリアルタイム購読
- MY画面から匿名ユーザーをGoogleアカウントへリンクし、別端末でも復元
- 既存Googleアカウントへ戻る場合は、端末とクラウドのお気に入りを和集合で統合
- お気に入りと通知設定を端末へ即時保存し、`users/{uid}/preferences/*`へ同期
- 初回は既存の端末設定をクラウドへ移行し、未送信変更は再起動後も再試行
- FCMトークンを`users/{uid}/devices/{tokenId}`へ登録
- BREAKING / AGREEMENT / OFFICIALのFCMトピック購読を通知設定と同期
- Firestore Security Rulesと開発用シードスクリプト
- 任意でStorage画像をアップロードしてFirestoreのURLへ反映する同期スクリプト
- 画像が未登録・取得失敗の場合は国旗／クラブ略称へ自動フォールバック
- API-Footballの移籍履歴をdry-run確認し、非公開ステージングへ保存する取込CLI

外部Football API、AI生成、FCMを送信するCloud Functionsは未実装。

## Football API取込（安全なステージング）

最初の外部データ検証にはAPI-Footballを利用する。無料プランはカード登録不要で、
1日100リクエストまで利用できる。無料プランで利用可能なシーズンは限定されるため、
既定値は過去シーズン`2024`、対象クラブ数は2に絞っている。

APIキーはFlutterやGitへ保存せず、そのターミナルだけの環境変数へ設定する。

```powershell
$env:API_FOOTBALL_KEY='API-Footballダッシュボードのキー'
Set-Location firebase
npm run import-api-football -- --season=2024 --max-teams=2
Set-Location ..
```

既定動作はdry-runであり、API結果を最大10件プレビューするだけでFirestoreは変更しない。
プレミアリーグのリーグIDは`39`。20クラブを取得するとチーム一覧1回＋移籍履歴20回の
合計21リクエストを消費する。
通常のレンタル移籍は取り込むが、ニュース性の低い`Return from loan`と
`Back from Loan`は既定で除外する。
検証目的で含める場合だけ`--include-loan-returns`を指定する。
無料プランの10回/分を超えないよう各リクエストを7秒間隔にする。HTTP 429または
レスポンス本文内のレート制限エラーが返った場合も61秒待って自動再試行するため、
20クラブの取込には数分かかる。待機表示が出ても、手動操作せず完了を待つ。

内容確認後、Application Default Credentialsを準備した開発環境だけで次を実行する。

```powershell
gcloud auth application-default login
Set-Location firebase
npm run import-api-football -- --season=2024 --max-teams=2 --write --project=transfer-now-dev
Set-Location ..
```

2クラブ分をFirestore Consoleで確認してから、`--max-teams=20`へ拡大する。

取込後は、公開前に読み取り専用の品質監査を実行する。

```powershell
Set-Location firebase
npm run audit-api-football -- --project=transfer-now-dev
Set-Location ..
```

監査は件数、日付範囲、移籍種別、入出方向、移籍金の取得率、欠損・育成チーム・
フリーエージェント経由などの要確認フラグを集計するだけで、Firestoreを変更しない。

書き込み先はクライアントから読み書きできない`externalTransfers`と
`externalImportRuns`。外部APIの確定移籍履歴は、アプリが必要とする噂・複数情報源・
選手詳細を含まないため、審査せず`transferCases`へ直接公開しない。

## Firestore構造

アプリが購読する`transferCases/{caseId}`は、一覧表示のたびに複数ドキュメントを
取得しなくて済むよう、選手・移籍元クラブ・移籍先クラブ・情報源・タイムラインを
埋め込んだ読み取り最適化ドキュメントにする。タイムラインが大きくなる場合は
将来サブコレクションへ分離する。

マスターデータ:

- `leagues/{leagueId}`
- `clubs/{clubId}`
- `players/{playerId}`
- `sources/{sourceId}`

ユーザー別データ:

- `users/{uid}/devices/{tokenId}`: FCMトークン
- `users/{uid}/preferences/favorites`: お気に入りクラブ名・移籍案件ID
- `users/{uid}/preferences/notifications`: 通知カテゴリ・お気に入り限定設定
- `users/{uid}/favoriteClubs/{clubId}`: 将来の正規化候補
- `users/{uid}/favoriteCases/{caseId}`: 将来の正規化候補

移籍情報とマスターは認証済みユーザーだけが読み取り可能で、クライアント書き込みは
禁止している。ユーザー配下は本人だけが読み書きできる。移籍情報の更新とFCM送信は
Admin SDKを使う信頼済みサーバーまたはCloud Functionsから行う。

## Firebaseプロジェクト作成

1. Firebase Consoleでプロジェクトを作る。
2. Androidアプリをapplication ID `com.transfernow.transfer_now`で登録する。
3. AuthenticationのSign-in methodで「匿名」と「Google」を有効化する。
4. Firestore Databaseを作成する。最初から本番モードを選び、リポジトリのRulesを適用する。
5. Cloud Messagingを有効にする。iOS対応時はAPNsキーも登録する。
6. 許諾済みの実画像をリモート配信する場合だけ、Blazeプランへ変更してStorageを作成する。

Firebase CLIをインストールしてログイン後、Rulesを反映する:

```powershell
firebase login
firebase use --add
firebase deploy --only firestore:rules,firestore:indexes
firebase deploy --only auth
```

## 選手画像・クラブエンブレム（任意のStorage差し替え）

標準構成は課金リスクのないアプリ内同梱方式。選手は
`assets/images/player_placeholder.png`のオリジナル共通イラスト、クラブは
クラブカラーと略称から描画するモノグラムを利用する。Storage設定は不要。

以下は、利用許諾を確認した実画像を将来リモート配信するときだけ実施する。

2026年2月3日以降、Cloud Storage for Firebaseの利用にはBlazeプランが必要。
Firebase Consoleの「Storage」からデフォルトバケットを作成する。Firestoreと同じ
`asia-northeast1`を選ぶと管理しやすいが、作成後にロケーションは変更できない。

バケット作成後、Storage Rulesを反映する:

```powershell
firebase deploy --only storage
```

利用許諾を確認した画像を`firebase/assets/players/`と
`firebase/assets/club-crests/`へ置く。ファイル名はFirestoreのIDと一致させる。
詳しいIDと推奨サイズは[firebase/assets/README.md](../firebase/assets/README.md)を参照。

```powershell
Set-Location firebase
npm run sync-assets -- --project=transfer-now-dev --dry-run
npm run sync-assets -- --project=transfer-now-dev
Set-Location ..
```

同期スクリプトは画像をStorageへアップロードし、`players.imageUrl`、
`clubs.crestUrl`と、`transferCases`内に埋め込まれた同じURLをまとめて更新する。
アプリは既存の`Image.network`表示へリアルタイムで切り替わるため、画像のためだけの
アプリ再ビルドは不要。Storageへのクライアント書き込みはRulesで禁止している。

公式クラブマークや報道写真は、著作権・商標・肖像に関する利用条件を確認してから
投入する。画像ファイル自体は`.gitignore`対象で、Gitにはコミットしない。

## Flutter接続（Android）

Firebase ConsoleからAndroidアプリの`google-services.json`をダウンロードし、
`android/app/google-services.json`へ配置する。Google Services Gradleプラグインが
ビルド時にこのファイルを処理する。API keyやApp IDはFirebaseアプリの公開識別子であり、
Admin SDKの秘密鍵ではない。サービスアカウントJSONはFlutterへ絶対に含めない。

```powershell
flutter run
```

Web/iOSを追加するときは`config/firebase.example.json`の値を使って起動できる。
Firebase初期化に失敗した場合は、アプリがクラッシュせずダミーRepositoryへ戻る。
接続後にデータ読み取りが失敗した場合は、各画面のエラー・再試行UIを表示する。

## 開発用12案件の投入

シードはAdmin SDKを使うため、Node.js 22以上とApplication Default Credentialsが必要。
破棄可能な開発プロジェクトだけを対象にする。

```powershell
gcloud auth application-default login
Set-Location firebase
npm install
npm run seed -- --project=YOUR_FIREBASE_PROJECT_ID
Set-Location ..
```

スクリプトは既知のIDへ`merge`で書き込み、既存の本番ユーザーは削除しない。ただし
同じIDの移籍案件とマスターを上書きするため、本番プロジェクトでは実行しない。

## ユーザー設定同期

お気に入りと通知設定は、操作直後に`SharedPreferences`へ保存して画面へ反映し、
同時に現在のFirebase Auth UID配下へ書き込む。通信エラーでクラウド書き込みが
完了しなかった場合は端末にpendingフラグを残し、次回初期化または設定変更時に
再試行する。クラウド値の読み込み失敗で端末設定を消すことはない。

初回は匿名認証で開始し、MY画面の「Googleでデータを引き継ぐ」からGoogleアカウントへ
リンクできる。新規リンクでは匿名ユーザーのUIDを維持するため、既存のFirestoreデータも
そのまま引き継ぐ。すでに別端末でリンク済みのGoogleアカウントを選んだ場合はそのUIDへ
サインインし、端末側とクラウド側のお気に入りを統合する。

AndroidのGoogleログインには、実行に使う署名証明書のSHA-1/SHA-256をFirebaseへ登録し、
OAuthクライアントを含む最新の`google-services.json`へ更新する必要がある。現在の開発用
debug署名は登録済み。Play Store公開時はPlay App SigningのSHA-1/SHA-256も追加する。
Google AuthenticationはSparkプランで利用でき、この設定だけでBlazeへの変更は不要。

## 次のバックエンド工程

1. Appleログインを追加（iOS対応時）
2. ステージング移籍を選手・クラブ情報で補完し、`transferCases`へ昇格
3. Football APIを定期取得するCloud Functions / Cloud Scheduler
4. 出典の統合、確率計算、AI要約を行うサーバーパイプライン
5. 案件更新時にFCMトピックまたは対象端末へ通知

参考:

- https://firebase.google.com/docs/flutter/setup
- https://firebase.google.com/docs/auth/flutter/anonymous-auth
- https://firebase.google.com/docs/auth/flutter/federated-auth
- https://firebase.google.com/docs/auth/flutter/account-linking
- https://www.api-football.com/documentation-v3
- https://firebase.google.com/docs/firestore/security/get-started
- https://firebase.google.com/docs/cloud-messaging/flutter/get-started
