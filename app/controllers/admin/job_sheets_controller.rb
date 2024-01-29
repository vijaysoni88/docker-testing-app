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

    @directions = params[:job_sheet][:directions] == 'null' ? [] : JSON.parse(params[:job_sheet][:directions])

    # Assuming @directions is the array you provided
    route_instructions = []
    all_routes_instructions = []

    @directions.each do |direction|
      if direction.start_with?("<strong>Route")
        all_routes_instructions.push(route_instructions) unless route_instructions.empty?
        route_instructions = [direction]
      else
        route_instructions.push(direction)
      end
    end

    # Push the last set of instructions
    all_routes_instructions.push(route_instructions) unless route_instructions.empty?

    @all_routes_instructions = all_routes_instructions


    map_image_path = google_maps_image(@job_sheet.start_address, @job_sheet.end_address)

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
          layout: 'pdf_layout'
        )
        send_data(pdf_content, filename: 'post_pdf.pdf', type: 'application/pdf', disposition: 'inline')
      end
    end
  end
  
  private
  
  def job_sheet_params
    params.require(:job_sheet).permit(:start_address, :end_address, :customer_name, :site_contact, :contact_number, :notes, :job_number, :job_instruction)
  end
end
