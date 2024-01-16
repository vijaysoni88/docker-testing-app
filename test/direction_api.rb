require 'net/http'
require 'json'

api_key = 'AIzaSyDa126WURrLx1'
origin_address = 'New York, NY'
destination_address = 'Los Angeles, CA'

url = URI("https://maps.googleapis.com/maps/api/directions/json?origin=#{origin_address}&destination=#{destination_address}&key=#{api_key}")

response = Net::HTTP.get(url)
directions_data = JSON.parse(response)

# Use absolute paths based on your project structure
project_root = '/home/bacancy/rails_work/AB-CRANE-HIRE'
test_directory = File.join(project_root, 'test')
file_path = File.join(test_directory, 'directions_response.json')

# Check if the file exists before writing to it
puts "#{file_path}  direction path"

if !File.exist?(file_path)
  File.open(file_path, 'w') { |file| file.write(JSON.pretty_generate(directions_data)) }
else
  puts "File '#{file_path}' already exists. Not overwriting."
end
