# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# カテゴリの初期データ
puts "カテゴリの初期データを作成中..."

categories = [
  { name: "観光スポット", display_order: 1 },
  { name: "グルメ", display_order: 2 },
  { name: "体験", display_order: 3 },
  { name: "買い物", display_order: 4 }
]

categories.each do |category_data|
  category = Category.find_or_initialize_by(name: category_data[:name])
  category.display_order = category_data[:display_order]
  category.save!
  puts "  - #{category.name} (display_order: #{category.display_order})"
end

puts "カテゴリの初期データを作成しました (#{Category.count}件)"
