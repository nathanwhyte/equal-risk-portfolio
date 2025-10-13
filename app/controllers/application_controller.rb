class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :assign_session_id

  private

  def assign_session_id
    session[:session_id] ||= SecureRandom.uuid
  end
end
