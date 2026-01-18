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
                  # カード判定：
                  # - /cardsを含む（ただし/group/で始まらない）、または
                  # - /user/で始まり、かつspotsを含む（ただしschedule関連は除外）
                  path.include?("cards") && !path.start_with?("/group") ||
                  (path.start_with?("/user/") && path.include?("spots") && !path.include?("schedule"))
                when "groups"
                  # グループ判定：
                  # - /groupsを含む、または/group/で始まる
                  # - ただしschedule関連とexpensesは除外
                  (path.include?("groups") || path.start_with?("/group/")) &&
                  !path.include?("schedule") && !path.include?("expenses")
                when "schedules"
                  # しおり判定：schedule, schedules, schedule_spots, expenses のいずれかを含む
                  path.include?("schedule") || path.include?("expenses")
                when "item_list"
                  # もちもの判定：item_listを含む、ただしschedule配下は除外
                  path.include?("item_list") && !path.include?("schedule")
                when "profile"
                  path.include?("profile")
                else
                  false
                end

    if is_active
      "text-secondary border-b-2 border-secondary font-semibold"
    else
      "text-text hover:text-secondary transition"
    end
  end
end
