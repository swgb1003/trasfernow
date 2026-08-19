# TRANSFER NOW

Flutterによるサッカー移籍情報アプリ。仕様の一次情報は [docs/SPEC.md](docs/SPEC.md)、画面モックアップは [screen_sample.png](screen_sample.png)。コード内で仕様の特定機能を実装する際は `// See SPEC.md §NN` の形でセクション番号を参照するコメントを残す(既存コードの慣習に合わせる)。

## 現在のフェーズ

開発方針(SPEC.md §36)通り、**バックエンド・外部APIは未接続**。全画面が [lib/data/dummy_transfer_cases.dart](lib/data/dummy_transfer_cases.dart) の12件のダミーデータのみで動作している。AI REPORTER画面も生成AIではなく、[lib/data/ai_reporter_engine.dart](lib/data/ai_reporter_engine.dart) のルールベースのキーワードマッチング。ダミーデータに実在の選手名を使っているが、移籍状況(ステータス・成立可能性・タイムライン)はすべて架空。

## コマンド

```
flutter pub get      # 依存関係取得
flutter analyze      # 静的解析(コード変更後は必ず実行)
flutter test         # ウィジェットテスト(コード変更後は必ず実行)
flutter run          # 実機/エミュレータ起動
```

変更を「完了」とみなす前に `flutter analyze` → `flutter test` の両方が通ることを確認する。

## ディレクトリ構成

```
lib/
  app/        アプリシェル・ルーティング(go_router, ボトムナビ5タブ)
  core/       デザインテーマ・カラートークン・日付フォーマット
  data/       ダミーデータ + Riverpodプロバイダ + AI応答エンジン
  models/     TransferCase, TransferStatus, TimelineEvent, TransferSource
  features/   live / detail / search / market / ai / my の画面
  widgets/    共通コンポーネント(カード、バッジ、ゲージ、アニメーション演出)
```

## 定型作業

### 新しいダミー移籍案件を追加する

[lib/data/dummy_transfer_cases.dart](lib/data/dummy_transfer_cases.dart) の `_buildDummyCases()` にリテラルを1件追加する。`ago(minutes)` / `daysAgo(days)` ヘルパーで `DateTime.now()` からの相対時刻にすること(絶対日付を埋め込むと「情報が古い」ように見えてしまう — 過去に実際指摘された)。`timeline` は古い順、最後の要素が現在のステータスと一致させる。

### 新しい画面を追加する

1. `lib/features/<name>/` にディレクトリを作り画面を実装
2. [lib/app/router.dart](lib/app/router.dart) の `buildAppRouter()` にルートを追加
3. ボトムナビに出す場合は [lib/app/root_shell.dart](lib/app/root_shell.dart) の `_destinations` にも追加

### 色・スタイルを使う

ハードコードせず [lib/core/theme/app_colors.dart](lib/core/theme/app_colors.dart) / [app_theme.dart](lib/core/theme/app_theme.dart) のトークンを参照する。ステータスごとの色は `TransferStatus.color`([transfer_status.dart](lib/models/transfer_status.dart))経由で取得する。

## 既知のハマりどころ(テスト・レイアウト)

- **GoRouterをトップレベル`final`にしない**: `GoRouter`はナビゲーション状態を自分自身に持つミュータブルなオブジェクト。シングルトンにするとテスト間(や複数インスタンス生成時)に画面遷移状態が漏れる。[lib/app/router.dart](lib/app/router.dart) の `buildAppRouter()` のように毎回新しいインスタンスを返す関数にし、`TransferNowApp`(StatefulWidget)の `initState` 相当で1つ生成して保持する。
- **`IntrinsicHeight` の中で `Stack` を使わない**: `Stack`は確定した高さがないと `size.isFinite` assertionで実機・テストともにクラッシュする。可変高さの行内で「光が伸びる」ような表現をしたい場合は `Stack`ではなく`AnimatedBuilder`でグラデーションの`stops`を動かす方式にする(例: [detail_screen.dart](lib/features/detail/detail_screen.dart) の `_Timeline` 内タイムライン接続線)。
- **無限ループするアニメーションがある画面で `pumpAndSettle()` を使わない**: パルス演出(`..repeat(reverse: true)`など)は永久に「settle」しないためテストがハングする。`for`ループで `tester.pump(Duration(...))` を規定回数呼ぶ方式にする。
- **`context.push()` 直後は1回空の `pump()` を挟む**: go_routerの画面遷移トランジションは、時間を指定した`pump(duration)`だけだと開始前のフレームを拾えないことがある。`await tester.pump(); await tester.pump(duration);` の2段階にすると安定する。
- **`find.text()` の文字列重複に注意**: 同じ文字列が別の場所でも使われていないか確認する(例: `TransferCase.probabilityLabel` が100%のとき返す `'OFFICIAL'` と、OFFICIAL演出オーバーレイの見出し文字列が衝突した)。曖昧な場合は `find.byType()` や `find.textContaining()` で一意に絞る。
- **`showModalBottomSheet`の中身は`MediaQuery.size.height`から自前でmaxHeightを計算しない**: シートの実際の高さは`isScrollControlled`の指定や画面サイズによって変わり、自前計算とズレるとオーバーフローする(実際に発生した)。`isScrollControlled: true` を指定した上で、可変長リスト部分は`ConstrainedBox`ではなく`Flexible`にラップし、親から降りてくる実際の制約に従わせる。
- **長いリストを`ListView(children:[...])`でテストする場合は`scrollUntilVisible`→`ensureVisible`の2段階にする**: 対象がビューポート外だと`find`で見つからず(`.builder`でなくてもスライバーは遅延マウントされる)、`scrollUntilVisible`だけだと要素の中心が可視領域の外に残ることがありタップが外れる(シートのバリアに当たって閉じてしまう)。`scrollUntilVisible`で存在を確定させた後、`ensureVisible`で完全に可視領域内へ寄せてからタップする。
