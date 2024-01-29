# app/helpers/application_helper.rb

module ApplicationHelper
  require 'open-uri'

  def google_maps_image(start_address, end_address)
    # Get the bounding box
    bbox = bbox_for_addresses(start_address, end_address)

    # Construct the Google Maps Static API URL
    google_maps_api_key = 'AIzaSyDa126WURrLx1_2G40zPfXQB5tFnENZNg0'
    size = '800x600'
    map_url = "https://maps.googleapis.com/maps/api/staticmap?key=#{google_maps_api_key}&size=#{size}&center=#{bbox[1]},#{bbox[0]}&zoom=13"

    # Specify the directory for saving the image
    image_path = Rails.root.join('public', 'google_maps_image.png')

    # Download the map image from the Google Maps Static API
    open(image_path, 'wb') do |file|
      file << URI.parse(map_url).read
    end

    return image_path
  end

  private

  def bbox_for_addresses(start_address, end_address)
    # Replace this logic with a proper geocoding solution
    start_coordinates = Geocoder.search(start_address).first.coordinates
    end_coordinates = Geocoder.search(end_address).first.coordinates
  
    min_lat = [start_coordinates[0], end_coordinates[0]].min
    min_lon = [start_coordinates[1], end_coordinates[1]].min
    max_lat = [start_coordinates[0], end_coordinates[0]].max
    max_lon = [start_coordinates[1], end_coordinates[1]].max
  
    # Return the bounding box as an array of numeric values
    [min_lon.to_f, min_lat.to_f, max_lon.to_f, max_lat.to_f]
  end  
end
