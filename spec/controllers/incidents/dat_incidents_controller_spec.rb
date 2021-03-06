require 'spec_helper'

describe Incidents::DatIncidentsController, :type => :controller do
  include LoggedIn



  # This should return the minimal set of attributes required to create a valid
  # Incidents::DatIncident. As you add validations to Incidents::DatIncident, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) { {  } }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # Incidents::DatIncidentsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "#new" do

    before(:each) do
      grant_role! :submit_incident_report
    end

    it "should redirect if there is a valid dat incident already" do
      grant_role! :incidents_admin
      incident = FactoryGirl.create :incident, chapter: @person.chapter
      dat = FactoryGirl.create :dat_incident, incident: incident

      get :new, incident_id: incident.to_param, chapter_id: incident.chapter.to_param

      expect(response).to redirect_to(action: :edit, incident_id: incident.to_param)
    end

    it "should render under an incident" do
      incident = FactoryGirl.create :incident, chapter: @person.chapter
      get :new, incident_id: incident.to_param, chapter_id: incident.chapter.to_param
      expect(response).to be_success
    end

  end

  describe "#edit" do
    before(:each) do
      grant_role! :incidents_admin
    end
    before(:each) do
      @incident = FactoryGirl.create :incident, chapter: @person.chapter
      @dat = FactoryGirl.create :dat_incident, incident: @incident
    end
    it "should render under an incident" do
      get :edit, incident_id: @incident.to_param, chapter_id: @incident.chapter.to_param
    end
    it "should not render standalone" do
      expect {
        get :edit, id: @dat.to_param, chapter_id: @incident.chapter.to_param
      }.to raise_error
    end
  end

  context "with an existing incident" do  
    before(:each) do
      grant_role! :submit_incident_report
    end

    before(:each) do
      @incident = FactoryGirl.create :incident, chapter: @person.chapter
      @dat = FactoryGirl.build :dat_incident
      @lead = FactoryGirl.create :person
      @vehicle = FactoryGirl.create :vehicle
    end

    before(:each) { allow(Incidents::Notifications::Notification).to receive :create_for_event }

    let(:create_attrs) {
      attrs = @dat.attributes
      attrs.merge!({'comfort_kits' => 10, 'blankets' => 50})
      attrs[:incident_attributes] = {id: @incident.id}
      attrs[:incident_attributes][:team_lead_attributes] = {person_id: @lead.id, role: 'team_lead', response: 'available'}
      attrs[:vehicle_ids] = [@vehicle.id]
      attrs
    }

    it "should allow creating" do
      expect {
        post :create, incident_id: @incident.to_param, chapter_id: @incident.chapter.to_param, incidents_dat_incident: create_attrs
        expect(response).to redirect_to(incidents_chapter_incident_path(@incident.chapter, @incident))
      }.to change(Incidents::DatIncident, :count).by(1)
    end
    it "should not change incident attributes" do
      create_attrs[:incident_attributes].merge!( {:incident_number => "15-555"})
      expect {
        post :create, incident_id: @incident.to_param, chapter_id: @incident.chapter.to_param, incidents_dat_incident: create_attrs
        expect(response).to redirect_to(incidents_chapter_incident_path(@incident.chapter, @incident))
      }.to_not change{@incident.reload.incident_number}
    end
    xit "should notify the report was filed" do
      expect(Incidents::Notifications::Notification).to receive(:create_for_event).with(anything, 'incident_report_filed', {is_new: true})
      create_attrs[:incident_attributes][:status] = 'closed'
      post :create, incident_id: @incident.to_param, chapter_id: @incident.chapter.to_param, incidents_dat_incident: create_attrs
    end
  end

  context "updating an existing report" do
    before(:each) do
      @incident = FactoryGirl.create :closed_incident, chapter: @person.chapter
      grant_role! :submit_incident_report
    end

    it "should notify the report was filed" do
      expect(Incidents::Notifications::Notification).to receive(:create_for_event).with(anything, 'incident_report_filed', {is_new: false})
      put :update, incident_id: @incident.to_param, chapter_id: @incident.chapter.to_param, incidents_dat_incident: {incident_attributes: {num_adults: 3}}
      expect(response).to redirect_to(incidents_chapter_incident_path(@incident.chapter, @incident))
    end
  end
end
