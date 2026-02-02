# == Schema Information
#
# Table name: expenses
#
#  id                    :bigint           not null, primary key
#  amount                :integer          not null
#  memo                  :text
#  name                  :string(100)      not null
#  paid_at               :date             not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  group_id              :bigint           not null
#  paid_by_membership_id :bigint           not null
#
# Indexes
#
#  index_expenses_on_group_id               (group_id)
#  index_expenses_on_paid_by_membership_id  (paid_by_membership_id)
#
# Foreign Keys
#
#  fk_rails_...  (group_id => groups.id)
#  fk_rails_...  (paid_by_membership_id => group_memberships.id)
#
require 'rails_helper'

RSpec.describe Expense, type: :model do
  describe 'バリデーション' do
    let(:user) { create(:user) }
    let(:group) { create(:group, created_by_user_id: user.id) }
    let(:membership) { create(:group_membership, group: group, user: user) }

    describe 'name' do
      context '存在しない場合' do
        it '無効であること' do
          expense = build(:expense, group: group, paid_by_membership_id: membership.id, name: '')
          expect(expense).not_to be_valid
          expect(expense.errors[:name]).to be_present
        end
      end

      context '100文字を超える場合' do
        it '無効であること' do
          expense = build(:expense, group: group, paid_by_membership_id: membership.id, name: 'a' * 101)
          expect(expense).not_to be_valid
          expect(expense.errors[:name]).to be_present
        end
      end

      context '100文字以内の場合' do
        it '有効であること' do
          expense = build(:expense, group: group, paid_by_membership_id: membership.id, name: 'a' * 100)
          expect(expense).to be_valid
        end
      end
    end

    describe 'amount' do
      context '存在しない場合' do
        it '無効であること' do
          expense = build(:expense, group: group, paid_by_membership_id: membership.id, amount: nil)
          expect(expense).not_to be_valid
          expect(expense.errors[:amount]).to be_present
        end
      end

      context '0の場合' do
        it '無効であること' do
          expense = build(:expense, group: group, paid_by_membership_id: membership.id, amount: 0)
          expect(expense).not_to be_valid
          expect(expense.errors[:amount]).to be_present
        end
      end

      context '負の数の場合' do
        it '無効であること' do
          expense = build(:expense, group: group, paid_by_membership_id: membership.id, amount: -1000)
          expect(expense).not_to be_valid
          expect(expense.errors[:amount]).to be_present
        end
      end

      context '正の整数の場合' do
        it '有効であること' do
          expense = build(:expense, group: group, paid_by_membership_id: membership.id, amount: 1000)
          expect(expense).to be_valid
        end
      end

      context '小数の場合' do
        it '無効であること' do
          expense = build(:expense, group: group, paid_by_membership_id: membership.id, amount: 1000.5)
          expect(expense).not_to be_valid
          expect(expense.errors[:amount]).to be_present
        end
      end
    end

    describe 'paid_at' do
      context '存在しない場合' do
        it '無効であること' do
          expense = build(:expense, group: group, paid_by_membership_id: membership.id, paid_at: nil)
          expect(expense).not_to be_valid
          expect(expense.errors[:paid_at]).to be_present
        end
      end

      context '日付が設定されている場合' do
        it '有効であること' do
          expense = build(:expense, group: group, paid_by_membership_id: membership.id, paid_at: Date.current)
          expect(expense).to be_valid
        end
      end
    end

    describe 'participants_must_exist（カスタムバリデーション）' do
      context '対象者が選択されていない場合' do
        it '無効であること' do
          expense = build(:expense, group: group, paid_by_membership_id: membership.id)
          expense.expense_participants.clear
          expect(expense).not_to be_valid
          expect(expense.errors[:base]).to include('対象者を選択してください')
        end
      end

      context '対象者が1人以上選択されている場合' do
        it '有効であること' do
          expense = build(:expense, group: group, paid_by_membership_id: membership.id,
                          expense_participants_list: [ membership ])
          expect(expense).to be_valid
        end
      end
    end

    describe 'paid_by_membership_belongs_to_group' do
      let(:other_user) { create(:user) }
      let(:other_group) { create(:group, created_by_user_id: other_user.id) }
      let(:other_membership) { create(:group_membership, group: other_group, user: other_user) }

      context 'paid_by_membershipがグループに属していない場合' do
        it '無効であること' do
          expense = build(:expense, group: group, paid_by_membership_id: other_membership.id)
          expect(expense).not_to be_valid
          expect(expense.errors[:paid_by_membership]).to include('はこのグループに属していません')
        end
      end

      context 'paid_by_membershipがグループに属している場合' do
        it '有効であること' do
          expense = build(:expense, group: group, paid_by_membership_id: membership.id)
          expect(expense).to be_valid
        end
      end
    end
  end

  describe '#paid_by?' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:group) { create(:group, created_by_user_id: user1.id) }
    let(:membership1) { create(:group_membership, group: group, user: user1) }
    let(:membership2) { create(:group_membership, group: group, user: user2) }
    let(:expense) do
      create(:expense, group: group, paid_by_membership_id: membership1.id,
             expense_participants_list: [ membership1 ])
    end

    context '指定されたメンバーシップが支出を支払った人の場合' do
      it 'trueを返すこと' do
        expect(expense.paid_by?(membership1)).to be true
      end
    end

    context '指定されたメンバーシップが支出を支払っていない場合' do
      it 'falseを返すこと' do
        expect(expense.paid_by?(membership2)).to be false
      end
    end

    context 'nilが渡された場合' do
      it 'falseを返すこと' do
        expect(expense.paid_by?(nil)).to be false
      end
    end
  end

  describe '.ordered_by_paid_at' do
    let(:user) { create(:user) }
    let(:group) { create(:group, created_by_user_id: user.id) }
    let(:membership) { create(:group_membership, group: group, user: user) }

    let(:expense1) do
      create(:expense, group: group, paid_by_membership_id: membership.id,
             paid_at: Date.new(2024, 1, 1), expense_participants_list: [ membership ])
    end

    let(:expense2) do
      create(:expense, group: group, paid_by_membership_id: membership.id,
             paid_at: Date.new(2024, 1, 3), expense_participants_list: [ membership ])
    end

    let(:expense3) do
      create(:expense, group: group, paid_by_membership_id: membership.id,
             paid_at: Date.new(2024, 1, 2), expense_participants_list: [ membership ])
    end

    it '支払日の降順で並ぶこと' do
      # let の lazy evaluation を回避するため明示的に参照
      [ expense1, expense2, expense3 ].each(&:id)

      expect(described_class.ordered_by_paid_at.pluck(:id)).to eq([ expense2.id, expense3.id, expense1.id ])
    end

    it 'expense_participants が正しく作成されること' do
      expect(expense1.expense_participants).not_to be_empty
    end
  end

  describe 'アソシエーション' do
    let(:user) { create(:user) }
    let(:group) { create(:group, created_by_user_id: user.id) }
    let(:membership) { create(:group_membership, group: group, user: user) }

    it 'groupに属すること' do
      expense = create(:expense, group: group, paid_by_membership_id: membership.id,
                       expense_participants_list: [ membership ])
      expect(expense.group).to eq(group)
    end

    it 'paid_by_membershipに属すること' do
      expense = create(:expense, group: group, paid_by_membership_id: membership.id,
                       expense_participants_list: [ membership ])
      expect(expense.paid_by_membership).to eq(membership)
    end

    it 'expense_participantsを持つこと' do
      expense = create(:expense, group: group, paid_by_membership_id: membership.id,
                       expense_participants_list: [ membership ])
      expect(expense.expense_participants).not_to be_empty
    end

    it 'participantsを通じてグループメンバーを取得できること' do
      expense = create(:expense, group: group, paid_by_membership_id: membership.id,
                       expense_participants_list: [ membership ])
      expect(expense.participants).to include(membership)
    end
  end
end
