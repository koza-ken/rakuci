module Groups
  class ItemsController < ApplicationController
    before_action :set_group
    before_action :check_group_member
    before_action :set_schedule
    before_action :set_item_list, only: %i[create update destroy]
    before_action :set_item, only: %i[update destroy]

    # POST /groups/:group_id/schedule/item_list/items
    def create
    end

    # PATCH/PUT /groups/:group_id/schedule/item_list/items/:id
    def update
    end

    # DELETE /groups/:group_id/schedule/item_list/items/:id
    def destroy
    end

    private

    def set_group
      @group = Group.find(params[:group_id])
    end

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

    def set_schedule
      @schedule = @group.schedule
    end

    def set_item_list
      @item_list = @schedule.item_list
    end

    def set_item
      @item = @item_list.items.find(params[:id])
    end

    def item_params
      params.require(:item).permit(:name, :checked)
    end
  end
end
