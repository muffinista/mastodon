require 'rails_helper'

RSpec.describe Settings::ApisController, type: :controller do

  before do
    sign_in Fabricate(:user), scope: :user
  end

  describe "GET #show" do
    it "returns http success" do
      get :show
      expect(response).to have_http_status(:success)
    end
  end

  describe "PUT #update" do
    it "redirects" do
      put :update
      expect(response).to be_redirect
    end
  end

end
