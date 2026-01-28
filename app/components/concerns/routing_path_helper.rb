# frozen_string_literal: true

# ルーティングパス生成のヘルパーモジュール（ボタンコンポーネントにpathを渡すための処理）
# EditButtonComponent と DeleteButtonComponent で共有
module RoutingPathHelper
  extend ActiveSupport::Concern

  # Shallow routing を使用するリソース（親リソースのIDなしでアクセス可能）例: /user/schedule_spots/:id （親のschedule_idは不要）
  SHALLOW_RESOURCES = %w[ScheduleSpot Spot].freeze
  # Group scope でネストされていて、group + resource の両方の引数が必要なリソース 例: edit_group_card_path(group, card) のように、groupとresourceの両方を渡す
  GROUP_PLURAL_RESOURCES = %w[Card Expense].freeze


  private

  # ルーティング規則に基づいてパスプレフィックスを生成
  def path_prefix
    case
    # Group scope：常に "group_*" を含む
    when group_scope?
      "group_#{@resource.class.name.underscore}"
    # User scope のshallow routing：  "user_*" を含む
    when user_scope? && shallow_resource?
      "user_#{@resource.class.name.underscore}"
    # User scope のregular resources：   "*" のみ（"user" なし）
    when user_scope?
      @resource.class.name.underscore
    else
      raise_unsupported_combination_error
    end
  end

  # ルーティング規則に基づいてメソッドに必要なパラメータを決定して実行
  def send_path_method(path_method)
    case
    # Group schedule（singular）：group のみ
    when group_scope? && schedule_resource?
      send(path_method, @scope)
    # Group card/expense（複数形）：group + resource
    when group_scope? && group_plural_resource?
      send(path_method, @scope, @resource)
    # その他（Group shallow routing, User）：resource のみ
    else
      send(path_method, @resource)
    end
  end


  # ========== ヘルパーメソッド ==========
  # Group scope かどうか
  def group_scope?
    @scope.class.name == "Group"
  end

  # User scope かどうか
  def user_scope?
    @scope.class.name == "User"
  end

  # Schedule リソースかどうか
  def schedule_resource?
    @resource.class.name == "Schedule"
  end

  # Shallow routing を使用するリソースかどうか
  def shallow_resource?
    SHALLOW_RESOURCES.include?(@resource.class.name)
  end


  # Group の複数形リソースかどうか
  def group_plural_resource?
    GROUP_PLURAL_RESOURCES.include?(@resource.class.name)
  end

  # ========== エラーハンドリング ==========
  # サポートされていないscope/resourceの組み合わせエラー
  def raise_unsupported_combination_error
    supported_combinations = <<~TEXT
      サポートされている組み合わせ:
      - User + Schedule/Card（通常リソース）
      - User + ScheduleSpot/Spot（Shallow リソース）
      - Group + Schedule/Card/Expense/ScheduleSpot/Spot
    TEXT

    raise ArgumentError, <<~ERROR
      サポートされていない scope/resource の組み合わせ: #{@scope.class.name}/#{@resource.class.name}

      #{supported_combinations}
    ERROR
  end
end
