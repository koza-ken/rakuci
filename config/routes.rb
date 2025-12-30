Rails.application.routes.draw do
  devise_for :users, controllers: {
    # deviseのコントローラをカスタム
    omniauth_callbacks: "users/omniauth_callbacks",
    registrations: "users/registrations"
  }

  # プロフィールページへのエイリアス（devise_scopeでDeviseの初期化処理を通す）
  devise_scope :user do
    get "/profile", to: "users/registrations#edit", as: :profile
  end

  root "static_pages#home"
  get "/privacy", to: "static_pages#privacy", as: :privacy
  get "/terms", to: "static_pages#terms", as: :terms

  # Routing Concerns（共通パターン）

  # acts_as_listによる並び替え機能
  concern :movable do
    member do
      patch :move_higher
      patch :move_lower
    end
  end

  # 持ち物リスト機能
  concern :with_item_list do
    resource :item_list, only: :show do
      resources :items, only: %i[create update destroy]
    end
  end

  # ========================================
  # 個人用リソース（Users名前空間）
  # ========================================

  scope module: "users" do
    # カード
    resources :cards, only: %i[index show new create update destroy] do
      # 個人用しおり（チェックボックス）のスポット追加（spot_idがいらない）
      get "schedule_spots/new", to: "schedule_spots#new", as: :new_schedule_spots
      post "schedule_spots", to: "schedule_spots#create", as: :spots_schedule_spots

      # カードのスポット
      resources :spots, only: %i[show new create edit update destroy], shallow: true do
        # 個人用しおりの個別スポット追加
        resources :schedule_spots, only: %i[new create]
      end
    end

    # ユーザーの持ち物リスト（全体管理・表示のみ）
    resource :item_list, only: :show do
      resources :items, only: %i[create update destroy]
    end

    # しおり
    resources :schedules, only: %i[index show new create edit update destroy] do
      # new/createのみ親IDが必要のためネスト（他のアクションは外に定義）
      resources :schedule_spots, only: %i[new create]

      # 個人しおり個別の持ち物リスト
      concerns :with_item_list
    end

    # しおりのスポット（shallow化: /user/schedule_spots/:id）
    resources :schedule_spots, only: %i[show edit update destroy],
                                path: "user/schedule_spots",
                                as: :user_schedule_spot,
                                concerns: :movable
  end

  # ========================================
  # グループ用リソース
  # ========================================

  resources :groups, only: %i[index show new create update destroy] do
    # 各ルーティングでコントローラの指定が不要になる
    scope module: "groups" do
      # カード
      resources :cards, only: %i[show new create update destroy] do
        # グループ用しおり（チェックボックス）のスポット追加
        post "schedule_spots", to: "schedule_spots#create", as: :schedule_spots

        resources :spots, only: %i[show new create edit update destroy] do
          # グループ用しおりの個別スポット追加
          post "/schedule_spots", to: "schedule_spots#create", as: :schedule_spot
        end

        resources :comments, only: %i[create destroy]
        resource :likes, only: %i[create destroy]
      end

      # グループしおり
      resource :schedule, only: %i[show new create edit update] do
        # new/createのみ親IDが必要なためネスト（他のアクションは外に定義）
        resources :schedule_spots, only: %i[new create]

        # グループしおりの持ち物リスト
        concerns :with_item_list
      end

      # グループメンバーシップ
      resources :group_memberships, only: :destroy
    end
  end

  # グループしおりのスポット（shallow化: /group/schedule_spots/:id）
  # shallow化する

  resources :schedule_spots, only: %i[show edit update destroy],
                              path: "group/schedule_spots",
                              controller: "groups/schedule_spots",
                              as: :group_schedule_spot,
                              concerns: :movable

  # 招待リンクからの参加
  # asオプションで、/groups/join/:invite_tokenのURLを生成するヘルパーを定義
  get "/groups/join/:invite_token", to: "groups#new_membership", as: :new_membership
  post "/groups/join/:invite_token", to: "groups#create_membership", as: :create_membership
end
