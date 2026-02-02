class GroupsController < ApplicationController
  # except
  before_action :authenticate_user!, except: %i[ show ]
  # only
  before_action :set_group, only: %i[ show update destroy ]
  before_action :check_group_member, only: %i[ show update ]

  def index
    set_joined_groups
  end

  def show
    @schedule = @group.schedule
    @cards_with_spots_by_category = @group.cards_with_spots_grouped
  end

  def new
    @form = GroupCreateForm.new
  end

  def create
    @form = GroupCreateForm.new(user: current_user, **group_form_params)

    if @form.save
      set_joined_groups
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = t("notices.groups.created") }
        format.html { redirect_to groups_path, notice: t("notices.groups.created") }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @group.update(group_params)
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = t("notices.groups.updated") }
        format.html { redirect_to group_path(@group), notice: t("notices.groups.updated") }
      end
    else
      respond_to do |format|
        format.turbo_stream { render :update, status: :unprocessable_entity }
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @group.destroy
    redirect_to groups_path, notice: t("notices.groups.destroyed")
  end

  private

  def set_group
    @group = Group.includes(:group_memberships, cards: :spots).find(params[:id])
  end

  # 現在のユーザーが参加しているグループ一覧を取得
  def set_joined_groups
    @groups = current_user.groups.with_memberships_and_schedule.recently_updated
    @groups_joined = @groups.any?
  end

  # グループに参加しているか確認するフィルター（showアクションのフィルター）
  def check_group_member
    unless group_member_authorized?
      redirect_to (user_signed_in? ? groups_path : root_path), alert: t("errors.groups.not_member")
    end
  end

  def group_member_authorized?
    user_signed_in? ? current_user.member_of?(@group) : GroupMembership.guest_member_by_token?(stored_guest_token_for(@group.id), @group)
  end

  # ストロングパラメータ

  # フォームオブジェクトの属性のみ（userはアクションで渡す）
  def group_form_params
    params.require(:group_create_form).permit(:name, :group_nickname)
  end

  # グループ名の更新で参照
  def group_params
    params.require(:group).permit(:name)
  end
end
