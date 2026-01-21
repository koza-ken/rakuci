# frozen_string_literal: true

class IconComponent < ViewComponent::Base
  def initialize(name:, size: 6,  breakpoints: {}, color: "text-text-light")
    @name = name                  # 部分テンプレートのファイル名
    @size = size
    @breakpoints = breakpoints
    @color = color
  end

  def size_class
    classes = "w-#{@size} h-#{@size}"

    @breakpoints.each do |breakpoint, bp_size|
      classes += " #{breakpoint}:w-#{bp_size} #{breakpoint}:h-#{bp_size}"
    end

    classes
  end
end
