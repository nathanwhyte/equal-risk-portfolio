require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include SessionTestHelper

  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  # Allow all external connections for system tests since they run in a separate process
  # and webmock stubs don't cross process boundaries
  setup do
    WebMock.allow_net_connect!
  end

  teardown do
    # Re-enable webmock restrictions after each test
    WebMock.disable_net_connect!(allow_localhost: true)
  end
end
