# == Schema Information
#
# Table name: packing_lists
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
#  index_packing_lists_on_listable  (listable_type,listable_id) UNIQUE
#
require 'rails_helper'

RSpec.describe PackingList, type: :model do
  describe 'バリデーション' do
    let(:user) { create(:user) }

    describe 'listable' do
      context '存在しない場合' do
        it '無効であること' do
          packing_list = described_class.new(listable_type: 'User', name: 'テスト')
          expect(packing_list).not_to be_valid
          expect(packing_list.errors[:listable]).to be_present
        end
      end
    end

    describe 'name' do
      context '100文字を超える場合' do
        it '無効であること' do
          packing_list = build(:packing_list, listable: user, name: 'a' * 101)
          expect(packing_list).not_to be_valid
          expect(packing_list.errors[:name]).to be_present
        end
      end

      context '100文字以内である場合' do
        it '有効であること' do
          packing_list = build(:packing_list, listable: user, name: 'a' * 100)
          expect(packing_list).to be_valid
        end
      end
    end
  end

  describe 'ポリモーフィック関連付け' do
    let(:user) { create(:user) }
    let(:schedule) { create(:schedule, schedulable: user) }

    context 'User に紐付く場合' do
      let(:packing_list) { user.packing_list }

      it 'listable_type が User であること' do
        expect(packing_list.listable_type).to eq('User')
      end

      it 'listable として User を取得できること' do
        expect(packing_list.listable).to eq(user)
      end
    end

    context 'Schedule に紐付く場合' do
      let(:packing_list) { schedule.packing_list }

      it 'listable_type が Schedule であること' do
        expect(packing_list.listable_type).to eq('Schedule')
      end

      it 'listable として Schedule を取得できること' do
        expect(packing_list.listable).to eq(schedule)
      end
    end
  end

  describe 'dependent: :destroy' do
    let(:user) { create(:user) }
    let(:packing_list) { user.packing_list }

    before do
      create_list(:packing_item, 3, packing_list: packing_list)
    end

    it 'PackingList を削除すると関連する PackingItem も削除される' do
      expect { packing_list.destroy }.to change(PackingItem, :count).by(-3)
    end
  end
end
