Rails.application.routes.draw do
  devise_for :users
  root "static_pages#home"

  resources :cards, only: %i[index show new create] do
    resources :spots, only: %i[show new create edit update destroy]
    resources :comments, only: %i[create destroy]
    resource :likes, only: %i[create destroy]
  end

  # group_idをURLに渡すためにネスト
  resources :groups, only: %i[index show new create] do
    resource :schedule, only: %i[show]
  end

  # URLは"/schedules"
  scope module: "users" do
    resources :schedules, only: %i[index show]
  end

  # 招待リンクからの参加
  # asオプションで、/groups/join/:invite_tokenのURLを生成するヘルパーを定義
  get "/groups/join/:invite_token", to: "groups#new_membership", as: :new_membership
  post "/groups/join/:invite_token", to: "groups#create_membership", as: :create_membership
end
