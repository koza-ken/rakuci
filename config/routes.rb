Rails.application.routes.draw do
  devise_for :users
  root "static_pages#home"

  resources :cards, only: %i[index show new create] do
    resources :spots, only: %i[show new create edit update destroy] do
      # 個人用しおりのスポット追加
      resources :schedule_spots, only: %i[new create], controller: 'users/schedule_spots', path: 'user_schedule_spot_path'
      # グループ用しおりのスポット追加（作成ページなし）
      post "/group_schedule_spots", to: "groups/schedule_spots#create", as: :group_schedule_spot
    end
    resources :comments, only: %i[create destroy]
    resource :likes, only: %i[create destroy]
  end

  # group_idをURLに渡すためにネスト
  resources :groups, only: %i[index show new create] do
    resource :schedule, only: %i[show]
  end

  # URLは"/schedules"
  scope module: "users" do
    resources :schedules, only: %i[index show] do
      # showはscheduleの詳細からアクセスする（追加のnew,createは/card/spotsから）
      resources :schedule_spots, only: %i[show]
    end
  end

  # URLは"/schedules"
  scope module: "groups" do
    resources :schedules, only: %i[show] do
      # showはscheduleの詳細からアクセスする（追加のnew,createは/card/spotsから）
      resources :schedule_spots, only: %i[show],  as: 'group_schedule_spot', path: '/group_schedule_spots'
    end
  end

  # 招待リンクからの参加
  # asオプションで、/groups/join/:invite_tokenのURLを生成するヘルパーを定義
  get "/groups/join/:invite_token", to: "groups#new_membership", as: :new_membership
  post "/groups/join/:invite_token", to: "groups#create_membership", as: :create_membership
end
