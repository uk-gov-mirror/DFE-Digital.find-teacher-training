require 'rails_helper'

describe 'results/nearest_location.html.erb', type: :view do

  let(:site1) do
    build(
      :site,
      latitude: 51.4985,
      longitude: 0.1367,
      address1: '10 Windy Way',
      address2: 'Witham',
      address3: 'Essex',
      address4: 'UK',
      postcode: 'CM8 2SD',
    )
  end

  let(:site_statuses) do
    [
      build(:site_status, :full_time_and_part_time, site: site1),
    ]
  end

  let(:parameter_hash) { { 'lat' => '51.4975', 'lng' => '0.1357' } }

  before do
    assign(:results_view, ResultsView.new(query_parameters: parameter_hash))
  end

  context 'course provided by university' do
    let(:html) do
      render partial: 'results/nearest_location', locals: { course: course }
    end

    let(:university_provider) { build(:provider, :university) }

    let(:course) do
      build(:course, site_statuses: site_statuses, provider: university_provider)
    end

    it 'renders dt with Location' do
      expect(html).to have_no_css('dt.govuk-list--description__label', text: 'Nearest location')
    end

    it "renders '0.1 miles from you'" do
      expect(html).to match('0.1 miles from you')
    end

    it 'does not render university placement description' do
      expect(html).to have_css('span.govuk-list--description__hint.govuk-\\!-margin-top-0', text: "Distance to university campus. You'll only spend some of your time here."
      )
    end
  end

  context 'not provided by a university' do
    let(:html) do
      render partial: 'results/nearest_location', locals: { course: course }
    end

    let(:course) do
      build(:course, site_statuses: site_statuses)
    end

    it 'renders dt with Location' do
      expect(html).to have_no_css('dt.govuk-list--description__label', text: 'Nearest location')
    end

    it "renders '0.1 miles from you'" do
      expect(html).to match('0.1 miles from you')
    end

    it 'does not render university placement description' do
      expect(html).to have_no_css(
        'span.govuk-list--description__hint.govuk-\\!-padding-top-0'
      )
    end
  end
end
