require 'zip'
require 'polylines'

class Admin::HomeController < ApplicationController

  before_action :authenticate_user!
  before_action :check_admin_role

  def index
    if params[:upload].present? || params[:regions]
      kmz_file = Kmz.last
      kmz_contents = kmz_file.kmz_attachment
      all_locations = extract_lat_long_region(kmz_contents)
      selected_regions = params[:regions]
     
      if selected_regions.present?
        gov_data = []
        permanent_barries = Barrier.where(name: selected_regions)
        permanent_regions = permanent_barries.pluck(:name)
        gov_regions = selected_regions - permanent_regions

        gov_data = all_locations.select { |location| gov_regions.include?(location[:region]) } unless gov_regions.empty?

        permanent_barries = permanent_barries.pluck(:latitude, :longitude, :name)
        permanent_data = format_barriers_response(permanent_barries)

        @locations =  permanent_data + gov_data
      else
        @locations = all_locations
      end
    elsif params[:create_barrier].present?
      coordinates_with_names = Barrier.pluck(:latitude, :longitude, :name)
      result_with_names = format_barriers_response(coordinates_with_names)
      @locations =  result_with_names
    else
      @locations = []
    end

    render 'index'
  end
  
  def barriers
    render 'barriers'
  end

  def route_setting
    render 'route_setting'
  end

  def job_sheet
    @directions = params[:start_location]
    render 'job_sheet'
  end

  def add_barriers
    @barrier = Barrier.new(barrier_params)

    respond_to do |format|
      if @barrier.save
        format.js   # Render create.js.erb for AJAX response on success
      else
        format.js { render 'admin/barriers/error', status: :unprocessable_entity } # Render error.js.erb on failure
      end
    end
  end

  def fetch_regions
    if params[:checkboxes].present?
      if (params[:checkboxes].include?("permanent") && params[:checkboxes].include?("government"))
        permanent_barriers = fetch_regions_for_permanent_barriers
        gov_barriers = fetch_regions_for_government_barriers
        @locations = permanent_barriers + gov_barriers
      elsif params[:checkboxes].include?("permanent")
        @locations = fetch_regions_for_permanent_barriers
      elsif params[:checkboxes].include?("government")
        @locations = fetch_regions_for_government_barriers
      else
        @locations = []
      end
    else
      @locations = []
    end

    render json: @locations
  end

  def selected_regions
    
  end

  def geocode
    try = 0
    begin
      yield try
    rescue *exceptions => exc
      try += 1
      try <= 3 ? retry : raise
    end
  end

  def geocode
    result = Geocoder.search(params[:address]).first
    coordinates = { latitude: result.latitude, longitude: result.longitude }

    render json: coordinates
  end

  def get_directions
    start_location =  params[:start_location]
    end_location = params[:end_location]

    barriers = Barrier.where(enabled: nil)
    barrier_coordinates = barriers.map { |barrier| [barrier.latitude, barrier.longitude] }
 
    # response = HTTParty.get('https://maps.googleapis.com/maps/api/directions/json', {
    #   query: {
    #     origin: start_location,
    #     destination: end_location,
    #     key: 'API_key',
    #     alternatives: true
    #   }
    # })

    # render json: response.body

    directions_response = File.read('/home/bacancy/rails_work/AB-CRANE-HIRE/test/directions_response.json')
    directions_data = JSON.parse(directions_response)

    # Process the response and include all routes, regardless of barriers
    all_routes = directions_data['routes']
  
    render json: { status: 'OK', routes: all_routes, barriers: barrier_coordinates }
  end  

  private

  def check_admin_role
    unless current_user&.admin?
      redirect_to user_home_index_path, alert: 'Access Denied. You must be an admin to perform this action.'
    end
  end

  def extract_lat_long_region(kmz_attachment)
    data = []
    # Assuming kmz_attachment is an instance of ActiveStorage::Attached::One
    kmz_file = kmz_attachment.download
  
    # Use RubyZip to extract KML file from KMZ archive
    Zip::File.open_buffer(kmz_file) do |zip_file|
      zip_file.each do |entry|
        # Check if the entry is the KML file
        if File.extname(entry.name) == '.kml'
          kml_data = entry.get_input_stream.read
          doc = Nokogiri::XML(kml_data)
          # Iterate through Placemark elements
          doc.xpath('//kml:Placemark', 'kml' => 'http://www.opengis.net/kml/2.2').each do |placemark|
            coordinates = placemark.at_xpath('.//kml:Point/kml:coordinates', 'kml' => 'http://www.opengis.net/kml/2.2')&.text
  
            if coordinates
              # Split the coordinates into latitude, longitude, and altitude
              longitude, latitude, _ = coordinates.split(',')

              # Assuming you have some way to determine the region, replace 'determine_region_method' with the actual method
              region = determine_region_method(placemark)
  
              data << {latitude: latitude.to_f, longitude: longitude.to_f, region: region}
            end
          end
        end
      end
    end
  
    # Now you have the latitudes, longitudes, and regions extracted from the KML file
    data
  end

  def determine_region_method(placemark)
      structure_name = placemark.at_xpath('.//kml:SimpleData[@name="Structure Name"]', 'kml' => 'http://www.opengis.net/kml/2.2')&.text
      tmr_district = placemark.at_xpath('.//kml:SimpleData[@name="TMR District"]', 'kml' => 'http://www.opengis.net/kml/2.2')&.text
  
      return tmr_district if structure_name && tmr_district
      ''
  end

  def fetch_regions_for_permanent_barriers
    Barrier.all.map do |barrier|
      {
        latitude: barrier.latitude,
        longitude: barrier.longitude,
        region: barrier.name
      }
    end
  end

  def fetch_regions_for_government_barriers
    kmz_file = Kmz.last
    kmz_contents = kmz_file.kmz_attachment
    all_locations = extract_lat_long_region(kmz_contents)
    all_locations.uniq { |location| location[:region] }
  end

  def format_barriers_response(data)
    data.map do |lat, long, name|
      {
        latitude: lat,
        longitude: long,
        region: name
      }
    end
  end
end
