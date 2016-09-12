# Provides interface to work with status.json, a file which stores information
# about the previous scrape run
class Status
  def initialize(file_path)
    @file = file_path

    create_new_file
  end

  attr_accessor :file,
                :json_ids_to_process,
                :db_ids_to_process

  def reset_file
    create_new_file
  end

  def remove_db_id(id)
    fail if db_ids_to_process.nil? || db_ids_to_process.length == 0

    db_ids_to_process.delete(id)

    update_file
  end

  def remove_json_id(id)
    fail if json_ids_to_process.nil? || json_ids_to_process.length == 0

    json_ids_to_process.delete(id)

    update_file
  end

  # def db_ids_for_locale?(locale)
  #   locale = locale.to_sym
  #   fail if db_ids_to_process[locale].nil?

  #   db_ids_to_process[locale].length > 0
  # end

  def num_json_ids_to_process
    total = 0

    total += json_ids_to_process.length

    total
  end

  def save_new_posting_to_process(ids)
    return if ids.nil?

    if ids.class.to_s.downcase == 'array'
      posts = ids.map{|x| {id: x}}

      json_ids_to_process << posts.clone
      db_ids_to_process << posts.clone

      json_ids_to_process.flatten!
      db_ids_to_process.flatten!

    elsif ids.class.to_s.downcase == 'fixnum'
      post = {
        id: ids
      }

      json_ids_to_process << post.clone
      db_ids_to_process << post.clone
    end


    update_file
  end

  private

  def create_new_file
    @json_ids_to_process = []

    @db_ids_to_process = []

    update_file
  end

  def update_file
    File.open(file, 'w') { |f| f.write(to_json) }
  end

  def to_json
    {
      ids_to_process: {
        json: json_ids_to_process,
        db: db_ids_to_process
      }
    }.to_json
  end
end
