module SessionTestHelper
  # Stub module to provide signed cookie access
  # In tests, we need to verify the signed cookie and return the session ID
  module SignedCookieAccessor
    def signed
      @signed_jar ||= SignedCookieJar.new(self)
    end
  end

  # Custom cookie jar that properly verifies and returns signed values
  class SignedCookieJar
    def initialize(cookies)
      @cookies = cookies
    end

    def [](key)
      value = @cookies[key]
      return nil unless value

      # Verify the signed cookie and return the verified value
      verifier = Rails.application.message_verifier("signed cookie jar")
      verifier.verify(value)
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      nil
    end
  end

  def sign_in_as(user)
    if respond_to?(:cookies)
      # Integration test approach
      @test_session = user.sessions.create!
      @test_user = user

      # Generate signed cookie value using Rails' message verifier
      @signed_session_cookie = Rails.application.message_verifier("signed cookie jar").generate(@test_session.id)

      # Set the signed cookie value - this will persist across all requests in the test
      cookies["session_id"] = @signed_session_cookie

      # Extend cookies to support .signed accessor if not already extended
      unless cookies.respond_to?(:signed)
        cookies.extend(SignedCookieAccessor)
      end

      # Set Current.session for the first request
      # Note: Current is reset between requests, so we need to restore it
      Thread.current[:current_session] = @test_session
    elsif respond_to?(:page) && page.respond_to?(:driver)
      # System test approach - set session cookie directly
      session = user.sessions.create!
      Current.session = session

      # Set the session cookie in the browser
      page.driver.browser.manage.add_cookie(
        name: "session_id",
        value: Rails.application.message_verifier("signed cookie jar").generate(session.id),
        domain: "localhost"
      )
    else
      # Fallback for other test types
      Current.session = user.sessions.create!
    end
  end

  def sign_out
    Current.session&.destroy!
    @test_session = nil
    @signed_session_cookie = nil
    if respond_to?(:cookies)
      cookies.delete("session_id")
    elsif respond_to?(:page) && page.respond_to?(:driver)
      page.driver.browser.manage.delete_all_cookies
    end
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) do
  include SessionTestHelper
end
