require 'rails_helper'

RSpec.describe SettlementCalculator, type: :service do
  describe '#calculate' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:user3) { create(:user) }
    let(:group) do
      group = create(:group, created_by_user_id: user1.id)
      # breadcrumbs view rendering で schedule が必要な場合がある
      create(:schedule, schedulable: group)
      group
    end
    let(:membership1) { create(:group_membership, group: group, user: user1) }
    let(:membership2) { create(:group_membership, group: group, user: user2) }
    let(:membership3) { create(:group_membership, group: group, user: user3) }

    context '支出がない場合' do
      it '全メンバーの精算額が0になること' do
        # ensure all memberships are created (let is lazy-evaluated)
        [ membership1, membership2, membership3 ].each(&:id)

        calculator = described_class.new(group)
        result = calculator.calculate

        expect(result).to have_key(membership1.id)
        expect(result[membership1.id][:paid]).to eq(0)
        expect(result[membership1.id][:participation]).to eq(0)
        expect(result[membership1.id][:settlement]).to eq(0)
      end
    end

    context '1つの支出を3人で均等に割る場合' do
      before do
        create(:expense, group: group, paid_by_membership_id: membership1.id, amount: 3000,
               expense_participants_list: [ membership1, membership2, membership3 ])
      end

      it 'user1が支払い、user2とuser3が負担を持つこと' do
        calculator = described_class.new(group)
        result = calculator.calculate

        # user1: 3000支払い - 1000負担 = 2000受け取る
        expect(result[membership1.id][:paid]).to eq(3000)
        expect(result[membership1.id][:participation]).to eq(1000.0)
        expect(result[membership1.id][:settlement]).to eq(2000.0)

        # user2: 0支払い - 1000負担 = -1000支払う
        expect(result[membership2.id][:paid]).to eq(0)
        expect(result[membership2.id][:participation]).to eq(1000.0)
        expect(result[membership2.id][:settlement]).to eq(-1000.0)

        # user3: 0支払い - 1000負担 = -1000支払う
        expect(result[membership3.id][:paid]).to eq(0)
        expect(result[membership3.id][:participation]).to eq(1000.0)
        expect(result[membership3.id][:settlement]).to eq(-1000.0)
      end
    end

    context '複数の支出がある場合' do
      before do
        # 支出1: user1が3000円支払い、3人で均等割
        create(:expense, group: group, paid_by_membership_id: membership1.id, amount: 3000,
               expense_participants_list: [ membership1, membership2, membership3 ])

        # 支出2: user2が2000円支払い、2人で均等割
        create(:expense, group: group, paid_by_membership_id: membership2.id, amount: 2000,
               expense_participants_list: [ membership2, membership3 ])
      end

      it '各メンバーの累積精算額が正確に計算されること' do
        calculator = described_class.new(group)
        result = calculator.calculate

        # user1: 3000支払い - 1000負担 = 2000受け取る
        expect(result[membership1.id][:paid]).to eq(3000)
        expect(result[membership1.id][:participation]).to eq(1000.0)
        expect(result[membership1.id][:settlement]).to eq(2000.0)

        # user2: 2000支払い - (1000 + 1000負担) = 0
        expect(result[membership2.id][:paid]).to eq(2000)
        expect(result[membership2.id][:participation]).to eq(2000.0)
        expect(result[membership2.id][:settlement]).to eq(0)

        # user3: 0支払い - (1000 + 1000負担) = -2000支払う
        expect(result[membership3.id][:paid]).to eq(0)
        expect(result[membership3.id][:participation]).to eq(2000.0)
        expect(result[membership3.id][:settlement]).to eq(-2000.0)
      end
    end

    context '小数が出る場合（小数第1位で切り捨て）' do
      before do
        # 10000円を3人で割る = 3333.3... → 3333.3に切り捨て
        create(:expense, group: group, paid_by_membership_id: membership1.id, amount: 10000,
               expense_participants_list: [ membership1, membership2, membership3 ])
      end

      it '小数第1位で切り捨てされること' do
        calculator = described_class.new(group)
        result = calculator.calculate

        # 10000 / 3 = 3333.333... → 3333.3に切り捨て
        expected_participation = 3333.3

        expect(result[membership1.id][:participation]).to eq(expected_participation)
        expect(result[membership2.id][:participation]).to eq(expected_participation)
        expect(result[membership3.id][:participation]).to eq(expected_participation)

        # user1: 10000 - 3333.3 = 6666.7
        expect(result[membership1.id][:settlement]).to eq(10000 - expected_participation)
      end
    end

    context '2人での分割' do
      before do
        # 1000円を2人で割る = 500
        create(:expense, group: group, paid_by_membership_id: membership1.id, amount: 1000,
               expense_participants_list: [ membership1, membership2 ])
      end

      it '正確に2分の1が計算されること' do
        calculator = described_class.new(group)
        result = calculator.calculate

        expect(result[membership1.id][:paid]).to eq(1000)
        expect(result[membership1.id][:participation]).to eq(500.0)
        expect(result[membership1.id][:settlement]).to eq(500.0)

        expect(result[membership2.id][:paid]).to eq(0)
        expect(result[membership2.id][:participation]).to eq(500.0)
        expect(result[membership2.id][:settlement]).to eq(-500.0)
      end
    end

    context '同じメンバーが複数の支出に参加する場合' do
      before do
        # 支出1: user1が5000円支払い、user1とuser2が参加
        create(:expense, group: group, paid_by_membership_id: membership1.id, amount: 5000,
               expense_participants_list: [ membership1, membership2 ])

        # 支出2: user2が3000円支払い、user1とuser2が参加
        create(:expense, group: group, paid_by_membership_id: membership2.id, amount: 3000,
               expense_participants_list: [ membership1, membership2 ])
      end

      it '累積の支払いと負担が正確に計算されること' do
        calculator = described_class.new(group)
        result = calculator.calculate

        # user1: (5000 + 0)支払い - (2500 + 1500)負担 = 1000
        expect(result[membership1.id][:paid]).to eq(5000)
        expect(result[membership1.id][:participation]).to eq(4000.0)
        expect(result[membership1.id][:settlement]).to eq(1000.0)

        # user2: (0 + 3000)支払い - (2500 + 1500)負担 = -1000
        expect(result[membership2.id][:paid]).to eq(3000)
        expect(result[membership2.id][:participation]).to eq(4000.0)
        expect(result[membership2.id][:settlement]).to eq(-1000.0)
      end
    end

    context '参加していないメンバーが存在する場合' do
      before do
        # ensure membership3 is created (lazy evaluation)
        membership3.id

        # user1とuser2だけが参加する支出
        create(:expense, group: group, paid_by_membership_id: membership1.id, amount: 2000,
               expense_participants_list: [ membership1, membership2 ])
      end

      it '参加していないメンバーの負担が0になること' do
        calculator = described_class.new(group)
        result = calculator.calculate

        # user3は参加していない
        expect(result[membership3.id][:paid]).to eq(0)
        expect(result[membership3.id][:participation]).to eq(0)
        expect(result[membership3.id][:settlement]).to eq(0)
      end
    end
  end
end
