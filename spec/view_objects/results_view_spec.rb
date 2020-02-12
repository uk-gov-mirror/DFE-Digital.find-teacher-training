require "rails_helper"

RSpec.describe ResultsView do
  let(:query_parameters) { ActionController::Parameters.new(parameter_hash) }

  let(:default_parameters) do
    {
      "qualifications" => "QtsOnly,PgdePgceWithQts,Other",
      "fulltime" => "False",
      "parttime" => "False",
      "hasvacancies" => "True",
      "senCourses" => "False",
    }
  end

  let(:subject_areas) do
    [
      build(:subject_area, subjects: [
        build(:subject, :primary, id: 1),
        build(:subject, :biology, id: 2),
        build(:subject, :english, id: 3),
        build(:subject, :mathematics, id: 4),
        build(:subject, :french, id: 5),
        ]),
      build(:subject_area, :secondary),
    ]
  end

  before do
    stub_api_v3_resource(
      type: SubjectArea,
      resources: subject_areas,
      include: [:subjects],
    )
  end

  describe "query_parameters_with_defaults" do
    subject { described_class.new(query_parameters: query_parameters).query_parameters_with_defaults }

    context "params are empty" do
      let(:parameter_hash) { {} }

      it { is_expected.to eq(default_parameters) }
    end

    context "query_parameters have qualifications set" do
      let(:parameter_hash) { { "qualifications" => "Other" } }

      it { is_expected.to eq(default_parameters.merge(parameter_hash)) }
    end

    context "query_parameters have fulltime set" do
      let(:parameter_hash) { { "fulltime" => "True" } }

      it { is_expected.to eq(default_parameters.merge(parameter_hash)) }
    end

    context "query_parameters have parttime set" do
      let(:parameter_hash) { { "parttime" => "True" } }

      it { is_expected.to eq(default_parameters.merge(parameter_hash)) }
    end

    context "query_parameters have hasvacancies set" do
      let(:parameter_hash) { { "hasvacancies" => "False" } }

      it { is_expected.to eq(default_parameters.merge(parameter_hash)) }
    end

    context "query_parameters have senCourses set" do
      let(:parameter_hash) { { "senCourses" => "False" } }

      it { is_expected.to eq(default_parameters.merge(parameter_hash)) }
    end

    context "parameters without default present in query_parameters" do
      let(:parameter_hash) { {  "lat" => "52.3812321", "lng" => "-3.9440235" } }

      it { is_expected.to eq(default_parameters.merge(parameter_hash)) }
    end

    context "rails specific parameters are present" do
      let(:parameter_hash) { { "utf8" => true, "authenticity_token" => "booyah" } }

      it "filters them out" do
        expect(subject).to eq(default_parameters.merge({}))
      end
    end
  end

  describe "filter_path_with_unescaped_commas" do
    subject { described_class.new(query_parameters: default_parameters).filter_path_with_unescaped_commas("/test") }

    it "appends an unescaped querystring to the passed path" do
      expected_path = "/test?qualifications=QtsOnly,PgdePgceWithQts,Other&fulltime=False&parttime=False&hasvacancies=True&senCourses=False"
      expect(subject).to eq(expected_path)
    end
  end

  describe "#qts_only?" do
    let(:results_view) { described_class.new(query_parameters: parameter_hash) }

    context "when the hash includes 'QTS only'" do
      let(:parameter_hash) { { "qualifications" => "QtsOnly,PgdePgceWithQts" } }

      it "returns true" do
        expect(results_view.qts_only?).to be_truthy
      end
    end

    context "when the hash does not include 'QTS only'" do
      let(:parameter_hash) { { "qualifications" => "Other" } }

      it "returns false" do
        expect(results_view.qts_only?).to be_falsy
      end
    end
  end

  describe "#pgce_or_pgde_with_qts?" do
    let(:results_view) { described_class.new(query_parameters: parameter_hash) }

    context "when the hash includes 'PGCE (or PGDE) with QTS'" do
      let(:parameter_hash) { { "qualifications" => "QtsOnly,PgdePgceWithQts" } }

      it "returns true" do
        expect(results_view.pgce_or_pgde_with_qts?).to be_truthy
      end
    end

    context "when the hash does not include 'PGCE (or PGDE) with QTS'" do
      let(:parameter_hash) { { "qualifications" => "Other" } }

      it "returns false" do
        expect(results_view.pgce_or_pgde_with_qts?).to be_falsy
      end
    end
  end

  describe "#other_qualifications?" do
    let(:results_view) { described_class.new(query_parameters: parameter_hash) }

    context "when the hash includes 'Further Education (PGCE or PGDE without QTS)'" do
      let(:parameter_hash) { { "qualifications" => "QtsOnly,Other" } }

      it "returns true" do
        expect(results_view.other_qualifications?).to be_truthy
      end
    end

    context "when the hash does not include 'Further Education (PGCE or PGDE without QTS)'" do
      let(:parameter_hash) { { "qualifications" => "QtsOnly" } }

      it "returns false" do
        expect(results_view.other_qualifications?).to be_falsy
      end
    end
  end

  describe "#all_qualifications?" do
    let(:results_view) { described_class.new(query_parameters: parameter_hash) }

    context "when all selected'" do
      let(:parameter_hash) { { "qualifications" => "QtsOnly,PgdePgceWithQts,Other" } }

      it "returns true" do
        expect(results_view.all_qualifications?).to be_truthy
      end
    end

    context "when not all selected" do
      let(:parameter_hash) { { "qualifications" => "QtsOnly" } }

      it "returns false" do
        expect(results_view.all_qualifications?).to be_falsy
      end
    end
  end

  describe "#send_courses?" do
    let(:results_view) { described_class.new(query_parameters: parameter_hash) }

    context "when the senCourses is True" do
      let(:parameter_hash) { { "senCourses" => "True" } }

      it "returns true" do
        expect(results_view.send_courses?).to be_truthy
      end
    end

    context "when the senCourses is nil" do
      let(:parameter_hash) { {} }

      it "returns false" do
        expect(results_view.send_courses?).to be_falsy
      end
    end
  end

  describe "#number_of_subjects_selected" do
    let(:results_view) { described_class.new(query_parameters: parameter_hash) }

    context "query_parameters don't have subjects set" do
      let(:parameter_hash) { {} }

      it "returns the number of all subjects" do
        expect(results_view.number_of_subjects_selected).to eq(5)
      end
    end

    context "query_parameters have subjects set" do
      let(:parameter_hash) { { "subjects" => "1,2,3" } }

      it "returns the number of all subjects" do
        expect(results_view.number_of_subjects_selected).to eq(3)
      end
    end
  end

  describe "#number_of_extra_subjects" do
    let(:results_view) { described_class.new(query_parameters: parameter_hash) }

    let(:parameter_hash) { { "subjects" => "1,2,3,4,5" } }

    it "returns the number of the extra subjects" do
      expect(results_view.number_of_extra_subjects).to eq(1)
    end
  end
end