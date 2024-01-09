class PdfGeneratorService
  def self.generate_job_sheet_pdf(job_sheet)
    pdf = Prawn::Document.new

    # Add logo at the top-right corner
    logo_path = "#{Rails.root}/app/assets/images/logo.jpg"
    pdf.image logo_path, at: [pdf.bounds.right - 100, pdf.bounds.top - 40], width: 100
    pdf.move_down 10 # Add some space after the logo
    pdf.text("\n") # Add a newline after "JOB DETAILS"
    pdf.text("\n") # Add a newline after "JOB DETAILS"
    pdf.text("\n") # Add a newline after "JOB DETAILS"
    pdf.text("\n") # Add a newline after "JOB DETAILS"
    pdf.text("\n") # Add a newline after "JOB DETAILS"
    pdf.text("\n") # Add a newline after "JOB DETAILS"
    pdf.text "JOB DETAILS", style: :bold
    pdf.text("\n") # Add a newline after "JOB DETAILS"

    pdf.text "JOB LOCATION", style: :bold
    pdf.text "#{job_sheet.end_address}"
    pdf.text_box "Customer Name: #{job_sheet.customer_name}", style: :bold, at: [0, pdf.cursor]
    pdf.text "\n" # Add a newline after "JOB LOCATION"
    pdf.text "Site Contact: #{job_sheet.site_contact}"
    pdf.text "Contact Number: #{job_sheet.contact_number}"
    pdf.text "NOTES", style: :bold
    pdf.text("\n") # Add a newline after "JOB DETAILS"
    pdf.text("\n") # Add a newline after "JOB DETAILS"
    pdf.text("\n") # Add a newline after "JOB DETAILS"
    pdf.text("\n") # Add a newline after "JOB DETAILS"

    pdf.text "DIRECTIONS", style: :bold
    pdf.text("\n") # Add a newline after "DIRECTIONS"

    # Dummy data for testing the table
    directions_data = [
      { step: 1, instructions: 'Go straight' },
      { step: 2, instructions: 'Turn right' },
      { step: 3, instructions: 'Turn left' }
    ]

    # Table setup with specific cell colors
    table_data = [['Step', 'Instructions']]
    table_data += directions_data.map { |data| [data[:step].to_s, data[:instructions]] }

    # Define the table structure and style
    table_style = {
      width: pdf.bounds.width,
      cell_style: { size: 10 },
      header: true
    }

    # Draw the table using prawn-table
    pdf.table(table_data, table_style) do |table|
      table.column_widths = { 0 => 50, 1 => pdf.bounds.width - 50 }
      table.row_colors = ['C0C0C0', 'FFFFFF'] # Light gray for the header background, white for other cells
    end

    return pdf
  end
end

# Render steps and instructions in two columns
  # job_sheet.directions['steps'].each_with_index do |step, index|
  #   instruction = job_sheet.directions['instructions'][index]

  #   pdf.text "#{step} in first column", indent_paragraphs: 20
  #   pdf.text "In second column #{instruction}", indent_paragraphs: 20
  #   pdf.move_down 10
  # end

  # Add more sections as needed, such as adding a map image on a separate page
