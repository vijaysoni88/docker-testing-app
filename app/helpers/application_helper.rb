# app/helpers/application_helper.rb

module ApplicationHelper
    require 'webshot'
    def openstreetmap_image(start_address, end_address)
        size = '600x300' # Adjust the size as needed
        bbox = bbox_for_addresses(start_address, end_address)
        url = "https://www.openstreetmap.org/export/embed.html?bbox=#{bbox}&layer=mapnik"
      
        # Specify the directory for saving the image
        image_path = Rails.root.join('public', 'map_image.png')

        # Use webshot to take a screenshot of the OpenStreetMap
        
        webshot = Webshot::Screenshot.instance
        webshot.capture("http://www.google.com/", image_path, width: 800)  # Adjust width as needed
      
        return image_path
      end
    # def openstreetmap_image(start_address, end_address)
    #     size = '600x300' # Adjust the size as needed
    #     bbox = bbox_for_addresses(start_address, end_address)
    #     url = "https://www.openstreetmap.org/export/embed.html?bbox=#{bbox}&layer=mapnik"

    #     # Specify the directory for saving the image
    #     directory = "#{Rails.root}/tmp"
      
    #     # Ensure the directory exists or create it
    #     FileUtils.mkdir_p(directory) unless File.directory?(directory)
      
    #     # Specify a file path when calling to_file
    #     # image_path = File.join(directory, 'map_image.png')
    #     image_path = Rails.root.join('public', 'map_image.png')
      
    #     # Use imgkit to take a screenshot of the OpenStreetMap
    #     imgkit = IMGKit.new(url, quality: 50, width: 800)  # Adjust width as needed
      
    #     # Save the image directly using .to_file
    #     imgkit.to_file(image_path)
      
    #     return image_path
    # end
      
    private
  
    def bbox_for_addresses(start_address, end_address)
      # Calculate bounding box based on start and end addresses
      # Replace this logic with your own bounding box calculation if needed
      # This is just a simple example
      "#{start_address.split(',').reverse.join(',')};#{end_address.split(',').reverse.join(',')}"
    end
  end
  