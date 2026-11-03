# The sign-up on the Stepper's docs page: three steps, each checked here on
# the server, as an app's own controller would. Some answers only the server
# can turn down: an email that already has an account, a workspace URL that's
# taken.
class Demo::Signup
  include ActiveModel::Model
  include ActiveModel::Attributes

  STEPS = %i[account workspace plan].freeze
  TAKEN_EMAILS = %w[ada@example.com].freeze
  TAKEN_SLUGS = %w[acme velvet admin].freeze
  # The fields each step asks for. The others ride along hidden, all but the
  # password, which is checked once and not sent back to the page.
  FIELDS = { 1 => %w[email password], 2 => %w[workspace_name workspace_slug], 3 => %w[plan] }.freeze
  PLANS = { "hobby" => "Hobby, free", "team" => "Team, $20 a month", "business" => "Business, $80 a month" }.freeze

  attribute :email, :string
  attribute :password, :string
  attribute :workspace_name, :string
  attribute :workspace_slug, :string
  attribute :plan, :string

  with_options on: :account do
    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }
    validates :password, presence: true, length: { minimum: 8, allow_blank: true }
    validate { errors.add(:email, "already has an account. Sign in instead?") if TAKEN_EMAILS.include?(email.to_s.downcase.strip) }
  end

  with_options on: :workspace do
    validates :workspace_name, presence: true
    validates :workspace_slug, presence: true,
                               format: { with: /\A[a-z0-9][a-z0-9-]*\z/, allow_blank: true, message: "can only have lowercase letters, numbers and dashes" }
    validate { errors.add(:workspace_slug, "is taken. Try #{workspace_slug}-hq?") if TAKEN_SLUGS.include?(workspace_slug.to_s) }
  end

  with_options on: :plan do
    validates :plan, inclusion: { in: PLANS.keys, message: "needs choosing" }
  end

  def self.model_name = ActiveModel::Name.new(self, nil, "Signup")

  def self.human_attribute_name(attribute, options = {})
    { "workspace_name" => "Workspace name", "workspace_slug" => "Workspace URL" }.fetch(attribute.to_s) { super }
  end

  def self.carried(step) = attribute_names - FIELDS.fetch(step) - %w[password]

  def valid_step?(step) = valid?(STEPS.fetch(step - 1))
end
