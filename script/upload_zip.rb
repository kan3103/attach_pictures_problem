require_relative '../config/environment'
require_relative '../config/application'

require 'benchmark'

dummy_path = Rails.root.join('tmp', 'images')

def upload_zip(post, dummy_path)
    blobs = []
    time = Benchmark.realtime do
      blobs = upload_all_files(dummy_path)
      attachments = blobs.map do |blob|
      {
        name: "images",
        record_type: "Post",
        record_id: post.id,
        blob_id: blob.id,
        created_at: Time.current
      }
      end
      ActiveStorage::Attachment.insert_all!(attachments)
    end
    time
end

def upload_all_files(extracted_folder)
    blobs = []
    Dir.glob(File.join(extracted_folder, '**', '*')) do |file_path|
      next if File.directory?(file_path)

      filename = File.basename(file_path)

      file = File.open(file_path)
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: filename,
        content_type: Marcel::MimeType.for(file)
      )
      blobs << blob
    end
    blobs
end



# benchmark to measure the time taken to insert records with images bypassing attach function
def db_insert(dummy_path, num: 10)
    puts "Inserting #{num} records with images without reload"
    times = 0
    num.times do |i|
        post = Post.create!(title: "Batch #{i + 1}", content: "Attaching images in batches")
        puts "Uploading zip for batch #{i + 1}"
        time = upload_zip(post, dummy_path)
        times += time
        puts "Time taken to upload files: #{time.round(2)} seconds"
        puts "Batch #{i + 1} completed."
    end
    puts "Total time for all batches: #{times.round(2)} seconds"
end



# benchmark to measure the time taken to insert records with images using attach function and splitting into batches
def attach_in_batches(dummy_path, num: 2, batch_size: 400)
    puts "Attaching images by attach function in batches of #{batch_size} of #{num} records"
    times = 0
    1..num.times do |n|
        post = Post.create!(title: "Batch #{n + 1}", content: "Attaching images in batches")
        temp = Benchmark.realtime do
            files = []
            Dir.glob(File.join(dummy_path, '**', '*')) do |file_path|
                next if File.directory?(file_path)
                filename = File.basename(file_path)
                file = { io: File.open(file_path), filename: filename, content_type: Marcel::MimeType.for(File.open(file_path)) }
                files << file
                
                if files.size >= batch_size
                    post.images.attach(files)
                    files.clear
                end
            end
        end
        puts "Batch #{n + 1} - Time taken: #{temp.round(2)}s"
        times += temp
    end
    puts "Sum of all batches: #{times.round(2)}s"
end

attach_in_batches(dummy_path, num: 3, batch_size: 400)
db_insert(dummy_path, num: 3)
