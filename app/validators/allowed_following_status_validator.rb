# frozen_string_literal: true

class AllowedFollowingStatusValidator < ActiveModel::Validator
  def validate(status)
    @status = status
    return unless !accounts.empty?

    # allow messages from local admin/moderators
    return if status.account.user_moderator? || status.account.user_admin?

    # allow messages from accounts that seem to have legit traffic
    return if status.account.account_stat.statuses_count > 25
    return if status.account.account_stat.followers_count > 5

    not_following_accounts = []
    
    begin
      not_following_accounts = accounts.select { |a|
        a && !a.following?(status.account)
      }.reject { |a|
        # allow messages to local admin/moderators
        (a.respond_to?(:user_admin?) && a.user_admin?) ||
          (a.respond_to?(:user_moderator?) && a.user_moderator?)
      }
    rescue StandardError => ex
      Raven.capture_exception(ex) if defined?(Raven)
    end
      

    if status.thread.present?
      mentioned_accounts = []
      begin
        #mentioned_accounts = status.thread.include(:account).map(&:account)
        mentioned_accounts = status.mentions.includes(:account).map(&:account)
      rescue StandardError => ex
        Raven.capture_exception(ex) if defined?(Raven)
      end

      # if the thread includes this account
      if mentioned_accounts.include?(status.account)
        # allow messages to accounts in the thread, if this account
        # was mentioned in the thread
        not_following_accounts = not_following_accounts.reject { |a|
          mentioned_accounts.include?(a)
        }
      end
    end


    status.errors.add(:text, I18n.t('statuses.cannot_send')) unless not_following_accounts.empty?
  end

  private

  def accounts
    @status.text.scan(Account::MENTION_RE).collect do |match|
      mentioned_account = nil
      begin
        username, domain  = Regexp.last_match(1).split('@')
        mentioned_account = Account.find_remote(username, domain)
        mentioned_account = Account.find_local(username) if mentioned_account.nil?
      rescue StandardError => ex
        Raven.capture_exception(ex) if defined?(Raven)
      end

      mentioned_account
    end
  end
end
