require 'zip'

class Admin::HomeController < ApplicationController
  before_action :authenticate_user!
  before_action :check_admin_role

  def index
    if flash.present?
      kmz_file = Kmz.find_by(id: flash['upload_result']['entries'].first['data'])
      kmz_contents = kmz_file.kmz_attachment
      @lat_long_region_data = extract_lat_long_region(kmz_contents)
    end
    render 'index'
  end

  def barriers
    render 'barriers'
  end

  private  

  def check_admin_role
    unless current_user&.admin?
      redirect_to user_home_index_path, alert: 'Access Denied. You must be an admin to perform this action.'
    end
  end

  def extract_lat_long_region(kmz_attachment)
    latitudes = []
    longitudes = []
    regions = []
  
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
  
              # Add the data to the arrays
              latitudes << latitude.to_f
              longitudes << longitude.to_f
              regions << region
            end
          end
        end
      end
    end
  
    # Now you have the latitudes, longitudes, and regions extracted from the KML file
    { latitudes: latitudes, longitudes: longitudes, regions: regions }
  end

  def determine_region_method(placemark)
    # Implement your logic to determine the region based on the placemark
    # For example, you might extract information from the placemark or perform some other calculation
    # Replace the following line with your actual implementation
    'India'
  end
end
