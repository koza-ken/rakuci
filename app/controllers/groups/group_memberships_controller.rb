class Groups::GroupMembershipsController < ApplicationController
  include GroupMemberAuthorization  # グループメンバーのみアクセス許可

  before_action :authenticate_user!, only: %i[ destroy ]
  before_action :set_group, only: %i[ destroy ]
  before_action :set_group_by_invite_token, only: %i[ new create ]
  before_action :ensure_group_present!, only: %i[ new create ]
  before_action :set_membership, only: %i[ destroy ]
  before_action :check_owner_permission, only: %i[ destroy ]
  before_action :check_group_member, only: %i[ destroy ]

  # グループ招待ページ
  def new
    if user_already_member_of_group?
      redirect_to group_path(@group.id)
      return
    end
    # ニックネームの一覧を取得
    @member_nicknames = available_guest_nicknames
  end

  # グループ参加ページからのデータ処理
  def create
    case membership_params[:membership_source]
    when "dropdown"
      handle_dropdown_membership
    when "text_input"
      handle_text_input_membership
    else
      redirect_to new_membership_path(@group.invite_token), alert: t("errors.groups.invalid_operation")
    end
  end

  def destroy
    @membership = @group.group_memberships.find(params[:id])

    # オーナーは削除できない
    if @membership.owner?
      redirect_to group_path(@group), alert: t("errors.memberships.cannot_delete_owner")
      return
    end

    @membership.destroy
    respond_to do |format|
      format.turbo_stream { flash.now[:notice] = t("notices.memberships.deleted") }
      format.html { redirect_to group_path(@group), notice: t("notices.memberships.deleted") }
    end
  end

  private

  def set_group
    @group = Group.find(params[:group_id])
  end

  def set_membership
    @membership = @group.group_memberships.find(params[:id])
  end

  # グループのオーナーのみがメンバーを削除できる
  def check_owner_permission
    unless current_user&.id == @group.created_by_user_id
      redirect_to group_path(@group), alert: t("errors.memberships.not_authorized")
    end
  end

  # 招待用トークンからグループを取得（new、createアクションのフィルター）
  def set_group_by_invite_token
    @group = Group.find_by(invite_token: params[:invite_token])
  end

  # @groupがなければroot_pathに（new、createアクションのフィルター）
  def ensure_group_present!
    return if @group.present?
    redirect_to root_path, notice: t("errors.groups.invalid_link")
  end

  # ログインしていて、かつ、そのユーザーがそのグループに参加しているか（newアクション）
  def user_already_member_of_group?
    user_signed_in? && @group.group_memberships.exists?(user_id: current_user.id)
  end

  # グループのニックネーム一覧を取得（newアクション）
  def available_guest_nicknames
    @group.group_memberships.where(user_id: nil).pluck(:group_nickname)
  end

  # ニックネーム一覧のドロップダウンからグループ参加の処理をまとめたメソッド（createアクション）
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

  # ニックネームの入力からのグループ参加の処理をまとめたメソッド（createアクション）
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

  # （createアクションのhandle_dropdown_membershipメソッド）
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

  # （createアクションのhandle_dropdown_membershipメソッド）
  def guest_token_matches?(membership)
    stored_token = stored_guest_token_for(@group.id)
    stored_token == membership.guest_token
  end

  # ストロングパラメータ
  def membership_params
    params.permit(:group_nickname, :membership_source, :invite_token)
  end
end
