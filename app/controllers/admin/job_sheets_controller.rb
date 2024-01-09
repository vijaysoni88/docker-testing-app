class Admin::JobSheetsController < ApplicationController
  def create
    # response = DirectionsApiService.get_directions(params[:start_address], params[:end_address])
  
    # if response.success?
    #   directions = {
    #     steps: response['steps'],
    #     instructions: response['instructions']
    #   }

      # @job_sheet = JobSheet.new(job_sheet_params.merge(directions: directions))
      @job_sheet = JobSheet.new(job_sheet_params)
      if @job_sheet.save
        # binding.pry
        pdf_data = PdfGeneratorService.generate_job_sheet_pdf(@job_sheet)

          send_data pdf_data.render, filename:'job_sheet.pdf', type: "application/pdf", disposition: :attachment
      else
        respond_to do |format|
          format.js { render 'error', status: :unprocessable_entity }
        end
      end
  end

  private
    
  def job_sheet_params
    params.require(:job_sheet).permit(:start_address, :end_address, :customer_name, :site_contact, :contact_number, :notes, :job_number, :job_instruction)
  end
end
