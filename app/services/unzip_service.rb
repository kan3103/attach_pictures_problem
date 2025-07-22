# frozen_string_literal: true

# This service handles the edit logic for Inventory records.
class UnzipService < Patterns::Service
  attr_reader :extracted_folder

  def initialize(file)
    super()
    @uploaded_file = file
  end

  def call
    zip_path = @uploaded_file
    
    @extracted_folder = Rails.root.join('tmp', 'unzipped')
    FileUtils.mkdir_p(@extracted_folder)

    Zip::File.open(zip_path) do |zip_file|
      zip_file.each do |entry|
        entry_path = File.join(@extracted_folder, entry.name)
        FileUtils.mkdir_p(File.dirname(entry_path))
        zip_file.extract(entry, entry_path) { true }
      end
    end
    self
   end
end
