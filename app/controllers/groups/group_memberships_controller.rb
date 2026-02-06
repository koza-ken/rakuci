class Groups::GroupMembershipsController < ApplicationController
  include GroupMemberAuthorization  # グループメンバーのみアクセス許可

  before_action :authenticate_user!, only: %i[ destroy ]
  before_action :set_group_by_invite_token, only: %i[ new create ]
  before_action :ensure_group_present!, only: %i[ new create ]
  before_action :set_group, only: %i[ destroy ]
  before_action :set_membership, only: %i[ destroy ]
  before_action :check_owner_permission, only: %i[ destroy ]
  before_action :check_group_member, only: %i[ destroy ]  # /concerns/GroupMemberAuthorizationモジュール

  # グループ招待ページ
  def new
    if user_already_member_of_group?
      redirect_to group_path(@group.id)
      return
    end
    # ゲストが選択可能なニックネーム一覧を取得
    @available_guest_nicknames = available_guest_nicknames
  end

  # グループ参加ページからのデータ処理
  def create
    # 「過去参加あり」か「はじめて参加」でストラテジークラスを判定
    strategy_class = GroupMemberships::GroupJoinStrategy.for(membership_params[:membership_source])
    strategy = strategy_class.new(@group, membership_params, current_user)
    # 生成されたストラテジークラスで参加処理
    result = strategy.execute

    if result.success?
      # ゲスト参加の場合、セッションにトークンを保存して、グループページに遷移
      set_guest_token(result.group_id, result.guest_token) if result.has_guest_token?
      redirect_to group_path(@group.id), notice: t("notices.groups.joined")
    else
      redirect_to new_membership_path(@group.invite_token), alert: result.error_message
    end
  rescue ArgumentError => e
    redirect_to new_membership_path(@group.invite_token), alert: t("errors.groups.invalid_operation")
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

  # ------------フィルター---------------

  def set_group
    @group = Group.find(params[:group_id])
  end

  def set_group_by_invite_token
    @group = Group.find_by(invite_token: params[:invite_token])
  end

  # 招待用トークンが有効ならアクション実行
  def ensure_group_present!
    return if @group.present?
    redirect_to root_path, notice: t("errors.groups.invalid_link")
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

  # ------------------------------------

  # ログインしていて、かつ、そのユーザーがそのグループに参加しているか（newアクション）
  def user_already_member_of_group?
    user_signed_in? && current_user.member_of?(@group)
  end

  # グループのゲスト（user_id: nil）のニックネーム一覧を取得（newアクション）
  def available_guest_nicknames
    @group.group_memberships.where(user_id: nil).pluck(:group_nickname)
  end

  # ストロングパラメータ
  def membership_params
    params.permit(:group_nickname, :membership_source, :invite_token)
  end
end
