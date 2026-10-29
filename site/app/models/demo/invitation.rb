# The invitation form on the "Building forms" guide: every kind of field, each with
# a validation that can fail, so each shows its error the way an app's would.
class Demo::Invitation
  include ActiveModel::Model
  include ActiveModel::Attributes

  ROLES = %w[Admin Member Viewer].freeze
  TEAMS = [ [ "Design", 1 ], [ "Engineering", 2 ], [ "Marketing", 3 ] ].freeze

  attribute :name, :string
  attribute :email, :string
  attribute :role, :string
  attribute :team_id, :integer
  attribute :starts_on, :date
  attribute :note, :string
  attribute :notify, :boolean, default: true
  attribute :terms, :boolean

  validates :name, :email, :role, :team_id, :starts_on, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :role, inclusion: { in: ROLES }, allow_blank: true
  validates :note, length: { maximum: 160 }
  validates :terms, acceptance: true
  validate :starts_on_is_not_in_the_past

  def self.model_name = ActiveModel::Name.new(self, nil, "Invitation")

  private

  def starts_on_is_not_in_the_past
    errors.add(:starts_on, "can't be in the past") if starts_on&.past?
  end
end
