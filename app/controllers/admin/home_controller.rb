require 'zip'

class Admin::HomeController < ApplicationController
  before_action :authenticate_user!
  before_action :check_admin_role

  def index
    @job_sheet = JobSheet.last
    if  params[:upload].present? || params[:regions]
      kmz_file = Kmz.last
      kmz_contents = kmz_file.kmz_attachment
      all_locations = extract_lat_long_region(kmz_contents)
      selected_regions = params[:regions]
     
      if selected_regions.present?
        @locations = all_locations.select { |location| selected_regions.include?(location[:region]) }
      else
        @locations = all_locations
      end
    elsif params[:create_barrier].present?
      coordinates_with_names = Barrier.pluck(:latitude, :longitude, :name)
      result_with_names = coordinates_with_names.map do |lat, long, name|
        {
          latitude: lat,
          longitude: long,
          region: name
        }
      end
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
    kmz_file = Kmz.last
    kmz_contents = kmz_file.kmz_attachment
    all_locations = extract_lat_long_region(kmz_contents)
    if all_locations.present?
      @locations = all_locations.uniq { |location| location[:region] }
    else
      @locations = []
    end
    render json: @locations
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
    # start_location =  params[:start_location]
    # end_location = params[:end_location]
 
    # response = HTTParty.get('https://maps.googleapis.com/maps/api/directions/json', {
    #   query: {
    #     origin: start_location,
    #     destination: end_location,
    #     key: 'AIzaSyDa126WU'
    #   }
    # })

    # render json: response.body
    # binding.pry
    directions_response = File.read('/home/bacancy/rails_work/AB-CRANE-HIRE/test/directions_response.json')
 
    render json: directions_response
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
end
