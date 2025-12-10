crumb :root do
  link "HOME", root_path
end

# ====== 個人用カード系 ======
crumb :cards do
  link "カード", cards_path
  parent :root
end

crumb :card do |card|
  truncated_name = card.name.length > 8 ? "#{card.name[0...8]}..." : card.name
  link truncated_name, card_path(card)
  parent :cards
end

crumb :card_spot do |card, spot|
  truncated_name = spot.name.length > 8 ? "#{spot.name[0...8]}..." : spot.name
  link truncated_name, card_spot_path(card, spot)
  parent :card, card
end

# ====== グループ系 ======
crumb :groups do
  link "グループ", groups_path
  parent :root
end

crumb :group do |group|
  truncated_name = group.name.length > 8 ? "#{group.name[0...8]}..." : group.name
  link truncated_name, group_path(group)
  parent :groups
end

# グループ内カード
crumb :group_card do |group, card|
  truncated_name = card.name.length > 8 ? "#{card.name[0...8]}..." : card.name
  link truncated_name, group_card_path(group, card)
  parent :group, group
end

crumb :group_card_spot do |group, card, spot|
  truncated_name = spot.name.length > 8 ? "#{spot.name[0...8]}..." : spot.name
  link truncated_name, group_card_spot_path(group, card, spot)
  parent :group_card, group, card
end

# グループしおり
crumb :group_schedule_label do |group|
  link "しおり", group_schedule_path(group)
  parent :group, group
end

crumb :group_schedule do |group|
  truncated_name = group.schedule.name.length > 8 ? "#{group.schedule.name[0...8]}..." : group.schedule.name
  link truncated_name, group_schedule_path(group)
  parent :group_schedule_label, group
end

crumb :group_schedule_spot do |group, schedule_spot|
  display_name = schedule_spot.display_name
  truncated_name = display_name.length > 8 ? "#{display_name[0...8]}..." : display_name
  link truncated_name, group_schedule_schedule_spot_path(group, schedule_spot)
  parent :group_schedule, group
end

# ====== 個人用しおり系 ======
crumb :schedules do
  link "しおり", schedules_path
  parent :root
end

crumb :schedule do |schedule|
  truncated_name = schedule.name.length > 8 ? "#{schedule.name[0...8]}..." : schedule.name
  link truncated_name, schedule_path(schedule)
  parent :schedules
end

crumb :schedule_spot do |schedule, schedule_spot|
  display_name = schedule_spot.display_name
  truncated_name = display_name.length > 8 ? "#{display_name[0...8]}..." : display_name
  link truncated_name, schedule_schedule_spot_path(schedule, schedule_spot)
  parent :schedule, schedule
end
