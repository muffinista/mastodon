# frozen_string_literal: true

class User < ApplicationRecord
  include Settings::Extend

  devise :registerable, :recoverable,
         :rememberable, :trackable, :validatable, :confirmable,
         :two_factor_authenticatable, otp_secret_encryption_key: ENV['OTP_SECRET']

  belongs_to :account, inverse_of: :user
  accepts_nested_attributes_for :account

  validates :account, presence: true
  validates :locale, inclusion: I18n.available_locales.map(&:to_s), unless: 'locale.nil?'
  validates :email, email: true

  scope :prolific,  -> { joins('inner join statuses on statuses.account_id = users.account_id').select('users.*, count(statuses.id) as statuses_count').group('users.id').order('statuses_count desc') }
  scope :recent,    -> { order('id desc') }
  scope :admins,    -> { where(admin: true) }
  scope :confirmed, -> { where.not(confirmed_at: nil) }

  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end

  def setting_default_privacy
    settings.default_privacy || (account.locked? ? 'private' : 'public')
  end

  def default_api_name
    [ account.username, "API access" ].join(" ")
  end
  
  def default_api_application
    Doorkeeper::Application.find_or_create_by(
      name:default_api_name,
      redirect_uri: "urn:ietf:wg:oauth:2.0:oob",
      scopes: "read write follow")
  end
  
  def api_access_token
    Doorkeeper::AccessToken.find_or_create_by(
        application_id:default_api_application.id,
        resource_owner_id: self.id) do |t|

      t.scopes = 'read write follow'
      t.expires_in = Doorkeeper.configuration.access_token_expires_in
      t.use_refresh_token = Doorkeeper.configuration.refresh_token_enabled?
    end
  end
end
