require_relative '../config/environment'
require_relative '../config/application'

require 'benchmark'

dummy_path = Rails.root.join('tmp', 'images')

def upload_zip(post, dummy_path)
    blobs = []
    time = Benchmark.realtime do
      upload_all_files(post.id, dummy_path)
    end
    time
end

def insert_attachments(post_id, blobs)
    now = Time.current
    attachments = blobs.map do |blob|
      {
        name: "images",
        record_type: "Post",
        record_id: post_id,
        blob_id: blob,
        created_at: now
      }
    end
    ActiveStorage::Attachment.insert_all!(attachments)
end

def upload_all_files(id, extracted_folder, batch_size: 400)
    blobs = []
    Dir.glob(File.join(extracted_folder, '**', '*')).each_with_index do |file_path, idx|
      next if File.directory?(file_path)

      filename = File.basename(file_path)

      file = File.open(file_path)
      blobs << {
        byte_size: file.size,
        checksum: '',
        filename: filename,
        metadata: {},
        key: "test_uploads/#{id}/#{idx}/#{filename}",
        service_name: 'localstack',
        created_at: Time.current,
      }
      if blobs.size >= batch_size
        ActiveStorage::Blob.insert_all!(blobs)
        keys = blobs.map { |b| b[:key] }
        inserted_blobs = ActiveStorage::Blob.where(key: keys).order(:id)
        ids = inserted_blobs.pluck(:id)
        insert_attachments(id, ids)
        blobs.clear
      end
    end
end



# benchmark to measure the time taken to insert records with images bypassing attach function
def db_insert(dummy_path, num: 10)
    puts "Inserting #{num} records with images without reload"
    times = 0
    max, min = 0, Float::INFINITY
    num.times do |i|
        post = Post.create!(title: "Batch #{i + 1}", content: "Attaching images in batches")
        time = upload_zip(post, dummy_path)
        max = time if time > max
        min = time if time < min
        times += time
    end
    puts "Average time per record: #{(times / num).round(2)} seconds"
    puts "Max time for a record: #{max.round(2)} seconds"
    puts "Min time for a record: #{min.round(2)} seconds"
    puts "Avg diff between max and min: #{(max - min).round(2)} seconds"
    puts "Total time for all records: #{times.round(2)} seconds"
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

attach_in_batches(dummy_path, num: 10, batch_size: 400)
db_insert(dummy_path, num: 10)
