require "capybara/cuprite"

# Cupriteドライバーの登録
Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [375, 812],
    browser_options: {
      'no-sandbox': nil,
      'disable-gpu': nil,
      'disable-dev-shm-usage': nil
    },
    # テストの結果をブラウザで見て確認したいとき（INSPECTOR=true bundle exec rspec）
    inspector: ENV['INSPECTOR']
  )
end

# JavaScriptテストのデフォルトドライバーをCupriteに設定
Capybara.javascript_driver = :cuprite

# サーバー設定（Docker環境対応）
Capybara.server_host = '0.0.0.0'
Capybara.server_port = 3001

# タイムアウト設定
Capybara.default_max_wait_time = 5
