require 'rails_helper'

describe ResultsView do
  include StubbedRequests::Courses
  include StubbedRequests::Subjects

  let(:query_parameters) { ActionController::Parameters.new(parameter_hash) }

  let(:default_output_parameters) do
    {
      'qualifications' => %w[QtsOnly PgdePgceWithQts Other],
      'fulltime' => false,
      'parttime' => false,
      'hasvacancies' => true,
      'senCourses' => false,
    }
  end

  before do
    stub_subjects
  end

  describe '#query_parameters_with_defaults' do
    subject(:results_view) { described_class.new(query_parameters: query_parameters).query_parameters_with_defaults }

    context 'params are empty' do
      let(:parameter_hash) { {} }

      it { is_expected.to eq(default_output_parameters) }
    end

    context 'query_parameters have qualifications set' do
      let(:parameter_hash) { { 'qualifications' => 'Other' } }

      it { is_expected.to eq(default_output_parameters.merge(parameter_hash)) }
    end

    context 'query_parameters have fulltime set' do
      let(:parameter_hash) { { 'fulltime' => 'true' } }

      it { is_expected.to eq(default_output_parameters.merge('fulltime' => true)) }
    end

    context 'query_parameters have parttime set' do
      let(:parameter_hash) { { 'parttime' => 'true' } }

      it { is_expected.to eq(default_output_parameters.merge('parttime' => true)) }
    end

    context 'query_parameters have hasvacancies set' do
      let(:parameter_hash) { { 'hasvacancies' => 'true' } }

      it { is_expected.to eq(default_output_parameters.merge('hasvacancies' => true)) }
    end

    context 'query_parameters have senCourses set' do
      let(:parameter_hash) { { 'senCourses' => 'false' } }

      it { is_expected.to eq(default_output_parameters.merge('senCourses' => false)) }
    end

    context "query_parameters not lose track of 'l' used by C# radio buttons" do
      let(:parameter_hash) { { 'l' => '2' } }

      it { is_expected.to eq(default_output_parameters.merge(parameter_hash)) }
    end

    context 'parameters without default present in query_parameters' do
      let(:parameter_hash) { { 'lat' => '52.3812321', 'lng' => '-3.9440235' } }

      it { is_expected.to eq(default_output_parameters.merge(parameter_hash)) }
    end

    context 'rails specific parameters are present' do
      let(:parameter_hash) { { 'utf8' => 'true', 'authenticity_token' => 'booyah' } }

      it 'filters them out' do
        expect(results_view).to eq(default_output_parameters.merge({}))
      end
    end

    context 'query_parameters have subjects set' do
      # TODO: the query parameters are currently C# DB ids. They are converted internally
      # in this class but should also be C# parameters when they are output here
      # This will change when we fully switch to Rails

      let(:parameter_hash) { { 'subjects' => '14,41,20' } }

      it { is_expected.to eq(default_output_parameters.merge(parameter_hash)) }
    end
  end

  describe 'filter_path_with_unescaped_commas' do
    let(:default_query_parameters) do
      {
        'qualifications' => %w[QtsOnly PgdePgceWithQts Other],
        'fulltime' => 'false',
        'parttime' => 'false',
        'hasvacancies' => 'true',
        'senCourses' => 'false',
      }
    end

    subject(:results_view) { described_class.new(query_parameters: default_query_parameters).filter_path_with_unescaped_commas('/test') }

    it 'appends an unescaped querystring to the passed path' do
      allow(UnescapedQueryStringService).to receive(:call).with(
        base_path: '/test',
        parameters: default_output_parameters,
      )
        .and_return('test_result')
      expect(results_view).to eq('test_result')
    end
  end

  describe '#qts_only?' do
    let(:results_view) { described_class.new(query_parameters: parameter_hash) }

    context "when the hash includes 'QTS only'" do
      let(:parameter_hash) { { 'qualifications' => %w[QtsOnly PgdePgceWithQts] } }

      it 'returns true' do
        expect(results_view.qts_only?).to be_truthy
      end
    end

    context "when the hash does not include 'QTS only'" do
      let(:parameter_hash) { { 'qualifications' => %w[Other] } }

      it 'returns false' do
        expect(results_view.qts_only?).to be_falsy
      end
    end
  end

  describe '#pgce_or_pgde_with_qts?' do
    let(:results_view) { described_class.new(query_parameters: parameter_hash) }

    context "when the hash includes 'PGCE (or PGDE) with QTS'" do
      let(:parameter_hash) { { 'qualifications' => 'QtsOnly,PgdePgceWithQts' } }

      it 'returns true' do
        expect(results_view.pgce_or_pgde_with_qts?).to be_truthy
      end
    end

    context "when the hash does not include 'PGCE (or PGDE) with QTS'" do
      let(:parameter_hash) { { 'qualifications' => 'Other' } }

      it 'returns false' do
        expect(results_view.pgce_or_pgde_with_qts?).to be_falsy
      end
    end
  end

  describe '#other_qualifications?' do
    let(:results_view) { described_class.new(query_parameters: parameter_hash) }

    context "when the hash includes 'Further Education (PGCE or PGDE without QTS)'" do
      let(:parameter_hash) { { 'qualifications' => 'QtsOnly,Other' } }

      it 'returns true' do
        expect(results_view.other_qualifications?).to be_truthy
      end
    end

    context "when the hash does not include 'Further Education (PGCE or PGDE without QTS)'" do
      let(:parameter_hash) { { 'qualifications' => 'QtsOnly' } }

      it 'returns false' do
        expect(results_view.other_qualifications?).to be_falsy
      end
    end
  end

  describe '#all_qualifications?' do
    let(:results_view) { described_class.new(query_parameters: parameter_hash) }

    context "when all selected'" do
      let(:parameter_hash) { { 'qualifications' => 'QtsOnly,PgdePgceWithQts,Other' } }

      it 'returns true' do
        expect(results_view.all_qualifications?).to eq(true)
      end
    end

    context 'when not all selected' do
      let(:parameter_hash) { { 'qualifications' => 'QtsOnly' } }

      it 'returns false' do
        expect(results_view.all_qualifications?).to eq(false)
      end
    end
  end

  describe '#send_courses?' do
    let(:results_view) { described_class.new(query_parameters: parameter_hash) }

    context 'when the senCourses is True' do
      let(:parameter_hash) { { 'senCourses' => 'True' } }

      it 'returns true' do
        expect(results_view.send_courses?).to be_truthy
      end
    end

    context 'when the senCourses is nil' do
      let(:parameter_hash) { {} }

      it 'returns false' do
        expect(results_view.send_courses?).to be_falsy
      end
    end
  end

  describe '#number_of_extra_subjects' do
    let(:results_view) { described_class.new(query_parameters: parameter_hash) }

    context 'The maximum number of subjects are selected' do
      let(:parameter_hash) { { 'subjects' => (1..43).to_a } }

      it 'Returns the number of extra subjects - 2' do
        expect(results_view.number_of_extra_subjects).to eq(37)
      end
    end

    context 'more than NUMBER_OF_SUBJECTS_DISPLAYED subjects are selected' do
      let(:parameter_hash) { { 'subjects' => %w[1 2 3 4 5] } }

      it 'returns the number of the extra subjects' do
        expect(results_view.number_of_extra_subjects).to eq(1)
      end
    end

    context 'no subjects are selected' do
      let(:parameter_hash) { {} }

      it 'returns the total number subjects - NUMBER_OF_SUBJECTS_DISPLAYED' do
        expect(results_view.number_of_extra_subjects).to eq(37)
      end
    end
  end

  describe '#location' do
    subject { described_class.new(query_parameters: parameter_hash).location }

    context 'when loc is passed' do
      let(:parameter_hash) { { 'loc' => 'Hogwarts' } }

      it { is_expected.to eq('Hogwarts') }
    end

    context 'when loc is not passed' do
      let(:parameter_hash) { {} }

      it { is_expected.to eq('Across England') }
    end
  end

  describe '#radius' do
    subject { described_class.new(query_parameters: parameter_hash).radius }

    let(:parameter_hash) { {} }

    it { is_expected.to eq('50') }
  end

  describe '#show_map?' do
    subject { described_class.new(query_parameters: parameter_hash).show_map? }

    context 'when lng, lat and rad are passed' do
      let(:parameter_hash) { { 'lng' => '0.3', 'lat' => '0.2', 'rad' => '10' } }

      it { is_expected.to be(true) }
    end

    context 'when only rad is passed' do
      let(:parameter_hash) { { 'rad' => '10' } }

      it { is_expected.to be(false) }
    end

    context 'when only lat is passed' do
      let(:parameter_hash) { { 'lat' => '0.10' } }

      it { is_expected.to be(false) }
    end

    context 'when only lng is passed' do
      let(:parameter_hash) { { 'lng' => '1.0' } }

      it { is_expected.to be(false) }
    end

    context 'when no params are passed' do
      let(:parameter_hash) { {} }

      it { is_expected.to be(false) }
    end
  end

  describe '#courses' do
    let(:results_view) { described_class.new(query_parameters: {}) }

    it 'returns a JSON query builder' do
      expect(results_view.courses).to be_a(JsonApiClient::Query::Builder)
    end
  end

  describe '#map_image_url' do
    subject { described_class.new(query_parameters: parameter_hash).map_image_url }

    let(:parameter_hash) do
      {
        'loc' => 'Hogwarts, Reading, UK',
        'rad' => '10',
        'lng' => '-27.1504002',
        'lat' => '-109.3042697',
      }
    end

    before do
      allow(Settings.google).to receive(:maps_api_key).and_return('yellowskullkey')
      allow(Settings.google).to receive(:maps_api_url).and_return('https://maps.googleapis.com/maps/api/staticmap')
    end

    it { is_expected.to eq('https://maps.googleapis.com/maps/api/staticmap?key=yellowskullkey&center=-109.3042697,-27.1504002&zoom=9&size=300x200&scale=2&markers=-109.3042697,-27.1504002') }
  end

  describe '#provider' do
    subject { described_class.new(query_parameters: parameter_hash).provider }

    context 'when query is passed' do
      let(:parameter_hash) { { 'query' => 'Kamino' } }

      it { is_expected.to eq('Kamino') }
    end
  end

  describe '#location_filter?' do
    subject { described_class.new(query_parameters: parameter_hash).location_filter? }

    context 'when l param is set to 1' do
      let(:parameter_hash) { { 'l' => '1' } }

      it { is_expected.to be(true) }
    end

    context 'when l param is not set to 1' do
      let(:parameter_hash) { { 'l' => '2' } }

      it { is_expected.to be(false) }
    end
  end

  describe '#england_filter?' do
    subject { described_class.new(query_parameters: parameter_hash).england_filter? }

    context 'when l param is set to 2' do
      let(:parameter_hash) { { 'l' => '2' } }

      it { is_expected.to be(true) }
    end

    context 'when l param is not set to 2' do
      let(:parameter_hash) { { 'l' => '3' } }

      it { is_expected.to be(false) }
    end
  end

  describe '#provider_filter?' do
    subject { described_class.new(query_parameters: parameter_hash).provider_filter? }

    context 'when l param is set to 3' do
      let(:parameter_hash) { { 'l' => '3' } }

      it { is_expected.to be(true) }
    end

    context 'when l param is not set to 3' do
      let(:parameter_hash) { { 'l' => '2' } }

      it { is_expected.to be(false) }
    end
  end

  describe '#course_count' do
    subject { described_class.new(query_parameters: {}).course_count }

    context 'there are more than three results' do
      before do
        stub_courses(query: results_page_parameters, course_count: 10)
      end

      it { is_expected.to be(10) }
    end

    context 'there are no results' do
      before do
        stub_courses(query: results_page_parameters, course_count: 0)
      end

      it { is_expected.to be(0) }
    end
  end

  describe '#subjects' do
    context 'when no parameters are passed' do
      let(:results_view) { described_class.new(query_parameters: {}) }

      it 'returns the first four subjects in alphabetical order' do
        expect(results_view.subjects.map(&:subject_name)).to eq(
          [
            'Art and design',
            'Biology',
            'Business studies',
            'Chemistry',
          ],
        )
      end

      context 'when subject parameters are passed' do
        let(:results_view) do
          described_class.new(query_parameters: {
            'subjects' => [
              french_csharp_id,
              russian_csharp_id,
              primary_csharp_id,
              spanish_csharp_id,
              mathematics_csharp_id,
            ],
          })
        end

        let(:french_csharp_id) { '13' }
        let(:primary_csharp_id) { '31' }
        let(:spanish_csharp_id) { '44' }
        let(:mathematics_csharp_id) { '24' }
        let(:russian_csharp_id) { '41' }

        it 'returns the first four matching subjects in alphabetical order' do
          expect(results_view.subjects.map(&:subject_name)).to eq(
            %w[
              French
              Mathematics
              Primary
              Russian
            ],
          )
        end
      end
    end
  end

  describe '#suggested_search_visible?' do
    def suggested_search_count_parameters
      results_page_parameters.reject do |k, _v|
        ['page[page]', 'page[per_page]', 'sort'].include?(k)
      end
    end

    context 'searching for courses within England' do
      subject { described_class.new(query_parameters: { 'c' => 'England', 'lat' => '0.1', 'lng' => '2.4', 'rad' => '50' }).suggested_search_visible? }

      context 'there are more than three results' do
        before do
          stub_courses(query: results_page_parameters, course_count: 10)
        end

        it { is_expected.to be(false) }
      end

      context 'there are less than three results and there are suggested courses found' do
        before do
          stub_courses(query: results_page_parameters, course_count: 2)
          stub_courses(query: suggested_search_count_parameters, course_count: 10)
        end

        it { is_expected.to be(true) }
      end

      context 'there are less than three results and there are no suggested courses found' do
        before do
          stub_courses(query: results_page_parameters, course_count: 2)
          stub_courses(query: suggested_search_count_parameters, course_count: 0)
        end

        it { is_expected.to be(false) }
      end
    end

    context 'searching for courses in a devolved nation' do
      context 'there are less than three results and there are suggested courses found' do
        subject { described_class.new(query_parameters: { 'c' => 'Scotland', 'lat' => '0.1', 'lng' => '2.4', 'rad' => '50' }).suggested_search_visible? }

        before do
          stub_courses(query: results_page_parameters, course_count: 2)
          stub_courses(query: suggested_search_count_parameters, course_count: 10)
        end

        it { is_expected.to be(false) }
      end
    end
  end

  describe '#placement_schools_summary' do
    subject(:placement_schools_summary) { results_view.placement_schools_summary(course) }

    let(:results_view) { described_class.new(query_parameters: parameter_hash) }

    let(:site1) do
      build(:site, latitude: 51.5079, longitude: 0.0877, address1: '1 Foo Street', postcode: 'BAA0NE')
    end

    let(:site_statuses) do
      [build(:site_status, :full_time_and_part_time, site: site1)]
    end

    let(:course) do
      build(
        :course,
        site_statuses: site_statuses,
      )
    end

    context 'site_distance less than 11 miles' do
      let(:parameter_hash) do
        {
          'lat' => '51.5079',
          'lng' => '0.0877',
        }
      end

      it { expect(placement_schools_summary).to eq('Placement schools are near you') }
    end

    context 'site_distance less than 21 miles' do
      let(:parameter_hash) do
        {
          'lat' => '51.6985',
          'lng' => '0.1367',
        }
      end

      it { expect(placement_schools_summary).to eq('Placement schools might be near you') }
    end

    context 'site_distance more than 21 miles' do
      let(:parameter_hash) do
        {
          'lat' => '52',
          'lng' => '0.1367',
        }
      end

      it { expect(placement_schools_summary).to eq('Placement schools might be in commuting distance') }
    end
  end

  describe '#site_distance' do
    let(:results_view) { described_class.new(query_parameters: parameter_hash) }

    context 'closest site distance is greater than 1 mile' do
      let(:parameter_hash) { { 'lat' => '51.4975', 'lng' => '0.1357' } }

      it 'calculates the distance to the closest site, rounding to one decimal place' do
        site1 = build(:site, latitude: 51.5079, longitude: 0.0877, address1: '1 Foo Street', postcode: 'BAA0NE')
        site2 = build(:site, latitude: 54.9783, longitude: 1.6178, address1: '2 Foo Street', postcode: 'BAA0NE')

        course = build(
          :course,
          site_statuses: [
            build(:site_status, :full_time_and_part_time, site: site1),
            build(:site_status, :full_time_and_part_time, site: site2),
          ],
        )

        expect(results_view.site_distance(course)).to eq(2)
      end
    end

    context 'closest site distance is less than 1 mile' do
      let(:parameter_hash) { { 'lat' => '51.4975', 'lng' => '0.1357' } }

      it 'calculates the distance to the closest site, rounding to one decimal place' do
        site1 = build(:site, latitude: 51.4985, longitude: 0.1367, address1: '1 Foo Street', postcode: 'BAA0NE')
        site2 = build(:site, latitude: 54.9783, longitude: 1.6178, address1: '2 Foo Street', postcode: 'BAA0NE')

        course = build(
          :course,
          site_statuses: [
            build(:site_status, :full_time_and_part_time, site: site1),
            build(:site_status, :full_time_and_part_time, site: site2),
          ],
        )

        expect(results_view.site_distance(course)).to eq(0.1)
      end
    end

    context 'closest site distance is less than 0.05 miles' do
      let(:parameter_hash) { { 'lat' => '51.4975', 'lng' => '0.1357' } }

      it 'calculates the distance to the closest site, rounding up to prevent 0.0 miles displaying' do
        site1 = build(:site, latitude: 51.4970, longitude: 0.1358, address1: '1 Foo Street', postcode: 'BAA0NE')

        course = build(
          :course,
          site_statuses: [
            build(:site_status, :full_time_and_part_time, site: site1),
          ],
        )

        expect(results_view.site_distance(course)).to eq(0.1)
      end
    end
  end

  context 'locations' do
    let(:results_view) { described_class.new(query_parameters: parameter_hash) }
    let(:parameter_hash) { { 'lat' => '51.4975', 'lng' => '0.1357' } }
    let(:geocoder) { instance_double(Geokit::LatLng) }

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
    let(:site2) do
      build(:site, latitude: 54.9783, longitude: 1.6178, location_name: 'no address')
    end
    let(:site3) do
      build(
        :site,
        latitude: nil,
        longitude: nil,
        address1: '10 Windy Way',
        address2: 'Witham',
        address3: 'Essex',
        address4: 'UK',
        postcode: 'CM8 2SD',
        location_name: 'no lat long',
      )
    end
    let(:site4) do
      build(
        :site,
        latitude: 51.4985,
        longitude: 0.1367,
        address1: '10 Windy Way',
        address2: 'Witham',
        address3: 'Essex',
        address4: 'UK',
        postcode: 'CM8 2SD',
        location_name: 'suspended',
      )
    end

    let(:course) do
      build(
        :course,
        site_statuses: [
          build(:site_status, :full_time_and_part_time, site: site1),
          build(:site_status, :full_time_and_part_time, site: site2),
          build(:site_status, :full_time_and_part_time, site: site3),
          build(:site_status, :full_time_and_part_time, site: site4, status: 'suspended'),
        ],
      )
    end

    before do
      course
    end

    describe '#nearest_address' do
      it 'returns the address to the nearest site' do
        allow(Geokit::LatLng).to receive(:new).and_return(geocoder)
        allow(geocoder).to receive(:distance_to).with('51.4985,0.1367')
        allow(geocoder).to receive(:distance_to).with(',').and_raise(Geokit::Geocoders::GeocodeError)

        expect(results_view.nearest_address(course)).to eq('10 Windy Way, Witham, Essex, UK, CM8 2SD')
      end
    end

    describe '#nearest_location_name' do
      it 'returns the location name to the nearest site' do
        allow(Geokit::LatLng).to receive(:new).and_return(geocoder)
        allow(geocoder).to receive(:distance_to).with('51.4985,0.1367')
        allow(geocoder).to receive(:distance_to).with(',').and_raise(Geokit::Geocoders::GeocodeError)

        expect(results_view.nearest_location_name(course)).to eq('Main Site')
      end
    end

    describe '#sites_count' do
      it 'returns the running or new sites count' do
        expect(results_view.sites_count(course)).to eq(1)
      end
    end

    describe '#site_distance' do
      it 'returns the running or new sites count' do
        expect(results_view.site_distance(course)).to eq(0.1)
      end
    end
  end

  describe '#sort_options' do
    context 'all other queries' do
      subject(:results_view) { described_class.new(query_parameters: {}).sort_options }

      it {
        expect(results_view).to eq(
          [
            ['Training provider (A-Z)', 0, { "data-qa": 'sort-form__options__ascending' }],
            ['Training provider (Z-A)', 1, { "data-qa": 'sort-form__options__descending' }],
          ],
        )
      }
    end
  end

  describe '#no_results_found?' do
    subject { described_class.new(query_parameters: {}).no_results_found? }

    context 'there are more than three results' do
      before do
        stub_courses(query: results_page_parameters, course_count: 10)
      end

      it { is_expected.to eq(false) }
    end

    context 'there are no results' do
      before do
        stub_courses(query: results_page_parameters, course_count: 0)
      end

      it { is_expected.to eq(true) }
    end
  end

  describe '#number_of_courses_string' do
    subject { described_class.new(query_parameters: {}).number_of_courses_string }

    context 'there are two results' do
      before do
        stub_courses(query: results_page_parameters, course_count: 2)
      end

      it { is_expected.to eq('2 courses') }
    end

    context 'there is one result' do
      before do
        stub_courses(query: results_page_parameters, course_count: 1)
      end

      it { is_expected.to eq('1 course') }
    end

    context 'there are no results' do
      before do
        stub_courses(query: results_page_parameters, course_count: 0)
      end

      it { is_expected.to eq('No courses') }
    end
  end

  describe '#total_pages' do
    subject(:results_view) { described_class.new(query_parameters: query_parameters) }

    let(:parameter_hash) { {} }

    def stub_request_with_meta_count(count)
      stub_request(:get, courses_url)
        .with(query: results_page_parameters)
        .to_return(
          body: { meta: { count: count } }.to_json,
          headers: { "Content-Type": 'application/vnd.api+json; charset=utf-8' },
        )
    end

    context 'where there are no results' do
      before do
        stub_request_with_meta_count(0)
      end

      it 'returns 0 pages' do
        expect(results_view.total_pages).to be(0)
      end
    end

    context 'where there are 10 results' do
      before do
        stub_request_with_meta_count(10)
      end

      it 'returns 1 page' do
        expect(results_view.total_pages).to be(1)
      end
    end

    context 'where there are 20 results' do
      before do
        stub_request_with_meta_count(20)
      end

      it 'returns 2 pages' do
        expect(results_view.total_pages).to be(2)
      end
    end
  end

  describe '#devolved_nation' do
    context 'where country is devolved nation' do
      let(:results_view) { described_class.new(query_parameters: { 'c' => 'Wales' }) }

      it 'returns true' do
        expect(results_view.devolved_nation?).to be true
      end
    end

    context 'where country is not a devolved nation' do
      let(:results_view) { described_class.new(query_parameters: { 'c' => 'Italy' }) }

      it 'returns false' do
        expect(results_view.devolved_nation?).to be false
      end
    end

    context 'where country is England' do
      let(:results_view) { described_class.new(query_parameters: { 'c' => 'England' }) }

      it 'returns false' do
        expect(results_view.devolved_nation?).to be false
      end
    end

    context 'where country is nil' do
      let(:results_view) { described_class.new(query_parameters: { 'c' => 'nil' }) }

      it 'returns false' do
        expect(results_view.devolved_nation?).to be false
      end
    end
  end
end
