require_relative 'environment'

def update_database
  puts 'updating database'
  source = ENV['SOURCE']

  start = Time.now

  begin
    @postings_database.log.info '**********************************************'
    @postings_database.log.info '**********************************************'

    ####################################################
    # load the data
    ####################################################
    files_processed = 0

    postings = @status.db_ids_to_process.dup

    postings.each do |posting|
      parent_id = get_parent_id_folder(posting[:id])
      file_path = "#{@data_path}#{parent_id}/#{posting[:id]}/#{posting[:date]}/#{@json_file}"

      next unless File.exist?(file_path)

      # pull in json
      json = JSON.parse(File.read(file_path))
      compress_file(file_path)

      # delete the record if it already exists
      sql = delete_record_sql(@postings_database.mysql, posting[:id])
      @postings_database.query(sql)

      # create sql statement
      sql = create_sql_insert(@postings_database.mysql, json, source)

      next if sql.nil?

      # create record
      @postings_database.query(sql)

      @status.remove_db_id(posting[:id])

      files_processed += 1
      @statistics_sheet.increase_num_db_records_saved_by_1

      # ad_date = Date.strptime(json['date'], '%Y-%m-%d')
      # @statistics_sheet.update_saved_records_date_range(ad_date)

      if files_processed % 100 == 0
        puts "#{files_processed} json files processed so far"
      end
    end

    @postings_database.log.info '------------------------------'
    @postings_database.log.info "It took #{Time.now - start} seconds to load #{files_processed} json files into the database"
    @postings_database.log.info '------------------------------'

    @postings_database.dump(@db_dump_file)

  rescue Mysql2::Error => e
    @postings_database.log.error "Mysql error ##{e.errno}: #{e.error}"
  ensure
    @postings_database.close unless @postings_database.nil?
  end
end
