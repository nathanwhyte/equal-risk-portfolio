require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new password reset page is accessible" do
    get new_password_path
    assert_response :success
  end

  test "create password reset request sends email" do
    post passwords_path, params: { email_address: @user.email_address }
    assert_enqueued_email_with PasswordsMailer, :reset, args: [ @user ]
    assert_redirected_to new_session_path
  end

  test "create password reset for unknown user does not send email" do
    post passwords_path, params: { email_address: "missing-user@example.com" }
    assert_enqueued_emails 0
    assert_redirected_to new_session_path
  end

  test "edit with valid token shows password form" do
    get edit_password_path(@user.password_reset_token)
    assert_response :success
  end

  test "edit with invalid token redirects with error" do
    get edit_password_path("invalid token")
    assert_redirected_to new_password_path
  end

  test "update password with matching confirmation" do
    assert_changes -> { @user.reload.password_digest } do
      put password_path(@user.password_reset_token), params: {
        password: "new_password",
        password_confirmation: "new_password"
      }
      assert_redirected_to new_session_path
    end
  end

  test "update password with non-matching confirmation fails" do
    token = @user.password_reset_token
    assert_no_changes -> { @user.reload.password_digest } do
      put password_path(token), params: {
        password: "new_password",
        password_confirmation: "different"
      }
      assert_redirected_to edit_password_path(token)
    end
  end
end
