require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it 'is invalid without an account' do
      user = Fabricate.build(:user, account: nil)
      user.valid?
      expect(user).to model_have_error_on_field(:account)
    end

    it 'is invalid without a valid locale' do
      user = Fabricate.build(:user, locale: 'toto')
      user.valid?
      expect(user).to model_have_error_on_field(:locale)
    end

    it 'is invalid without a valid email' do
      user = Fabricate.build(:user, email: 'john@')
      user.valid?
      expect(user).to model_have_error_on_field(:email)
    end
  end

  describe 'scopes' do
    describe 'recent' do
      it 'returns an array of recent users ordered by id' do
        user_1 = Fabricate(:user)
        user_2 = Fabricate(:user)
        expect(User.recent).to match_array([user_2, user_1])
      end
    end

    describe 'admins' do
      it 'returns an array of users who are admin' do
        user_1 = Fabricate(:user, admin: false)
        user_2 = Fabricate(:user, admin: true)
        expect(User.admins).to match_array([user_2])
      end
    end

    describe 'confirmed' do
      it 'returns an array of users who are confirmed' do
        user_1 = Fabricate(:user, confirmed_at: nil)
        user_2 = Fabricate(:user, confirmed_at: Time.now)
        expect(User.confirmed).to match_array([user_2])
      end
    end
  end

  let(:account) { Fabricate(:account, username: 'alice') }
  let(:password) { 'abcd1234' }

  describe 'blacklist' do
    it 'should allow a non-blacklisted user to be created' do
      user = User.new(email: 'foo@example.com', account: account, password: password)

      expect(user.valid?).to be_truthy
    end

    it 'should not allow a blacklisted user to be created' do
      user = User.new(email: 'foo@mvrht.com', account: account, password: password)

      expect(user.valid?).to be_falsey
    end
  end

  describe 'whitelist' do
    around(:each) do |example|
      old_whitelist = Rails.configuration.x.email_whitelist

      Rails.configuration.x.email_domains_whitelist = 'mastodon.space'

      example.run

      Rails.configuration.x.email_domains_whitelist = old_whitelist
    end

    it 'should not allow a user to be created unless they are whitelisted' do
      user = User.new(email: 'foo@example.com', account: account, password: password)
      expect(user.valid?).to be_falsey
    end

    it 'should allow a user to be created if they are whitelisted' do
      user = User.new(email: 'foo@mastodon.space', account: account, password: password)
      expect(user.valid?).to be_truthy
    end
  end

  describe "API methods" do
    let(:user) { Fabricate(:user, account: account) }
    describe 'default_api_name' do
      it "should include account username" do
        expect(user.default_api_name).to eql("alice API access")
      end
    end
    
    describe "default_api_application" do
      it "should create once and then persist" do
        app = user.default_api_application
        expect(app).to be_a(Doorkeeper::Application)

        app2 = user.reload.default_api_application
        expect(app2).to eql(app)
      end

      it "recreates if deleted" do
        app = user.default_api_application
        expect(app).to be_a(Doorkeeper::Application)

        app.destroy

        app2 = user.default_api_application
        expect(app2).to be_a(Doorkeeper::Application)

        expect(app2).to_not eql(app)
      end
    end
    
    describe "api_access_token" do
      it "should create once and then persist" do
        token = user.api_access_token
        expect(token.application).to eql(user.default_api_application)

        token2 = user.reload.api_access_token
        expect(token2).to eql(token)
      end
    end
  end
end
