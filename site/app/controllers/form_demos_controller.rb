# Answers the live forms on the "Building forms" guide as an app's own
# controller would: valid, it succeeds; invalid, it renders the form again
# with the errors and a 422, which Turbo shows in place.
class FormDemosController < ApplicationController
  layout "docs"

  def sign_in
    @sign_in = Demo::SignIn.new(params.expect(sign_in: [ :email, :password, :remember_me ]))
    render_guide(@sign_in.authenticate)
  end

  def invitation
    @invitation = Demo::Invitation.new(params.expect(invitation: [ :name, :email, :role, :team_id, :starts_on, :note, :notify, :terms ]))
    render_guide(@invitation.valid?)
  end

  private

  # An app would redirect on success; the demo stays on the guide and says so.
  def render_guide(success)
    @page = "forms"
    @success = success
    render "docs/forms", status: success ? :ok : :unprocessable_entity
  end
end
