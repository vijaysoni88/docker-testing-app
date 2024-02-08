# app/helpers/application_helper.rb

module ApplicationHelper
  require 'open-uri'

  def google_maps_image(start_address, end_address, polylines)
    # Calculate bounding box to include all coordinates of polylines
    bbox = calculate_bounding_box(polylines)

    # Adjust center and zoom level based on bounding box
    center_lat = (bbox[1] + bbox[3]) / 2
    center_lng = (bbox[0] + bbox[2]) / 2
    zoom = calculate_zoom(bbox)

    # Construct the Google Maps Static API URL
    google_maps_api_key = Rails.application.credentials.staging[:google_maps_api_key]
    size = '1800x1600'
    map_url = "https://maps.googleapis.com/maps/api/staticmap?key=#{google_maps_api_key}&size=#{size}&center=#{center_lat},#{center_lng}&zoom=#{zoom}"

    # Add polylines to the map image URL
    polylines.each do |polyline|
      map_url += "&path=enc:#{polyline}"
    end

    # Specify the directory for saving the image
    image_path = Rails.root.join('public', 'google_maps_image.png')

    begin
      # Download the map image from the Google Maps Static API
      open(image_path, 'wb') do |file|
        file << URI.parse(map_url).read
      end
    rescue OpenURI::HTTPError => e
      Rails.logger.error "Error downloading map image: #{e.message}"
      return nil
    end

    return image_path
  end

  private

  def calculate_bounding_box(polylines)
    min_lat, min_lng, max_lat, max_lng = nil, nil, nil, nil

    polylines.each do |polyline|
      coordinates = decode_polyline(polyline)
      coordinates.each do |lat, lng|
        min_lat = lat if min_lat.nil? || lat < min_lat
        min_lng = lng if min_lng.nil? || lng < min_lng
        max_lat = lat if max_lat.nil? || lat > max_lat
        max_lng = lng if max_lng.nil? || lng > max_lng
      end
    end

    [min_lng, min_lat, max_lng, max_lat]
  end

  def decode_polyline(polyline)
    coordinates = []
    index = lat = lng = dlat = dlng = 0
  
    while index < polyline.length
      change = factor = 1
      temp_lat = temp_lng = 0
  
      loop do
        break if index >= polyline.length
  
        shift = result = 0
  
        loop do
          break if index >= polyline.length || (shift += 5) > 35
          result |= (polyline[index].ord - 63 & 0x1F) << shift
          index += 1
        end
  
        temp = (result & 1) == 1 ? ~(result >> 1) : result >> 1
  
        if change == 1
          dlat += temp
          change = 0
        else
          dlng += temp
          coordinates << [(lat += dlat * 1e-5).round(5), (lng += dlng * 1e-5).round(5)]
          dlat = dlng = 0
          change = 1
        end
      end
    end
  
    coordinates
  end

  def calculate_zoom(bbox)
    # Calculate zoom level based on bounding box
    # You may need to adjust this calculation based on your requirements
    max_zoom = 21
    world_width = 256
    aspect_ratio = 1.0 # You may adjust this if your map image aspect ratio is different
    pixel_width = 1800
    latitude_diff = bbox[3] - bbox[1]
    longitude_diff = bbox[2] - bbox[0]

    degreesPerPixelX = longitude_diff / pixel_width
    degreesPerPixelY = latitude_diff / (pixel_width * aspect_ratio)

    zoomX = Math.log2(360 / degreesPerPixelX)
    zoomY = Math.log2(170 / degreesPerPixelY)

    [zoomX, zoomY, max_zoom].min.floor
  end
end
