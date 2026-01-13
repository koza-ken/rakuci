require "capybara/cuprite"

# JavaScriptテストのデフォルトドライバーを設定
Capybara.javascript_driver = :cuprite_docker

# すべてのテストのデフォルトドライバーを設定
Capybara.default_driver = :cuprite_docker

# Cupriteドライバーの登録（Docker環境用カスタム設定）
Capybara.register_driver(:cuprite_docker) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [375, 812],
    # コンテナ環境で安定させるためのオプション
    browser_options: {
      'no-sandbox': nil,
      'disable-gpu': nil,
      'disable-dev-shm-usage': nil, # /dev/shum（共有メモリ）が小さいのでChromeが使用するのを無効化
      'disable-software-rasterizer': nil, # 描画処理によって動作が不安定にならないように無効化（headlessで描画自体不要）
      'disable-features': 'dbus'
    },
    process_timeout: 30, # ブラウザ（Chromium）を起動するときの待ち時間（秒）
    pending_connection_errors: true,
    inspector: ENV['INSPECTOR']
  )
end


# サーバー設定（Docker環境対応）
Capybara.server_host = '0.0.0.0'
Capybara.server_port = 3001

# タイムアウト設定（DOM要素の出現待ち時間（秒））
Capybara.default_max_wait_time = 5
