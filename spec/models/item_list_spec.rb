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
  describe 'バリデーション' do
    let(:user) { create(:user) }

    describe 'listable_type' do
      context '存在しない場合' do
        it '無効であること' do
          item_list = ItemList.new(listable_id: user.id, name: 'テスト')
          expect(item_list).not_to be_valid
          expect(item_list.errors[:listable_type]).to be_present
        end
      end
    end

    describe 'listable_id' do
      context '存在しない場合' do
        it '無効であること' do
          item_list = ItemList.new(listable_type: 'User', name: 'テスト')
          expect(item_list).not_to be_valid
          expect(item_list.errors[:listable_id]).to be_present
        end
      end
    end

    describe 'name' do
      context '100文字を超える場合' do
        it '無効であること' do
          item_list = build(:item_list, listable: user, name: 'a' * 101)
          expect(item_list).not_to be_valid
          expect(item_list.errors[:name]).to be_present
        end
      end

      context '100文字以内である場合' do
        it '有効であること' do
          item_list = build(:item_list, listable: user, name: 'a' * 100)
          expect(item_list).to be_valid
        end
      end
    end
  end

  describe 'ポリモーフィック関連付け' do
    let(:user) { create(:user) }
    let(:schedule) { create(:schedule, schedulable: user) }

    context 'User に紐付く場合' do
      let(:item_list) { create(:item_list, listable: user) }

      it 'listable_type が User であること' do
        expect(item_list.listable_type).to eq('User')
      end

      it 'listable として User を取得できること' do
        expect(item_list.listable).to eq(user)
      end
    end

    context 'Schedule に紐付く場合' do
      let(:item_list) { create(:item_list, listable: schedule) }

      it 'listable_type が Schedule であること' do
        expect(item_list.listable_type).to eq('Schedule')
      end

      it 'listable として Schedule を取得できること' do
        expect(item_list.listable).to eq(schedule)
      end
    end
  end

  describe 'dependent: :destroy' do
    let(:user) { create(:user) }
    let(:item_list) { create(:item_list, listable: user) }

    before do
      create_list(:item, 3, item_list: item_list)
    end

    it 'ItemList を削除すると関連する Item も削除される' do
      expect { item_list.destroy }.to change(Item, :count).by(-3)
    end
  end
end
