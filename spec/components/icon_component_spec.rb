# frozen_string_literal: true

require "rails_helper"

describe IconComponent, type: :component do
  context "renders correctly" do
    it "renders with default size and color" do
      # IconComponent.new → described_class.newが適当（rubocop）
      render_inline described_class.new(name: "favicon")
      expect(page).to have_css(".w-6.h-6.text-text-light")
    end

    it "renders with custom size" do
      render_inline described_class.new(name: "favicon", size: 8)
      expect(page).to have_css(".w-8.h-8")
    end

    it "renders with custom color" do
      render_inline described_class.new(name: "favicon", color: "text-secondary")
      expect(page).to have_css(".text-secondary")
    end

    it "renders with responsive breakpoints" do
      html = render_inline(described_class.new(
        name: "favicon",
        size: 6,
        breakpoints: { md: 8, lg: 10 }
      )).to_s
      # Tailwind classes with responsive prefixes
      expect(page).to have_css(".w-6.h-6")
      expect(html).to include("md:w-8")
      expect(html).to include("lg:w-10")
    end

    it "renders the SVG icon" do
      render_inline described_class.new(name: "favicon")
      expect(page).to have_css("svg")
    end
  end

  context "with color and size combinations" do
    it "renders with multiple custom parameters" do
      html = render_inline(described_class.new(
        name: "favicon",
        size: 4,
        color: "text-primary",
        breakpoints: { sm: 5, md: 6 }
      )).to_s
      expect(page).to have_css(".w-4.h-4.text-primary")
      expect(html).to include("sm:w-5")
      expect(html).to include("md:w-6")
    end
  end
end
