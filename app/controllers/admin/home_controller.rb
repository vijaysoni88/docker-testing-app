require 'zip'

class Admin::HomeController < ApplicationController
  before_action :authenticate_user!
  before_action :check_admin_role

  def index
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

  def fetch_regions
    kmz_file = Kmz.last
    kmz_contents = kmz_file.kmz_attachment
    all_locations = extract_lat_long_region(kmz_contents)
    @locations = all_locations.uniq { |location| location[:region] }
 
    render json: @locations
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
