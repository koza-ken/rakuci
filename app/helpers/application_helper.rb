module ApplicationHelper
  # フラッシュメッセージのスタイルクラスを返す
  def flash_style_classes(type)
    case type.to_s
    when "notice"
      "bg-green-500"
    when "alert", "error"
      "bg-red-500"
    else
      "bg-blue-500"
    end
  end

  # フラッシュメッセージのアイコンを返す
  def flash_icon(type)
    case type.to_s
    when "notice"
      # svgをrawで埋め込むとセキュリティリスク（XSS）になるので、部分テンプレートに切り出し
      render "shared/icon/flash_icon_success"
    when "alert", "error"
      render "shared/icon/flash_icon_error"
    else
      render "shared/icon/flash_icon_info"
    end
  end

  # ページタイトルの動的表示
  def page_title(title = "")
    base_title = "RakuCi"
    title.present? ? "#{title} | #{base_title}" : base_title
  end

  # ホーム（トップ）ではパンくずを表示しない
  def show_breadcrumbs?
    !current_page?(root_path)
  end

  # ナビゲーションリンクのアクティブ状態クラスを返す（URLパターン判定）
  def nav_link_class(menu_type)
    path = request.path

    is_active = case menu_type
    when "cards"
      # カード判定：ユーザーカード または ユーザーカードスポット
      is_user_cards = path.include?("cards") && !path.start_with?("/group")
      is_user_card_spots = path.start_with?("/user/") && path.include?("spots") && path.exclude?("schedule")
      is_user_cards || is_user_card_spots
    when "groups"
      # グループ判定：グループ系ページ、ただしschedule/expenses除外
      is_group_page = path.include?("groups") || path.start_with?("/group/")
      is_not_schedule_or_expenses = path.exclude?("schedule") && path.exclude?("expenses")
      is_group_page && is_not_schedule_or_expenses
    when "schedules"
      # しおり判定：schedule関連 または 精算ページ（グループしおりのみなので）
      is_schedule_related = path.include?("schedule")
      is_expenses = path.include?("expenses")
      is_schedule_related || is_expenses
    when "item_list"
      # もちもの判定：item_list、ただしschedule配下は除外
      is_item_list = path.include?("item_list")
      is_not_schedule = path.exclude?("schedule")
      is_item_list && is_not_schedule
    when "profile"
      path.include?("profile")
    else
      false
    end

    if is_active
      "text-lg text-secondary border-b-2 border-secondary font-semibold"
    else
      "text-lg text-text hover:text-secondary transition"
    end
  end
end
