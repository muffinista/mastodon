# frozen_string_literal: true

class Settings::ApisController < ApplicationController
  layout 'admin'

  before_action :authenticate_user!

  def show; end

  def update
    current_user.default_api_application.try(:destroy)
    redirect_to settings_api_path, notice: I18n.t('generic.reset')
  end
end
