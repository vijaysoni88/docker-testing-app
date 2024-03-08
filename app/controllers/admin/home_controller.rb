require 'zip'
require 'polylines'

class Admin::HomeController < ApplicationController

  before_action :authenticate_user!
  before_action :check_admin_role

  def index
    if params[:upload].present? || params[:regions]
      all_locations = get_kmz_extract_lat_long_region
      selected_regions = params[:regions]
     
      if selected_regions.present?
        @locations = get_locations(selected_regions, all_locations)
        @selected_regions = selected_regions

        user = User.find_by(id: current_user.id)

        user.locations = @locations
        user.save
      else
        @selected_regions = []
        @locations = all_locations
      end
    elsif params[:create_barrier].present?
      coordinates_with_names = Barrier.pluck(:latitude, :longitude, :name)
      result_with_names = format_barriers_response(coordinates_with_names)
      @selected_regions = []
      @locations =  result_with_names
    else
      @selected_regions = []
      @locations = current_user.locations.present? ? hash_response(current_user.locations) : []
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
    render 'shared/job_sheet'
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
    result = nil
    retry_count = 0
  
    begin
      result = Geocoder.search(params[:address]).first
    rescue
      if retry_count < 3  # Retry up to 3 times
        retry_count += 1
        sleep(1)  # Wait for 1 second before retrying
        retry
      else
        render json: { error: 'Geocoding failed after multiple attempts' }, status: :unprocessable_entity
        return
      end
    end
  
    if result.nil?
      render json: { error: 'Geocoding failed: no result found' }, status: :unprocessable_entity
      return
    end
  
    coordinates = { latitude: result.latitude, longitude: result.longitude }
    render json: coordinates
  end  

  def get_directions
    start_location =  params[:start_location]
    middle_location = params[:middle_location]
    end_location = params[:end_location]

    if params[:barriers_selected].present? || current_user.locations.present?
      if params[:barriers_selected].present?
        @barriers_selected = params[:barriers_selected]
      else
        # Assuming current_user.locations is an array of hashes
        @barriers_selected = current_user.locations.map { |location| location["region"] }.uniq
      end

      all_locations = get_kmz_extract_lat_long_region
      barrier_coordinates = get_locations(@barriers_selected, all_locations)
      barrier_coordinates = barrier_coordinates.map { |entry| [entry[:latitude], entry[:longitude]] }
    else
      barrier_coordinates = []
    end

    all_routes = []

    if start_location.present? && end_location.present?
      @response_start_to_end = fetch_route(start_location, end_location)
      routes = @response_start_to_end['routes']
      all_routes.concat(routes)
    end
  
    if middle_location.present? && end_location.present?
      @response_from_middle_to_end = fetch_route(middle_location, end_location)
      routes = @response_from_middle_to_end['routes']
      all_routes.concat(routes)
    end

    if start_location.present? && middle_location.present?
      @response_start_to_middle = fetch_route(start_location, middle_location)
      routes = @response_start_to_middle['routes']
      all_routes.concat(routes)
    end
    
    response = [@response_start_to_end,  @response_start_to_middle, @response_from_middle_to_end].compact.flatten


    # Check if there is a Response record present

    response_data = Response.where(response_type: "route").last

    if response_data.present?
      # Update the existing Response record
      response_data.response_type = "route"
      response_data.json_file.attach(io: StringIO.new(response.to_json), filename: 'response.json')
      response_data.save
    else
      # Initialize a new Response record
      new_response = Response.new
      new_response.response_type = "route"
      new_response.json_file.attach(io: StringIO.new(response.to_json), filename: 'response.json')
      new_response.save
    end
  
    render json: { status: 'OK', routes: all_routes, barriers: barrier_coordinates }
  end

  def save_directions
    # Retrieve the file from the request
    directions_file = params[:directions_file]

    # Create a new ActiveStorage blob
    blob = ActiveStorage::Blob.create_and_upload!(
      io: directions_file,
      filename: directions_file.original_filename,
      content_type: directions_file.content_type
    )

    # Check if a Response record already exists
    response =  Response.where(response_type: "direction").last
   
    if response.present?
      # If a response exists, update it with the new blob
      response.response_type = "direction"
      response.json_file.attach(blob)
    else
      # If no response exists, create a new one and attach the blob
      response = Response.new
      response.response_type = "direction"
      response.json_file.attach(blob)
    end

    if response.save
      render json: { message: 'Directions file saved successfully' }, status: :ok
    else
      render json: { error: 'Failed to save directions file' }, status: :unprocessable_entity
    end
  end

  private

  def fetch_route(origin, destination)
    response = HTTParty.get('https://maps.googleapis.com/maps/api/directions/json', {
      query: {
        origin: origin,
        destination: destination,
        key: Rails.application.credentials.staging[:google_maps_api_key],
        alternatives: true
      }
    })
    JSON.parse(response.body)
  end

  def check_admin_role
    unless current_user&.admin?
      redirect_to user_home_index_path, alert: 'Access Denied. You must be an admin to perform this action.'
    end
  end

  def get_kmz_extract_lat_long_region
    kmz_file = Kmz.last
    kmz_attachment = kmz_file.kmz_attachment
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
    all_locations = get_kmz_extract_lat_long_region
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

  def hash_response(input_data)
    input_data.map do |hash|
      {
        latitude: hash["latitude"],
        longitude: hash["longitude"],
        region: hash["region"]
      }
    end
  end

  def get_locations(selected_regions, all_locations)
    gov_data = []
    permanent_barries = Barrier.where(name: selected_regions)

    permanent_regions = permanent_barries.pluck(:name)
    gov_regions = selected_regions - permanent_regions
    
    gov_data = all_locations.select { |location| gov_regions.include?(location[:region]) } unless gov_regions.empty?

    permanent_barries = permanent_barries.pluck(:latitude, :longitude, :name)
    permanent_data = format_barriers_response(permanent_barries)

    @selected_regions = selected_regions

    locations =  permanent_data + gov_data
    locations
  end
end
