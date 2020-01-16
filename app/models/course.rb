class Course < Base
  belongs_to :recruitment_cycle, through: :provider, param: :recruitment_cycle_year
  belongs_to :provider, param: :provider_code
  has_many :site_statuses
  has_many :sites, through: :site_statuses, source: :site
  has_many :subjects

  property :fee_international, type: :string
  property :fee_uk_eu, type: :string
  property :maths, type: :string
  property :english, type: :string
  property :science, type: :string

  self.primary_key = :course_code

  def has_fees?
    funding_type == "fee"
  end

  def year
    applications_open_from.split("-").first if applications_open_from.present?
  end

  def month
    applications_open_from.split("-").second if applications_open_from.present?
  end

  def day
    applications_open_from.split("-").third if applications_open_from.present?
  end
end