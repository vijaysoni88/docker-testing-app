class Admin::JobSheetsController < ApplicationController
  def create
    response = DirectionsApiService.get_directions(params[:start_address], params[:end_address])
  
    if response.success?
      directions = {
        steps: response['steps'],
        instructions: response['instructions']
      }

      @job_sheet = JobSheet.new(job_sheet_params.merge(directions: directions))

      if @job_sheet.save
        PdfGeneratorService.generate_job_sheet_pdf(@job_sheet)
        respond_to do |format|
          format.js { render 'create', status: :ok }
        end
      else
        respond_to do |format|
          format.js { render 'error', status: :unprocessable_entity }
        end
      end
    else
      respond_to do |format|
        format.js { render 'error', status: :unprocessable_entity }
      end
    end
  end
    
  private
    
  def job_sheet_params
    params.require(:job_sheet).permit(:start_address, :end_address, :customer_name, :site_contact, :contact_number, :notes)
  end
end
