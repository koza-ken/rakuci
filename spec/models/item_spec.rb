# == Schema Information
#
# Table name: items
#
#  id           :bigint           not null, primary key
#  checked      :boolean          default(FALSE), not null
#  name         :string(100)      not null
#  position     :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  item_list_id :integer          not null
#
# Indexes
#
#  index_items_on_item_list_id       (item_list_id)
#  index_items_on_list_and_position  (item_list_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (item_list_id => item_lists.id)
#
require 'rails_helper'

RSpec.describe Item, type: :model do
  describe 'バリデーション' do
    describe 'name' do
      context '存在しない場合' do
        it '無効であること' do
          item = described_class.new(checked: false)
          expect(item).not_to be_valid
          expect(item.errors[:name]).to be_present
        end
      end

      context '100文字を超える場合' do
        it '無効であること' do
          user = create(:user)
          item_list = user.item_list
          item = build(:item, item_list: item_list, name: 'a' * 101)
          expect(item).not_to be_valid
          expect(item.errors[:name]).to be_present
        end
      end

      context '100文字以内の場合' do
        it '有効であること' do
          user = create(:user)
          item_list = user.item_list
          item = build(:item, item_list: item_list, name: 'a' * 100)
          expect(item).to be_valid
        end
      end
    end
  end

  describe 'acts_as_list' do
    let(:user) { create(:user) }
    let(:schedule_a) { create(:schedule, schedulable: user, name: 'スケジュール A') }
    let(:schedule_b) { create(:schedule, schedulable: user, name: 'スケジュール B') }
    let(:item_list_a) { schedule_a.item_list }
    let(:item_list_b) { schedule_b.item_list }

    context '同じリスト内での並び順管理' do
      let!(:item1) { create(:item, item_list: item_list_a, name: 'アイテム 1') }
      let!(:item2) { create(:item, item_list: item_list_a, name: 'アイテム 2') }
      let!(:item3) { create(:item, item_list: item_list_a, name: 'アイテム 3') }

      it 'position が自動的に割り当てられる' do
        expect(item1.position).to eq(1)
        expect(item2.position).to eq(2)
        expect(item3.position).to eq(3)
      end

      it 'アイテムを削除すると後続の position が繰り上がる' do
        item2.destroy
        expect(item3.reload.position).to eq(2)
      end
    end

    context '異なるリスト間での position の独立性' do
      let!(:item_a1) { create(:item, item_list: item_list_a, name: 'リスト A - アイテム 1') }
      let!(:item_a2) { create(:item, item_list: item_list_a, name: 'リスト A - アイテム 2') }
      let!(:item_b1) { create(:item, item_list: item_list_b, name: 'リスト B - アイテム 1') }
      let!(:item_b2) { create(:item, item_list: item_list_b, name: 'リスト B - アイテム 2') }

      it '各リストで独立した position を持つ' do
        expect(item_a1.position).to eq(1)
        expect(item_a2.position).to eq(2)
        expect(item_b1.position).to eq(1)
        expect(item_b2.position).to eq(2)
      end

      it 'リスト A のアイテムを削除してもリスト B には影響しない' do
        item_a1.destroy
        expect(item_a2.reload.position).to eq(1)
        expect(item_b1.reload.position).to eq(1)
        expect(item_b2.reload.position).to eq(2)
      end
    end
  end

  describe 'checked デフォルト値' do
    let(:user) { create(:user) }
    let(:item_list) { user.item_list }
    let(:item) { create(:item, item_list: item_list, name: 'テストアイテム') }

    it 'デフォルトで false になること' do
      expect(item.checked).to be false
    end
  end
end
