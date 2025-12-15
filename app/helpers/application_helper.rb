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
end
