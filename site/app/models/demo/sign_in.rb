# The sign-in form on the "Building forms" guide: a form object that checks
# what was typed, then the credentials. It knows one account, the one the
# guide tells you to try.
class Demo::SignIn
  include ActiveModel::Model
  include ActiveModel::Attributes

  EMAIL = "ada@example.com".freeze
  PASSWORD = "velvetkit".freeze

  attribute :email, :string
  attribute :password, :string
  attribute :remember_me, :boolean, default: false

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }
  validates :password, presence: true

  # Params arrive as sign_in[...], as they would for an app's own SignIn.
  def self.model_name = ActiveModel::Name.new(self, nil, "SignIn")

  def authenticate
    return false unless valid?
    return true if email.casecmp?(EMAIL) && password == PASSWORD

    errors.add(:base, "Email or password is incorrect")
    false
  end
end
