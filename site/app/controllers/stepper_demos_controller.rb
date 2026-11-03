# Answers the sign-up on the Stepper's docs page as an app's own controller
# would: check the step that was sent; valid, show the next one; invalid,
# show the same one again with its errors and a 422. Back skips the checks.
# Earlier answers travel in hidden fields, where an app might keep a draft
# record or the session.
class StepperDemosController < ApplicationController
  def create
    @signup = Demo::Signup.new(params.expect(signup: [ :email, :password, :workspace_name, :workspace_slug, :plan ]))
    step = params[:step].to_i.clamp(1, Demo::Signup::STEPS.size)

    # A real check takes a moment; this one waits so the spinner shows.
    sleep 0.4 unless Rails.env.test?

    if params[:back]
      render_step [ step - 1, 1 ].max
    elsif @signup.valid_step?(step)
      render_step step + 1
    else
      render_step step, failed: true, status: :unprocessable_entity
    end
  end

  private

  def render_step(step, failed: false, status: :ok)
    render partial: "components/demos/stepper", locals: { signup: @signup, step: step, failed: failed }, status: status
  end
end
