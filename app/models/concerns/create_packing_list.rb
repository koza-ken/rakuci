# 作成時にPackingListを生成する共通コールバック
module CreatePackingList
  extend ActiveSupport::Concern

  included do
    after_create :create_packing_list
  end

  private

  def create_packing_list
    PackingList.create(listable: self)
  end
end
