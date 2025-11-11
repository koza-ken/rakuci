class GroupsController < ApplicationController
  before_action :authenticate_user!, except: [ :show, :new_membership, :create_membership ]
  before_action :set_group, only: [ :show ]
  before_action :check_group_member, only: [ :show ]
  before_action :set_group_by_invite_token, only: [ :new_membership, :create_membership ]
  # set_group_by_invite_tokenで招待トークンをもとに@groupがあるかないか
  before_action :ensure_group_present!, only: [ :new_membership, :create_membership ]

  def index
    @groups = current_user.groups.includes(:group_memberships)
  end

  def show
    @schedule = @group.schedule
  end

  def new
    @form = GroupCreateForm.new
  end

  def create
    # フォームのデータにcurrent_userを追加することで、フォームオブジェクトで扱える（@form.userで参照できる）
    @form = GroupCreateForm.new(group_form_params.merge(user: current_user))
    # モデルにコールバックを設定してトークン生成
    if @form.save
      @group = @form.group  # フォームオブジェクトから作成されたグループを取得
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to groups_path, notice: t("notices.groups.created") }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  # グループ招待ページ
  def new_membership
    if user_already_member_of_group?
      redirect_to group_path(@group.id)
      return
    end
    # ニックネームの一覧を取得
    @member_nicknames = available_guest_nicknames
  end

  # グループ参加ページからのデータ処理
  def create_membership
    case membership_params[:membership_source]
    when "dropdown"
      handle_dropdown_membership
    when "text_input"
      handle_text_input_membership
    else
      redirect_to new_membership_path(@group.invite_token), alert: t("errors.groups.invalid_operation")
    end
  end

  private

  # ストロングパラメータ
  def group_form_params
    params.require(:group_create_form).permit(:name, :group_nickname)
  end

  def membership_params
    params.permit(:group_nickname, :membership_source, :invite_token)
  end

  # グループに参加しているか確認するフィルター（showアクションのフィルター）
  def check_group_member
    authorized = if user_signed_in?
      current_user.member_of?(@group)
    else
      GroupMembership.guest_member?(guest_token_for(@group.id), @group.id)
    end

    unless authorized
      redirect_to (user_signed_in? ? groups_path : root_path), alert: t("errors.groups.not_member")
    end
  end

  def set_group
    @group = Group.includes(:group_memberships, :cards).find(params[:id])
  end

  # 招待用トークンからグループを取得（new_membership、create_membershipアクションのフィルター）
  def set_group_by_invite_token
    @group = Group.find_by(invite_token: params[:invite_token])
  end

  # @groupがなければroot_pathに（new_membership、create_membershipアクションのフィルター）
  def ensure_group_present!
    return if @group.present?
    redirect_to root_path, notice: t("errors.groups.invalid_link")
  end

  # ログインしていて、かつ、そのユーザーがそのグループに参加しているか（new_membershipアクション）
  def user_already_member_of_group?
    user_signed_in? && @group.group_memberships.exists?(user_id: current_user.id)
  end

  # グループのニックネーム一覧を取得（new_membershipアクション）
  def available_guest_nicknames
    @group.group_memberships.where(user_id: nil).pluck(:group_nickname)
  end

  # ニックネーム一覧のドロップダウンからグループ参加の処理をまとめたメソッド（create_membershipアクション）
  def handle_dropdown_membership
    membership = @group.group_memberships.find_by(group_nickname: membership_params[:group_nickname])
    # 選択したニックネームからメンバーシップをさがす
    unless membership
      redirect_to new_membership_path(@group.invite_token), alert: t("errors.groups.user_not_found")
      return
    end

    # 見つかったメンバーシップに、user_idかトークンを紐づける
    unless attach_user_or_guest_token(membership)
      redirect_to new_membership_path(@group.invite_token), alert: t("errors.groups.membership_failed")
      return
    end

    # ゲスト参加で、トークンが一致しない場合
    if membership.user_id.nil? && !guest_token_matches?(membership)
      redirect_to new_membership_path(@group.invite_token), alert: t("errors.groups.token_mismatch")
      return
    end

    # 問題なければグループに参加する
    redirect_to group_path(@group.id), notice: t("notices.groups.joined")
  end

  # ニックネームの入力からのグループ参加の処理をまとめたメソッド（create_membershipアクション）
  def handle_text_input_membership
    membership = @group.group_memberships.build(group_nickname: membership_params[:group_nickname], role: "member")
    if user_signed_in?
      membership.user = current_user
    else
      membership.guest_token = membership.generate_guest_token
    end

    if membership.save
      set_guest_token(@group.id, membership.guest_token) if membership.guest_token.present?
      redirect_to group_path(@group.id), notice: t("notices.groups.joined")
    else
      redirect_to new_membership_path(@group.invite_token), alert: t("errors.groups.membership_failed")
    end
  end

  # （create_membershipアクションのhandle_dropdown_membershipメソッド）
  def attach_user_or_guest_token(membership)
    if user_signed_in?
      membership.update(user_id: current_user.id)
    else
      ensure_guest_token!(membership)
    end
  end

  # メンバーシップにゲスト用トークンがついているか確認し、なければ発行して保存するメソッド
  def ensure_guest_token!(membership)
    # トークンがあればtrueを返して処理おわり
    return true if membership.guest_token.present?
    if membership.update(guest_token: membership.generate_guest_token)
      set_guest_token(@group.id, membership.guest_token)
      true
    else
      false
    end
  end

  # （create_membershipアクションのhandle_dropdown_membershipメソッド）
  def guest_token_matches?(membership)
    stored_token = guest_token_for(@group.id)
    stored_token == membership.guest_token
  end
end
