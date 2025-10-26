require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new session page is accessible" do
    get new_session_path
    assert_response :success
  end

  test "create session with valid credentials" do
    post session_path, params: {
      email_address: @user.email_address,
      password: "password"
    }

    assert_redirected_to root_path
    assert cookies["session_id"].present?
  end

  test "create session with invalid credentials" do
    post session_path, params: {
      email_address: @user.email_address,
      password: "wrong"
    }

    assert_redirected_to new_session_path
    assert_nil cookies["session_id"]
  end

  test "destroy session logs user out" do
    sign_in_as(@user)
    delete session_path

    assert_redirected_to new_session_path
  end
end
