class Admin::JobSheetsController < ApplicationController
  include ApplicationHelper

  def index
    @job_sheets = JobSheet.all
  end

  def new
    @job_sheet = JobSheet.new
  end

  def create
    @job_sheet = JobSheet.new(job_sheet_params)

    if @job_sheet.save
      redirect_to admin_job_sheets_path, notice: 'Job Sheet created successfully.'
    else
      render :new
    end
  end
  
  def generate_pdf
    @job_sheet = JobSheet.create!(job_sheet_params)
    
    data = fetch_directions

    response = Response.where(response_type: "direction").last
    json_data = response.json_file.download

    directions_data = JSON.parse(json_data)

    if data[:success]
      @directions = directions_data.split('<strong><h2>DIRECTION<h2/></strong>').reject(&:empty?).map { |route| route.split('<br>').reject(&:empty?).map(&:strip) }

      @route_polylines = data[:data].map { |route| route[:polyline] }
    else
      @directions = []
      @route_polylines = []
    end

    map_image_path = google_maps_image(@job_sheet.start_address, @job_sheet.end_address, @route_polylines)

    # Specify the destination directory within assets/images
    destination_directory = Rails.root.join('app', 'assets', 'images')

    # Ensure the destination directory exists or create it
    FileUtils.mkdir_p(destination_directory) unless File.directory?(destination_directory)

    # Move the image to the destination directory
    destination_path = File.join(destination_directory, 'map_image.png')
    FileUtils.mv(map_image_path, destination_path)

    respond_to do |format|
      format.html

      format.pdf do
        pdf_content = render_to_string(
          pdf: 'post_pdf',
          template: 'admin/job_sheets/generate_pdf',
          layout: 'pdf_layout',
          locals: { map_image_path: destination_path }
        )
        send_data(pdf_content, filename: 'post_pdf.pdf', type: 'application/pdf', disposition: 'inline')
      end
    end
  end
  
  private
  
  def job_sheet_params
    params.require(:job_sheet).permit(:start_address, :end_address, :customer_name, :site_contact, :contact_number, :notes, :job_number, :job_instruction)
  end

  def fetch_directions
    response =  Response.where(response_type: "route").last
    json_data = response.json_file.download
    directions_data = JSON.parse(json_data)

    if directions_data.all? { |data| data['status'] == 'OK' }
      # Parse the response to extract all routes with their instructions
      routes_with_instructions = parse_directions_response(directions_data)
      { success: true, data: routes_with_instructions }
    else
      { success: false, error_message: 'Failed to fetch directions' }
    end
  end
  
  def parse_directions_response(directions_data)
    routes_with_instructions = []
    directions_data.each do |data|
      next unless data['status'] == 'OK'
      data['routes'].each do |route|
        routes_with_instructions << {
          polyline: route['overview_polyline']['points'],
          instructions: extract_instructions(route['legs'].first)
        }
      end
    end
    routes_with_instructions
  end
  
  def extract_instructions(leg)
    instructions = []
    leg['steps'].each do |step|
      instructions << step['html_instructions']
    end
    instructions
  end
end
