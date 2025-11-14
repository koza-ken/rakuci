Rails.application.routes.draw do
  devise_for :users
  root "static_pages#home"

  resources :cards, only: %i[index show new create update destroy] do
    # 個人用しおり（チェックボックス）のスポット追加（spot_idがいらない）の新規作成new
    get "schedule_spots/new", to: "users/schedule_spots#new", as: :new_schedule_spots
    # 個人用しおり（チェックボックス）のスポット追加（spot_idがいらない）
    post "schedule_spots", to: "users/schedule_spots#create", as: :spots_schedule_spots
    # グループ用しおり（チェックボックス）のスポット追加（spot_idがいらない）
    post "group_schedule_spots", to: "groups/schedule_spots#create", as: :spots_group_schedule_spots

    resources :spots, only: %i[show new create edit update destroy] do
      # 個人用しおりの個別スポット追加
      resources :schedule_spots, only: %i[new create], controller: "users/schedule_spots", path: "user_schedule_spot_path"
      # グループ用しおりの個別スポット追加（作成ページなし）
      post "/group_schedule_spots", to: "groups/schedule_spots#create", as: :group_schedule_spot
    end
    resources :comments, only: %i[create destroy]
    resource :likes, only: %i[create destroy]
  end

  # group_idをURLに渡すためにネスト
  resources :groups, only: %i[index show new create update destroy] do
    resource :schedule, only: %i[show new create edit update], controller: "groups/schedules" do
      resources :schedule_spots, only: %i[show edit update destroy], controller: "groups/schedule_spots"
    end
    resources :group_memberships, only: %i[destroy], controller: "groups/memberships"
  end

  # URLは"/schedules"（個人用）
  scope module: "users" do
    resources :schedules, only: %i[index show new create edit update destroy] do
      # showはscheduleの詳細からアクセスする（追加のnew,createは/card/spotsから）
      resources :schedule_spots, only: %i[show edit update destroy]
    end
  end

  # 招待リンクからの参加
  # asオプションで、/groups/join/:invite_tokenのURLを生成するヘルパーを定義
  get "/groups/join/:invite_token", to: "groups#new_membership", as: :new_membership
  post "/groups/join/:invite_token", to: "groups#create_membership", as: :create_membership
end
