require 'rails_helper'

RSpec.describe 'Groups::Expenses', type: :request do
  let(:user) { create(:user) }
  let(:group) do
    group = create(:group, created_by_user_id: user.id)
    create(:group_membership, group: group, user: user)
    # breadcrumbs で schedule が必要
    create(:schedule, schedulable: group)
    group
  end
  let(:other_user) { create(:user) }
  let(:other_membership) do
    create(:group_membership, group: group, user: other_user)
  end
  let(:membership) { group.group_memberships.find_by(user_id: user.id) }

  before { sign_in user }

  describe 'GET /groups/:group_id/expenses' do
    let!(:expense1) do
      create(:expense, group: group, paid_by_membership_id: membership.id,
             paid_at: Date.new(2024, 1, 2), expense_participants_list: [ membership ])
    end
    let!(:expense2) do
      # デフォルトで other_membership を participant として作成
      create(:expense, group: group, paid_by_membership_id: other_membership.id,
             paid_at: Date.new(2024, 1, 1), expense_participants_list: [ other_membership ])
    end

    before do
      # expense2 に membership を追加参加者として追加（other_membership は既に参加）
      expense2.expense_participants.create!(group_membership: membership)
    end

    context 'グループメンバーの場合' do
      it 'ステータス200が返ること' do
        get group_expenses_path(group)
        expect(response).to have_http_status(:ok)
      end

      it 'expenses ページが表示されること' do
        get group_expenses_path(group)
        expect(response.body).to include('旅費の精算')
      end

      it '支出一覧が表示されること' do
        get group_expenses_path(group)
        expect(response.body).to include(expense1.name)
        expect(response.body).to include(expense2.name)
      end

      it '精算額が表示されること' do
        get group_expenses_path(group)
        expect(response.body).to include('精算額')
      end
    end

    context 'グループメンバーではない場合' do
      let(:other_group) do
        group = create(:group, created_by_user_id: other_user.id)
        create(:group_membership, group: group, user: other_user)
        create(:schedule, schedulable: group)
        group
      end

      it 'グループ一覧ページにリダイレクトされること' do
        get group_expenses_path(other_group)
        expect(response).to redirect_to(groups_path)
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'ログインページにリダイレクトされること' do
        get group_expenses_path(group)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'POST /groups/:group_id/expenses' do
    let(:valid_params) do
      {
        expense: {
          paid_by_membership_id: membership.id,
          participant_ids: [ membership.id.to_s, other_membership.id.to_s ],
          name: 'テスト支出',
          amount: 5000,
          paid_at: Date.current
        }
      }
    end

    let(:invalid_params) do
      {
        expense: {
          paid_by_membership_id: membership.id,
          participant_ids: [],
          name: 'テスト支出',
          amount: 5000,
          paid_at: Date.current
        }
      }
    end

    context 'グループメンバーが有効なパラメータで支出を作成する場合' do
      it '支出が1件作成されること' do
        expect {
          post group_expenses_path(group), params: valid_params
        }.to change(Expense, :count).by(1)
      end

      it '支出詳細ページにリダイレクトされること' do
        post group_expenses_path(group), params: valid_params
        expect(response).to redirect_to(group_expenses_path(group))
      end

      it '成功メッセージが表示されること' do
        post group_expenses_path(group), params: valid_params
        follow_redirect!
        expect(response.body).to include('支払いを追加しました')
      end

      it '参加者が正確に保存されること' do
        post group_expenses_path(group), params: valid_params
        expense = Expense.last
        expect(expense.participants.pluck(:id)).to contain_exactly(membership.id, other_membership.id)
      end
    end

    context 'バリデーションエラーがある場合' do
      it '支出が作成されないこと' do
        expect {
          post group_expenses_path(group), params: invalid_params
        }.not_to change(Expense, :count)
      end

      it 'expensesページが再表示されること' do
        post group_expenses_path(group), params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'エラーメッセージが表示されること' do
        post group_expenses_path(group), params: invalid_params
        expect(response.body).to include('対象者を選択してください')
      end
    end

    context 'グループメンバーではない場合' do
      let(:other_group) do
        group = create(:group, created_by_user_id: other_user.id)
        create(:schedule, schedulable: group)
        create(:group_membership, group: group, user: other_user)
        group
      end

      it 'グループ一覧ページにリダイレクトされること' do
        post group_expenses_path(other_group), params: valid_params
        expect(response).to redirect_to(groups_path)
      end

      it '支出が作成されないこと' do
        expect {
          post group_expenses_path(other_group), params: valid_params
        }.not_to change(Expense, :count)
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'ログインページにリダイレクトされること' do
        post group_expenses_path(group), params: valid_params
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'GET /groups/:group_id/expenses/:id/edit' do
    let(:expense) do
      create(:expense, group: group, paid_by_membership_id: membership.id,
             expense_participants_list: [ membership ])
    end

    before do
      # expense が作成されることを確認
      expense
      # other_membership を明示的に作成
      other_membership
    end

    context '支出の作成者がアクセスする場合' do
      it 'ステータス200が返ること' do
        get edit_group_expense_path(group, expense)
        expect(response).to have_http_status(:ok)
      end

      it '編集ページが表示されること' do
        get edit_group_expense_path(group, expense)
        expect(response.body).to include('支払いを編集する')
      end

      it '支出の内容が表示されること' do
        get edit_group_expense_path(group, expense)
        expect(response.body).to include(expense.name)
        expect(response.body).to include(expense.amount.to_s)
      end
    end

    context '支出の作成者ではないメンバーがアクセスする場合' do
      it 'expensesページにリダイレクトされること' do
        get edit_group_expense_path(group, expense)
        sign_in other_user
        get edit_group_expense_path(group, expense)
        expect(response).to redirect_to(group_expenses_path(group))
      end

      it 'エラーメッセージが表示されること' do
        sign_out user
        sign_in other_user
        get edit_group_expense_path(group, expense)
        follow_redirect!
        expect(response.body).to include('この支払いを編集する権限がありません')
      end
    end

    context 'グループメンバーではない場合' do
      let(:other_group) do
        group = create(:group, created_by_user_id: other_user.id)
        create(:schedule, schedulable: group)
        create(:group_membership, group: group, user: other_user)
        group
      end

      it 'グループ一覧ページにリダイレクトされること' do
        # user は other_group のメンバーではないため、check_group_member で groups_path にリダイレクトされる
        other_membership = other_group.group_memberships.first
        other_expense = create(:expense, group: other_group, paid_by_membership_id: other_membership.id,
                               expense_participants_list: [ other_membership ])
        get edit_group_expense_path(other_group, other_expense)
        expect(response).to redirect_to(groups_path)
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'ログインページにリダイレクトされること' do
        get edit_group_expense_path(group, expense)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'PATCH /groups/:group_id/expenses/:id' do
    let(:expense) do
      create(:expense, group: group, paid_by_membership_id: membership.id,
             expense_participants_list: [ membership ])
    end
    let(:valid_params) do
      {
        expense: {
          paid_by_membership_id: membership.id,
          participant_ids: [ membership.id.to_s, other_membership.id.to_s ],
          name: '更新されたタイトル',
          amount: 8000,
          paid_at: Date.current
        }
      }
    end
    let(:invalid_params) do
      {
        expense: {
          paid_by_membership_id: membership.id,
          participant_ids: [],
          name: '更新されたタイトル',
          amount: 8000,
          paid_at: Date.current
        }
      }
    end

    before do
      # expense が作成されることを確認
      expense
      # other_membership を明示的に作成
      other_membership
    end



    context '支出の作成者が有効なパラメータで更新する場合' do
      it '支出が更新されること' do
        patch group_expense_path(group, expense), params: valid_params
        expense.reload
        expect(expense.name).to eq('更新されたタイトル')
        expect(expense.amount).to eq(8000)
      end

      it '参加者が更新されること' do
        patch group_expense_path(group, expense), params: valid_params
        expense.reload
        expect(expense.participants.pluck(:id)).to contain_exactly(membership.id, other_membership.id)
      end

      it 'expensesページにリダイレクトされること' do
        patch group_expense_path(group, expense), params: valid_params
        expect(response).to redirect_to(group_expenses_path(group))
      end

      it '成功メッセージが表示されること' do
        patch group_expense_path(group, expense), params: valid_params
        follow_redirect!
        expect(response.body).to include('支払いを更新しました')
      end
    end

    context 'バリデーションエラーがある場合' do
      it '支出が更新されないこと' do
        original_name = expense.name
        patch group_expense_path(group, expense), params: invalid_params
        expense.reload
        expect(expense.name).to eq(original_name)
      end

      it '編集ページが再表示されること' do
        patch group_expense_path(group, expense), params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context '支出の作成者ではないメンバーが更新しようとする場合' do
      it '支出が更新されないこと' do
        original_name = expense.name
        sign_out user
        sign_in other_user
        patch group_expense_path(group, expense), params: valid_params
        expense.reload
        expect(expense.name).to eq(original_name)
      end

      it 'expensesページにリダイレクトされること' do
        sign_out user
        sign_in other_user
        patch group_expense_path(group, expense), params: valid_params
        expect(response).to redirect_to(group_expenses_path(group))
      end
    end

    context 'グループメンバーではない場合' do
      let(:other_group) do
        group = create(:group, created_by_user_id: other_user.id)
        create(:schedule, schedulable: group)
        create(:group_membership, group: group, user: other_user)
        group
      end

      it 'グループ一覧ページにリダイレクトされること' do
        # user は other_group のメンバーではないため、check_group_member で groups_path にリダイレクトされる
        other_membership = other_group.group_memberships.first
        other_expense = create(:expense, group: other_group, paid_by_membership_id: other_membership.id,
                               expense_participants_list: [ other_membership ])
        patch group_expense_path(other_group, other_expense), params: valid_params
        expect(response).to redirect_to(groups_path)
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'ログインページにリダイレクトされること' do
        patch group_expense_path(group, expense), params: valid_params
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'DELETE /groups/:group_id/expenses/:id' do
    let!(:expense) do
      create(:expense, group: group, paid_by_membership_id: membership.id,
             expense_participants_list: [ membership ])
    end

    before do
      # expense が作成されることを確認
      expense
      # other_membership を明示的に作成
      other_membership
    end

    context '支出の作成者が削除する場合' do
      it '支出が削除されること' do
        expect {
          delete group_expense_path(group, expense)
        }.to change(Expense, :count).by(-1)
      end

      it 'expensesページにリダイレクトされること' do
        delete group_expense_path(group, expense)
        expect(response).to redirect_to(group_expenses_path(group))
      end

      it '成功メッセージが表示されること' do
        delete group_expense_path(group, expense)
        follow_redirect!
        expect(response.body).to include('支払いを削除しました')
      end

      it 'expense_participants も一緒に削除されること' do
        expense_id = expense.id
        delete group_expense_path(group, expense)
        expect(ExpenseParticipant.where(expense_id: expense_id)).to be_empty
      end
    end

    context '支出の作成者ではないメンバーが削除しようとする場合' do
      it '支出が削除されないこと' do
        sign_out user
        sign_in other_user
        expect {
          delete group_expense_path(group, expense)
        }.not_to change(Expense, :count)
      end

      it 'expensesページにリダイレクトされること' do
        sign_out user
        sign_in other_user
        delete group_expense_path(group, expense)
        expect(response).to redirect_to(group_expenses_path(group))
      end
    end

    context 'グループメンバーではない場合' do
      let(:other_group) do
        group = create(:group, created_by_user_id: other_user.id)
        create(:schedule, schedulable: group)
        create(:group_membership, group: group, user: other_user)
        group
      end

      it 'グループ一覧ページにリダイレクトされること' do
        # user は other_group のメンバーではないため、check_group_member で groups_path にリダイレクトされる
        other_membership = other_group.group_memberships.first
        other_expense = create(:expense, group: other_group, paid_by_membership_id: other_membership.id,
                               expense_participants_list: [ other_membership ])
        delete group_expense_path(other_group, other_expense)
        expect(response).to redirect_to(groups_path)
      end
    end

    context '未ログイン時' do
      before { sign_out user }

      it 'ログインページにリダイレクトされること' do
        delete group_expense_path(group, expense)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
