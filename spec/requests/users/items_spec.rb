require 'rails_helper'

RSpec.describe "Users::Items", type: :request do
  let(:user) { create(:user) }
  let(:item_list) { user.item_list }

  before do
    sign_in user
  end

  describe "POST /item_list/items" do
    context "ログインしている場合" do
      context "有効なパラメーターの場合" do
        it "アイテムが作成されること" do
          expect {
            post item_list_items_path, params: {
              item: { name: "新しいアイテム" }
            }
          }.to change(Item, :count).by(1)
        end

        it "Turbo Streamレスポンスを返すこと" do
          post item_list_items_path, params: {
            item: { name: "新しいアイテム" }
          }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
          expect(response).to have_http_status(:success)
          expect(response.content_type).to include("text/vnd.turbo-stream.html")
        end

        it "作成されたアイテムが正しい属性を持つこと" do
          post item_list_items_path, params: {
            item: { name: "新しいアイテム" }
          }
          item = Item.last
          expect(item.name).to eq("新しいアイテム")
          expect(item.checked).to be false
          expect(item.item_list).to eq(item_list)
        end

        it "アイテムにpositionが自動割り当てされること" do
          post item_list_items_path, params: {
            item: { name: "最初のアイテム" }
          }
          post item_list_items_path, params: {
            item: { name: "2番目のアイテム" }
          }
          expect(Item.where(item_list: item_list).order(:id).first.position).to eq(1)
          expect(Item.where(item_list: item_list).order(:id).last.position).to eq(2)
        end
      end

      context "無効なパラメーターの場合" do
        it "nameが空だとアイテムが作成されないこと" do
          expect {
            post item_list_items_path, params: {
              item: { name: "" }
            }
          }.not_to change(Item, :count)
        end

        it "nameが100文字を超えるとアイテムが作成されないこと" do
          expect {
            post item_list_items_path, params: {
              item: { name: "a" * 101 }
            }
          }.not_to change(Item, :count)
        end
      end
    end

    context "ログインしていない場合" do
      before do
        sign_out user
      end

      it "ログインページにリダイレクトされること" do
        post item_list_items_path, params: {
          item: { name: "新しいアイテム" }
        }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "PATCH /item_list/items/:id" do
    let(:item) { create(:item, item_list: item_list, name: "元のアイテム") }

    context "ログインしている場合" do
      context "nameを更新する場合" do
        it "アイテムのnameが更新されること" do
          patch item_list_item_path(item), params: {
            item: { name: "更新されたアイテム" }
          }
          item.reload
          expect(item.name).to eq("更新されたアイテム")
        end

        it "Turbo Streamレスポンスを返すこと" do
          patch item_list_item_path(item), params: {
            item: { name: "更新されたアイテム" }
          }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
          expect(response).to have_http_status(:success)
          expect(response.content_type).to include("text/vnd.turbo-stream.html")
        end
      end

      context "checked を更新する場合" do
        it "アイテムのcheckedが更新されること" do
          patch item_list_item_path(item), params: {
            item: { checked: true }
          }, headers: { "Accept" => "application/json" }
          item.reload
          expect(item.checked).to be true
        end

        it "JSON レスポンスで :ok を返すこと" do
          patch item_list_item_path(item), params: {
            item: { checked: true }
          }, headers: { "Accept" => "application/json" }
          expect(response).to have_http_status(:ok)
        end
      end

      context "position を更新する場合" do
        let(:item1) { create(:item, item_list: item_list, name: "アイテム1") }
        let(:item2) { create(:item, item_list: item_list, name: "アイテム2") }
        let(:item3) { create(:item, item_list: item_list, name: "アイテム3") }

        it "アイテムの position が更新されること" do
          patch item_list_item_path(item2), params: {
            item: { position: 3 }
          }, headers: { "Accept" => "application/json" }
          item2.reload
          expect(item2.position).to eq(3)
        end

        it "他のアイテムの position が自動調整されること" do
          patch item_list_item_path(item1), params: {
            item: { position: 2 }
          }, headers: { "Accept" => "application/json" }
          item1.reload
          item2.reload
          item3.reload
          expect(item1.position).to eq(2)
          expect(item2.position).to eq(3)
          expect(item3.position).to eq(4)
        end

        it "JSON レスポンスで :ok を返すこと" do
          patch item_list_item_path(item2), params: {
            item: { position: 1 }
          }, headers: { "Accept" => "application/json" }
          expect(response).to have_http_status(:ok)
        end
      end

      context "無効なパラメーターの場合" do
        it "name を空にするとエラーが返されること" do
          patch item_list_item_path(item), params: {
            item: { name: "" }
          }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
          item.reload
          expect(item.name).to eq("元のアイテム")
        end
      end
    end

    context "ログインしていない場合" do
      before do
        sign_out user
      end

      it "ログインページにリダイレクトされること" do
        patch item_list_item_path(item), params: {
          item: { name: "更新されたアイテム" }
        }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "DELETE /item_list/items/:id" do
    let(:item) { create(:item, item_list: item_list, name: "削除対象アイテム") }

    context "ログインしている場合" do
      it "アイテムが削除されること" do
        item_id = item.id
        expect {
          delete item_list_item_path(item)
        }.to change(Item, :count).by(-1)
        expect(Item.find_by(id: item_id)).to be_nil
      end

      it "Turbo Stream レスポンスを返すこと" do
        delete item_list_item_path(item), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end

      it "削除後に他のアイテムの position が自動調整されること" do
        item1 = create(:item, item_list: item_list, name: "アイテム1", position: 1)
        item2 = create(:item, item_list: item_list, name: "アイテム2", position: 2)
        item3 = create(:item, item_list: item_list, name: "アイテム3", position: 3)

        delete item_list_item_path(item2)

        item1.reload
        item3.reload
        expect(item1.position).to eq(1)
        expect(item3.position).to eq(2)
      end
    end

    context "ログインしていない場合" do
      before do
        sign_out user
      end

      it "ログインページにリダイレクトされること" do
        delete item_list_item_path(item)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "他のユーザーのアイテムへのアクセス" do
    let(:other_user) { create(:user) }
    let(:other_item) { create(:item, item_list: other_user.item_list, name: "他のユーザーのアイテム") }

    context "他のユーザーのアイテムを更新しようとする場合" do
      it "404 エラーが返されること" do
        patch item_list_item_path(other_item), params: {
          item: { name: "更新しようとしたアイテム" }
        }
        expect(response).to have_http_status(:not_found)
      end
    end

    context "他のユーザーのアイテムを削除しようとする場合" do
      it "404 エラーが返されること" do
        delete item_list_item_path(other_item)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
