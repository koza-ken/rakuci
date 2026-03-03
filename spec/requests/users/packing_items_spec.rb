require 'rails_helper'

RSpec.describe "Users::PackingItems", type: :request do
  let(:user) { create(:user) }
  let(:packing_list) { user.packing_list }

  before do
    sign_in user
  end

  describe "POST /packing_list/packing_items" do
    context "ログインしている場合" do
      context "有効なパラメーターの場合" do
        it "アイテムが作成されること" do
          expect {
            post packing_list_items_path, params: {
              packing_item: { name: "新しいアイテム" }
            }
          }.to change(PackingItem, :count).by(1)
        end

        it "Turbo Streamレスポンスを返すこと" do
          post packing_list_items_path, params: {
            packing_item: { name: "新しいアイテム" }
          }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
          expect(response).to have_http_status(:success)
          expect(response.content_type).to include("text/vnd.turbo-stream.html")
        end

        it "作成されたアイテムが正しい属性を持つこと" do
          post packing_list_items_path, params: {
            packing_item: { name: "新しいアイテム" }
          }
          packing_item = PackingItem.last
          expect(packing_item.name).to eq("新しいアイテム")
          expect(packing_item.checked).to be false
          expect(packing_item.packing_list).to eq(packing_list)
        end

        it "アイテムにpositionが自動割り当てされること" do
          post packing_list_items_path, params: {
            packing_item: { name: "最初のアイテム" }
          }
          post packing_list_items_path, params: {
            packing_item: { name: "2番目のアイテム" }
          }
          expect(PackingItem.where(packing_list: packing_list).order(:id).first.position).to eq(1)
          expect(PackingItem.where(packing_list: packing_list).order(:id).last.position).to eq(2)
        end
      end

      context "無効なパラメーターの場合" do
        it "nameが空だとアイテムが作成されないこと" do
          expect {
            post packing_list_items_path, params: {
              packing_item: { name: "" }
            }
          }.not_to change(PackingItem, :count)
        end

        it "nameが100文字を超えるとアイテムが作成されないこと" do
          expect {
            post packing_list_items_path, params: {
              packing_item: { name: "a" * 101 }
            }
          }.not_to change(PackingItem, :count)
        end
      end
    end

    context "ログインしていない場合" do
      before do
        sign_out user
      end

      it "ログインページにリダイレクトされること" do
        post packing_list_items_path, params: {
          packing_item: { name: "新しいアイテム" }
        }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "PATCH /packing_list/packing_items/:id" do
    let(:packing_item) { create(:packing_item, packing_list: packing_list, name: "元のアイテム") }

    context "ログインしている場合" do
      context "nameを更新する場合" do
        it "アイテムのnameが更新されること" do
          patch packing_list_item_path(packing_item), params: {
            packing_item: { name: "更新されたアイテム" }
          }
          packing_item.reload
          expect(packing_item.name).to eq("更新されたアイテム")
        end

        it "Turbo Streamレスポンスを返すこと" do
          patch packing_list_item_path(packing_item), params: {
            packing_item: { name: "更新されたアイテム" }
          }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
          expect(response).to have_http_status(:success)
          expect(response.content_type).to include("text/vnd.turbo-stream.html")
        end
      end

      context "checked を更新する場合" do
        it "アイテムのcheckedが更新されること" do
          patch packing_list_item_path(packing_item), params: {
            packing_item: { checked: true }
          }, headers: { "Accept" => "application/json" }
          packing_item.reload
          expect(packing_item.checked).to be true
        end

        it "JSON レスポンスで :ok を返すこと" do
          patch packing_list_item_path(packing_item), params: {
            packing_item: { checked: true }
          }, headers: { "Accept" => "application/json" }
          expect(response).to have_http_status(:ok)
        end
      end

      context "position を更新する場合" do
        let(:packing_item1) { create(:packing_item, packing_list: packing_list, name: "アイテム1") }
        let(:packing_item2) { create(:packing_item, packing_list: packing_list, name: "アイテム2") }
        let(:packing_item3) { create(:packing_item, packing_list: packing_list, name: "アイテム3") }

        it "アイテムの position が更新されること" do
          patch packing_list_item_path(packing_item2), params: {
            packing_item: { position: 3 }
          }, headers: { "Accept" => "application/json" }
          packing_item2.reload
          expect(packing_item2.position).to eq(3)
        end

        it "他のアイテムの position が自動調整されること" do
          patch packing_list_item_path(packing_item1), params: {
            packing_item: { position: 2 }
          }, headers: { "Accept" => "application/json" }
          packing_item1.reload
          packing_item2.reload
          packing_item3.reload
          expect(packing_item1.position).to eq(2)
          expect(packing_item2.position).to eq(3)
          expect(packing_item3.position).to eq(4)
        end

        it "JSON レスポンスで :ok を返すこと" do
          patch packing_list_item_path(packing_item2), params: {
            packing_item: { position: 1 }
          }, headers: { "Accept" => "application/json" }
          expect(response).to have_http_status(:ok)
        end
      end

      context "無効なパラメーターの場合" do
        it "name を空にするとエラーが返されること" do
          patch packing_list_item_path(packing_item), params: {
            packing_item: { name: "" }
          }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
          packing_item.reload
          expect(packing_item.name).to eq("元のアイテム")
        end
      end
    end

    context "ログインしていない場合" do
      before do
        sign_out user
      end

      it "ログインページにリダイレクトされること" do
        patch packing_list_item_path(packing_item), params: {
          packing_item: { name: "更新されたアイテム" }
        }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "DELETE /packing_list/packing_items/:id" do
    let(:packing_item) { create(:packing_item, packing_list: packing_list, name: "削除対象アイテム") }

    context "ログインしている場合" do
      it "アイテムが削除されること" do
        packing_item_id = packing_item.id
        expect {
          delete packing_list_item_path(packing_item)
        }.to change(PackingItem, :count).by(-1)
        expect(PackingItem.find_by(id: packing_item_id)).to be_nil
      end

      it "Turbo Stream レスポンスを返すこと" do
        delete packing_list_item_path(packing_item), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end

      it "削除後に他のアイテムの position が自動調整されること" do
        packing_item1 = create(:packing_item, packing_list: packing_list, name: "アイテム1", position: 1)
        packing_item2 = create(:packing_item, packing_list: packing_list, name: "アイテム2", position: 2)
        packing_item3 = create(:packing_item, packing_list: packing_list, name: "アイテム3", position: 3)

        delete packing_list_item_path(packing_item2)

        packing_item1.reload
        packing_item3.reload
        expect(packing_item1.position).to eq(1)
        expect(packing_item3.position).to eq(2)
      end
    end

    context "ログインしていない場合" do
      before do
        sign_out user
      end

      it "ログインページにリダイレクトされること" do
        delete packing_list_item_path(packing_item)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "他のユーザーのアイテムへのアクセス" do
    let(:other_user) { create(:user) }
    let(:other_packing_item) { create(:packing_item, packing_list: other_user.packing_list, name: "他のユーザーのアイテム") }

    context "他のユーザーのアイテムを更新しようとする場合" do
      it "404 エラーが返されること" do
        patch packing_list_item_path(other_packing_item), params: {
          packing_item: { name: "更新しようとしたアイテム" }
        }
        expect(response).to have_http_status(:not_found)
      end
    end

    context "他のユーザーのアイテムを削除しようとする場合" do
      it "404 エラーが返されること" do
        delete packing_list_item_path(other_packing_item)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
