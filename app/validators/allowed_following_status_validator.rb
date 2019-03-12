# frozen_string_literal: true

class AllowedFollowingStatusValidator < ActiveModel::Validator
  def validate(status)
    @status = status
    return unless status.direct_visibility? && !accounts.empty?
    return if status.text !~ /http:/ && status.text !~ /https:/

    not_following_accounts = accounts.reject { |a|
      a && !a.following?(status.account)      
    }
        
    status.errors.add(:text, I18n.t('statuses.cannot_send')) unless not_following_accounts.empty?
  end

  private

  def accounts
    @accounts ||= @status.text.scan(Account::MENTION_RE).collect do |match|
      username, domain  = Regexp.last_match(1).split('@')
      mentioned_account = Account.find_remote(username, domain)
    end
  end
end
