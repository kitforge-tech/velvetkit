require "test_helper"

# The live forms on the "Building forms" guide answer like an app's would:
# 422 with the errors in place, or success.
class FormsGuideTest < ActionDispatch::IntegrationTest
  test "the guide renders both forms empty" do
    get doc_path("forms")
    assert_response :success
    assert_select "turbo-frame#sign-in-demo form[action='#{form_demo_sign_in_path}']"
    assert_select "turbo-frame#invitation-demo form[action='#{form_demo_invitation_path}']"
    assert_select "[aria-invalid='true']", count: 0
  end

  test "sign in, empty: field errors and a 422" do
    post form_demo_sign_in_path, params: { sign_in: { email: "", password: "" } }
    assert_response :unprocessable_entity
    assert_select "input[name='sign_in[email]'][aria-invalid='true']"
    assert_select "p.text-destructive", text: "Email can't be blank"
    assert_select "p.text-destructive", text: "Password can't be blank"
  end

  test "sign in, wrong password: an error on the whole form, typed email kept" do
    post form_demo_sign_in_path, params: { sign_in: { email: Demo::SignIn::EMAIL, password: "nope" } }
    assert_response :unprocessable_entity
    assert_select "[role='alert'], .text-destructive", text: /Email or password is incorrect/
    assert_select "input[name='sign_in[email]'][value='#{Demo::SignIn::EMAIL}']"
  end

  test "sign in, right password: success" do
    post form_demo_sign_in_path, params: { sign_in: { email: Demo::SignIn::EMAIL, password: Demo::SignIn::PASSWORD } }
    assert_response :success
    assert_select "turbo-frame#sign-in-demo", text: /Signed in as #{Demo::SignIn::EMAIL}/
  end

  test "invitation, empty: a summary and an error under every field" do
    post form_demo_invitation_path, params: { invitation: { name: "", email: "", role: "", team_id: "", starts_on: "", note: "", notify: "0", terms: "0" } }
    assert_response :unprocessable_entity
    assert_select "turbo-frame#invitation-demo", text: /6 problems to fix before sending/
    [ "Name can't be blank", "Role can't be blank", "Team can't be blank", "Start date can't be blank", "Permission must be accepted" ].each do |message|
      assert_select "p.text-destructive", text: message
    end
    assert_select "select[name='invitation[team_id]'][aria-invalid='true']"
    assert_select "button[role='combobox'][aria-invalid='true']"
  end

  test "invitation, start date in the past: shown under the date picker" do
    post form_demo_invitation_path, params: { invitation: { name: "Grace", email: "grace@example.com", role: "Member", team_id: "2",
                                                            starts_on: "2020-01-01", notify: "1", terms: "1" } }
    assert_response :unprocessable_entity
    assert_select "p.text-destructive", text: "Start date can't be in the past"
    assert_select "input[name='invitation[name]'][value='Grace']"
    assert_select "select[name='invitation[team_id]'] option[value='2'][selected]"
    assert_select "label", text: "Start date"
  end

  test "invitation, valid: success" do
    post form_demo_invitation_path, params: { invitation: { name: "Grace", email: "grace@example.com", role: "Member", team_id: "2",
                                                            starts_on: Date.tomorrow.iso8601, notify: "1", terms: "1" } }
    assert_response :success
    assert_select "turbo-frame#invitation-demo", text: /Invite sent to grace@example.com/
  end

  test "the sidebar's Forms branch holds the guide and the form components" do
    get component_path("input")
    assert_select "aside details[open] > summary", text: "Forms"
    assert_select "aside details[open] a[href='#{doc_path("forms")}']"
    assert_select "aside details[open] a[href='#{component_path("input")}'][aria-current='page']"
    assert_select "aside nav[aria-label='Documentation'] a[href='#{component_path("input")}']", count: 1
  end

  test "the Forms branch starts closed elsewhere" do
    get component_path("dialog")
    assert_select "aside details:not([open]) > summary", text: "Forms"
  end
end
