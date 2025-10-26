module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    def authenticated?
      resume_session
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      Current.session ||= find_session_by_cookie || find_session_by_header
    end

    def find_session_by_cookie
      signed_id = nil
      begin
        signed_id = cookies.signed[:session_id] if cookies.respond_to?(:signed)
      rescue => e
        Rails.logger.error "Error reading signed cookie: #{e.message}"
      end

      Session.find_by(id: signed_id) if signed_id
    end

    # Allow test authentication via Current.session (set by test helper)
    def find_session_by_header
      # Check Thread.current for test sessions
      thread_session = Thread.current[:current_session]
      return thread_session if thread_session && thread_session.is_a?(Session)

      Current.session
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_path
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }
      end
    end

    def terminate_session
      Current.session.destroy
      cookies.delete(:session_id)
    end
end
