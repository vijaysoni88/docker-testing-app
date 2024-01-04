document.addEventListener('DOMContentLoaded', function() {
    const fileInput = document.getElementById('kmz-file');
    const browseButton = document.getElementById('browse-button');
    const newBarrierForm = document.getElementById('new-barrier-form');
    const errorMessageContainer = document.getElementById('error-message');
  
  
    browseButton.addEventListener('click', function() {
      fileInput.click();
    });
  
    fileInput.addEventListener('change', function() {
      const fileName = fileInput.files[0] ? fileInput.files[0].name : 'Upload File';
      document.getElementById('kmz-file').nextElementSibling.querySelector('input').value = fileName;
    });
  
    newBarrierForm.addEventListener('submit', function(event) {
      event.preventDefault();
  
      const formData = new FormData(event.target);
  
      fetch(event.target.action, {
        method: event.target.method,
        body: formData,
        headers: {
          'Accept': 'text/javascript',
          'X-CSRF-Token': Rails.csrfToken()
        }
      }).then(response => {
        if (response.ok) {
          // Barrier created successfully, display success message
          errorMessageContainer.innerHTML = 'Barrier added successfully!';
        } else {
          // Barrier creation failed, display error message
          return response.text();
        }
      }).then(errorText => {
        errorMessageContainer.innerHTML = errorText;
      });
    });
  });
