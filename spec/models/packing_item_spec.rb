# == Schema Information
#
# Table name: packing_items
#
#  id              :bigint           not null, primary key
#  checked         :boolean          default(FALSE), not null
#  name            :string(100)      not null
#  position        :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  packing_list_id :integer          not null
#
# Indexes
#
#  index_packing_items_on_list_and_position  (packing_list_id,position)
#  index_packing_items_on_packing_list_id    (packing_list_id)
#
# Foreign Keys
#
#  fk_rails_...  (packing_list_id => packing_lists.id)
#
require 'rails_helper'

RSpec.describe PackingItem, type: :model do
  describe 'バリデーション' do
    describe 'name' do
      context '存在しない場合' do
        it '無効であること' do
          packing_item = described_class.new(checked: false)
          expect(packing_item).not_to be_valid
          expect(packing_item.errors[:name]).to be_present
        end
      end

      context '100文字を超える場合' do
        it '無効であること' do
          user = create(:user)
          packing_list = user.packing_list
          packing_item = build(:packing_item, packing_list: packing_list, name: 'a' * 101)
          expect(packing_item).not_to be_valid
          expect(packing_item.errors[:name]).to be_present
        end
      end

      context '100文字以内の場合' do
        it '有効であること' do
          user = create(:user)
          packing_list = user.packing_list
          packing_item = build(:packing_item, packing_list: packing_list, name: 'a' * 100)
          expect(packing_item).to be_valid
        end
      end
    end
  end

  describe 'acts_as_list' do
    let(:user) { create(:user) }
    let(:schedule_a) { create(:schedule, schedulable: user, name: 'スケジュール A') }
    let(:schedule_b) { create(:schedule, schedulable: user, name: 'スケジュール B') }
    let(:packing_list_a) { schedule_a.packing_list }
    let(:packing_list_b) { schedule_b.packing_list }

    context '同じリスト内での並び順管理' do
      let!(:item1) { create(:packing_item, packing_list: packing_list_a, name: 'アイテム 1') }
      let!(:item2) { create(:packing_item, packing_list: packing_list_a, name: 'アイテム 2') }
      let!(:item3) { create(:packing_item, packing_list: packing_list_a, name: 'アイテム 3') }

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
      let!(:item_a1) { create(:packing_item, packing_list: packing_list_a, name: 'リスト A - アイテム 1') }
      let!(:item_a2) { create(:packing_item, packing_list: packing_list_a, name: 'リスト A - アイテム 2') }
      let!(:item_b1) { create(:packing_item, packing_list: packing_list_b, name: 'リスト B - アイテム 1') }
      let!(:item_b2) { create(:packing_item, packing_list: packing_list_b, name: 'リスト B - アイテム 2') }

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
    let(:packing_list) { user.packing_list }
    let(:packing_item) { create(:packing_item, packing_list: packing_list, name: 'テストアイテム') }

    it 'デフォルトで false になること' do
      expect(packing_item.checked).to be false
    end
  end
end
