require 'zip'

class Admin::KmzController < ApplicationController
  def upload
    uploaded_file = params[:kmz_file]
    kmz_file_instance = Kmz.save_uploaded_kmz(uploaded_file)

    respond_to do |format|
      format.html { redirect_to admin_home_index_path(extracted_data: 'your_data_here'), notice: 'KMZ file data extracted successfully.' }
      format.js   # Add this line if you want to respond with JavaScript (e.g., update the map)
    end
  end

  private

  # def extract_lat_long_region(kmz_contents)
  #   data = []

  #   # Use RubyZip to extract KML file from KMZ contents
  #   Zip::File.open_buffer(kmz_contents) do |zip_file|
  #     zip_file.each do |entry|
  #       # Check if the entry is the KML file
  #       if File.extname(entry.name) == '.kml'
  #         kml_data = entry.get_input_stream.read
  #         doc = Nokogiri::XML(kml_data)

  #         # Iterate through Placemark elements
  #         doc.xpath('//kml:Placemark', 'kml' => 'http://www.opengis.net/kml/2.2').each do |placemark|
  #           coordinates = placemark.at_xpath('.//kml:Point/kml:coordinates', 'kml' => 'http://www.opengis.net/kml/2.2')&.text

  #           if coordinates
  #             # Split the coordinates into latitude, longitude, and altitude
  #             longitude, latitude, _ = coordinates.split(',')

  #             # Assuming you have some way to determine the region, replace 'determine_region_method' with the actual method
  #             region = determine_region_method(placemark)

  #             # Add the data to the array
  #             data << { latitude: latitude.to_f, longitude: longitude.to_f, region: region }
  #           end
  #         end
  #       end
  #     end
  #   end

  #   # Now you have the latitudes, longitudes, and regions extracted from the KML file
  #   data
  # end

  # def determine_region_method(placemark)
  #   # Replace this method with your logic to determine the region based on the placemark
  #   # For example, you might extract the region from another element in the KML
  #   # or based on some other criteria specific to your data.
  #   # The return value should be the determined region.
  #   # Example:
  #   # placemark.at_xpath('.//kml:RegionName', 'kml' => 'http://www.yournamespace.com')&.text
  # end
end
