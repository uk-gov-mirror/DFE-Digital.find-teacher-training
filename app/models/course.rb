class Course < Base
  belongs_to :recruitment_cycle, through: :provider, param: :recruitment_cycle_year
  belongs_to :provider, param: :provider_code, shallow_path: true
  has_many :site_statuses
  has_many :sites, through: :site_statuses, source: :site
  has_many :subjects

  property :fee_international, type: :string
  property :fee_uk_eu, type: :string
  property :maths, type: :string
  property :english, type: :string
  property :science, type: :string
  property :changed_at, type: :time

  self.primary_key = :course_code

  def has_fees?
    funding_type == 'fee'
  end

  def university_based?
    provider_type == 'university'
  end

  def further_education?
    level == 'further_education' && subjects.any? { |s| s.subject_name == 'Further education' || s.subject_code = '41' }
  end

  def travel_to_work_areas
    travel_to_work_areas = site_statuses.map(&:site).map { |site| site.london_borough || site.travel_to_work_area }.uniq

    travel_to_work_areas.to_sentence(last_word_connector: ' and ')
  end
end
