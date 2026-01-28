# スマホ：アイコン、パソコン：アイコン＋ラベル
module IconButtonStyling
  extend ActiveSupport::Concern

  # btn-**クラスはtailwindで定義（暫定）
  PRIMARY_ICON_BUTTON_CLASSES = "btn-main-icon p-2 lg:px-4 lg:py-2 inline-flex items-center gap-2 lg:gap-3".freeze
  DANGER_ICON_BUTTON_CLASSES = "btn-danger p-2 lg:px-4 lg:py-2 inline-flex items-center gap-2 lg:gap-3".freeze
  LABEL_STYLE_CLASSES = "hidden lg:inline text-sm".freeze
end
