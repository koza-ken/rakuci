# == Schema Information
#
# Table name: item_lists
#
#  id            :bigint           not null, primary key
#  listable_type :string           not null
#  name          :string(100)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  listable_id   :integer          not null
#
# Indexes
#
#  index_item_lists_on_listable  (listable_type,listable_id) UNIQUE
#
require 'rails_helper'

RSpec.describe ItemList, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
