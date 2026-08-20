# TRANSFER NOW

Flutterで構築した、サッカー移籍案件をリアルタイム形式で追跡するアプリ。

## Documentation

- [Product specification](docs/SPEC.md)
- [Backend development](docs/BACKEND.md)
- [Screen reference](screen_sample.png)

## Development

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

AndroidのFirebase設定ファイルを配置して起動する:

```powershell
# Firebase Consoleからダウンロードしたファイルをここへ配置
# android/app/google-services.json
flutter run
```

設定ファイルがない、またはFirebase初期化に失敗した場合は、ダミーRepositoryへ
自動的に戻る。Web/iOS用のコンパイル時設定テンプレートは
`config/firebase.example.json`に用意している。

Firebase接続時は匿名認証後にFirestoreの`transferCases`をリアルタイム購読し、
お気に入り・通知設定の端末キャッシュをユーザー配下へ同期し、FCM端末トークンを
登録する。開発用の12件を投入する手順、Security Rules、FCM設定は
[バックエンド開発手順](docs/BACKEND.md)を参照。

選手画像はアプリ内のオリジナル共通イラスト、クラブエンブレムはクラブカラーから
描画するオリジナルモノグラムを使用するため、画像表示にFirebase StorageやBlaze
プランは不要。許諾済みの実画像へ差し替える場合だけStorage同期を任意で利用できる。

API-Footballはdry-run／非公開ステージング取込まで実装済み。生成AI、定期取得、
FCMを送信するCloud Functionsはまだ未接続。
