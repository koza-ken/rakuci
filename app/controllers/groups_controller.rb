class GroupsController < ApplicationController
  include GroupMemberAuthorization  # グループメンバーのみアクセス許可

  # except
  before_action :authenticate_user!, except: %i[ show ]
  # only
  before_action :set_group, only: %i[ update destroy ]
  before_action :set_group_for_show, only: %i[ show ]
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
    @group = Group.find(params[:id])
  end

  def set_group_for_show
    @group = Group.includes(:group_memberships, cards: :spots).find(params[:id])
  end

  # 現在のユーザーが参加しているグループ一覧を取得
  def set_joined_groups
    @groups = current_user.groups.with_memberships_and_schedule.recently_updated
    @groups_joined = @groups.any?
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
