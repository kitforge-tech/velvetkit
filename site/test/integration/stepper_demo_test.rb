require "test_helper"

# The sign-up on the Stepper's page is checked here, a step at a time: the
# next step on success, the same one with its errors and a 422 otherwise.
class StepperDemoTest < ActionDispatch::IntegrationTest
  def signup(**fields)
    { email: "", password: "", workspace_name: "", workspace_slug: "", plan: "" }.merge(fields)
  end

  test "the page shows the demo on its first step" do
    get component_path("stepper")
    assert_response :success
    assert_select "turbo-frame#stepper-demo form[action='#{stepper_demo_path}']"
    assert_select "turbo-frame#stepper-demo li[data-status='current']", text: /Account/
  end

  test "an email that already has an account is turned down by the server" do
    post stepper_demo_path, params: { step: 1, signup: signup(email: "ada@example.com", password: "longenough") }
    assert_response :unprocessable_entity
    assert_select "li[data-status='error']", text: /Account/
    assert_select "p.text-destructive", text: "Email already has an account. Sign in instead?"
  end

  test "a valid step moves on, carrying earlier answers but not the password" do
    post stepper_demo_path, params: { step: 1, signup: signup(email: "grace@example.com", password: "longenough") }
    assert_response :success
    assert_select "li[data-status='complete']", text: /grace@example.com/
    assert_select "li[data-status='current']", text: /Workspace/
    assert_select "input[type='hidden'][name='signup[email]'][value='grace@example.com']"
    assert_select "input[name='signup[password]']", count: 0
  end

  test "a pasted address is cut down to the workspace name" do
    post stepper_demo_path, params: { step: 2, signup: signup(email: "grace@example.com", workspace_name: "Works", workspace_slug: "https://www.Works.example.com/") }
    assert_response :success
    assert_select "li[data-status='complete']", text: /works.example.com/
  end

  test "a name that isn't one says what is" do
    post stepper_demo_path, params: { step: 2, signup: signup(email: "grace@example.com", workspace_name: "Works", workspace_slug: "works.com") }
    assert_response :unprocessable_entity
    assert_select "p.text-destructive", text: "Workspace address can only have lowercase letters, numbers and dashes, like acme-hq"
  end

  test "a taken workspace address" do
    post stepper_demo_path, params: { step: 2, signup: signup(email: "grace@example.com", workspace_name: "Acme", workspace_slug: "acme") }
    assert_response :unprocessable_entity
    assert_select "p.text-destructive", text: "Workspace address is taken. Try acme-hq?"
  end

  test "back skips the checks" do
    post stepper_demo_path, params: { step: 2, back: "1", signup: signup(email: "grace@example.com") }
    assert_response :success
    assert_select "li[data-status='current']", text: /Account/
  end

  test "the last step finishes" do
    post stepper_demo_path, params: { step: 3, signup: signup(email: "grace@example.com", workspace_name: "Acme", workspace_slug: "acme-hq", plan: "team") }
    assert_response :success
    assert_select "li[data-status='complete']", count: 3
    assert_select "h3", text: "Workspace created"
  end
end
