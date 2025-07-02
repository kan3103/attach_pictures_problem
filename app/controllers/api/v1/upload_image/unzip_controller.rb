# frozen_string_literal: true

require 'zip'

class Api::V1::UploadImage::UnzipController < Api::BaseController
  def upload_zip
    uploaded_file = params[:file]

    unless uploaded_file && uploaded_file.original_filename.ends_with?('.zip')
      return render json: { error: 'Please upload a valid .zip file' }, status: :bad_request
    end
    unzip = UnzipService.new(uploaded_file).call
    upload_all_files(unzip.extracted_folder)
    
    render json: {
      message: 'Zip uploaded and extracted successfully',
      extracted_to: unzip.extracted_folder.to_s
    }
  rescue => e
    return render json: { error: "Failed to unzip file: #{e.message}" }, status: :unprocessable_entity
  end

  private

  def upload_all_files(extracted_folder)
    Dir.glob(File.join(extracted_folder, '**', '*')) do |file_path|
      next if File.directory?(file_path)

      filename = File.basename(file_path)

      file = File.open(file_path)
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: filename,
        content_type: Marcel::MimeType.for(file)
      )
    end
  end
end
