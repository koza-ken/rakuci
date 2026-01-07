# ====== 個人用カード系 ======
crumb :cards do
  link "カード", cards_path
end

crumb :card do |card|
  truncated_name = card.name.length > 6 ? "#{card.name[0...6]}..." : card.name
  link truncated_name, card_path(card)
  parent :cards
end

crumb :card_spot do |spot|
  truncated_name = spot.name.length > 6 ? "#{spot.name[0...6]}..." : spot.name
  link truncated_name, user_spot_path(spot)
  parent :card, spot.card
end

# ====== グループ系 ======
crumb :groups do
  link "グループ", groups_path
end

crumb :group do |group|
  truncated_name = group.name.length > 6 ? "#{group.name[0...6]}..." : group.name
  link truncated_name, group_path(group)
  parent :groups
end

crumb :group_for_card do |group|
  link "グループ", groups_path
end

crumb :group_name_for_card do |group|
  truncated_name = group.name.length > 6 ? "#{group.name[0...6]}..." : group.name
  link truncated_name, group_path(group)
  parent :group_for_card, group
end

# グループ内カード
crumb :group_card do |group, card|
  truncated_name = card.name.length > 6 ? "#{card.name[0...6]}..." : card.name
  link truncated_name, group_card_path(group, card)
  parent :group_name_for_card, group
end

crumb :group_card_spot do |spot|
  truncated_name = spot.name.length > 6 ? "#{spot.name[0...6]}..." : spot.name
  link truncated_name, group_spot_path(spot)
  parent :group_card, spot.card.group, spot.card
end

# グループしおり
crumb :group_schedule_label do |group|
  link "しおり", group_schedule_path(group)
  parent :group, group
end

crumb :group_schedule do |group|
  truncated_name = group.schedule.name.length > 6 ? "#{group.schedule.name[0...6]}..." : group.schedule.name
  link truncated_name, group_schedule_path(group)
  parent :group_schedule_label, group
end

crumb :group_schedule_spot do |schedule_spot|
  display_name = schedule_spot.display_name
  truncated_name = display_name.length > 6 ? "#{display_name[0...6]}..." : display_name
  link truncated_name, group_schedule_spot_path(schedule_spot)
  parent :group_schedule, schedule_spot.schedule.schedulable
end

crumb :group_schedule_item_list do |group|
  link "もちもの", group_schedule_item_list_path(group)
  parent :group_schedule, group
end

crumb :group_expenses do |group|
  link "精算", group_expenses_path(group)
  parent :group_schedule, group
end

# ====== 個人用しおり系 ======
crumb :schedules do
  link "しおり", schedules_path
end

crumb :schedule do |schedule|
  truncated_name = schedule.name.length > 6 ? "#{schedule.name[0...6]}..." : schedule.name
  link truncated_name, schedule_path(schedule)
  parent :schedules
end

crumb :schedule_spot do |schedule_spot|
  display_name = schedule_spot.display_name
  truncated_name = display_name.length > 6 ? "#{display_name[0...6]}..." : display_name
  link truncated_name, user_schedule_spot_path(schedule_spot)
  parent :schedule, schedule_spot.schedule
end

crumb :schedule_item_list do |schedule|
  link "もちもの", schedule_item_list_path(schedule)
  parent :schedule, schedule
end
