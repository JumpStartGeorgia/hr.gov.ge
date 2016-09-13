require_relative 'environment'

def environment_is_production
  return ENV['ENVIRONMENT'] == 'production'
end

def json_template
  json = {}
  json[:posting_id] = nil

  json[:common] = {}
  json[:common][:title] = nil
  json[:common][:employer] = nil
  json[:common][:category] = nil
  json[:common][:deadline] = nil
  json[:common][:salary] = nil
  json[:common][:salary_currency] = nil
  json[:common][:number_openings] = nil
  json[:common][:duty] = nil
  json[:common][:job_type] = nil
  json[:common][:probation_period] = nil

  json[:common][:functions] = nil

  json[:common][:minimum_education] = nil
  json[:common][:years_work_experience] = nil
  json[:common][:profession] = nil
  json[:common][:minimum_age] = nil

  json[:common][:competition_topic] = nil

  json[:common][:contact_address] = nil
  json[:common][:contact_phone] = nil
  json[:common][:contact_person] = nil

  json[:common][:additional_requirements] = nil
  json[:common][:for_more_information] = nil
  json[:common][:form_and_terms_of_decision] = nil

  json[:special_cases] = {}
  json[:special_cases][:computer_software] = nil
  json[:special_cases][:languages] = nil
  json[:special_cases][:competition_stages] = nil
  json[:special_cases][:mandatory_blocks] = nil

  return json
end

def json_computer_template
  {
    name: nil,
    level: nil
  }
end

def json_language_template
  {
    language: nil,
    writing: nil,
    speaking: nil
  }
end

def create_directory(file_path)
	if !file_path.nil? && file_path != "."
		FileUtils.mkpath(file_path)
	end
end

# get the parent folder for the provided id
# - the folder is the id minus it's last 2 digits
def get_parent_id_folder(id)
  if id.to_s.length > 4
    id.to_s[0..id.to_s.length-2]
  else
    id.to_s
  end
end

# pull out a query parameter value for a particular key
def get_param_value(url, key)
  value = nil
  index_q = url.index('?')
  if !index_q.nil?
    url_params = url.split('?').last

    if !url_params.nil?
      params = url_params.split('&')

      if !params.nil?
        param = params.select{|x| x.index(key + '=') == 0}
        if !param.nil?
          value = param.first.split('=')[1]
        end

      end
    end
  end

  return value
end

# pull out id from url
# href is in format: /JobProvider/UserOrgVakActives/Details/39510
# - where the last part is the id
def get_url_id(url)
  if !url.nil?
    url.split('/').last
  end
end

def posting_is_duplicate(post_id)
  @saved_ids_for_last_scraped_date.include? post_id
end

# pull out the id of each property from the link
def pull_out_ids(links)
  puts "pull_out_ids"
  links.each do |link|
    # puts "- link = #{link}; href = #{link['href']}"
    post_id = get_url_id(link['href'])
    puts "- post_id = #{post_id}"
    next if post_id.nil?

    if reached_max_num_ids_to_scrape
      @finished_scraping_new_post_ids = true
      break
    end

    @ids_to_process << post_id

    @num_ids_scraped += 1

    #@status.save_new_posting_to_process(post_id)
  end
end


# create sql for insert statements
def create_sql_insert(mysql, json, source)
  fields = []
  values = []
  sql = nil

  fields << 'source'
  values << source

  fields << 'created_at'
  values << Time.now.strftime('%Y-%m-%d %H:%M:%S')

  if !json["posting_id"].nil?
    fields << 'posting_id'
    values << json["posting_id"]
  end

  if !json["common"]["title"].nil?
    fields << 'title'
    values << json["common"]["title"]
  end
  if !json["common"]["employer"].nil?
    fields << 'employer'
    values << json["common"]["employer"]
  end
  if !json["common"]["category"].nil?
    fields << 'category'
    values << json["common"]["category"]
  end
  if !json["common"]["deadline"].nil?
    fields << 'deadline'
    values << json["common"]["deadline"]
  end
  if !json["common"]["salary"].nil?
    fields << 'salary'
    values << json["common"]["salary"]
  end
  if !json["common"]["salary_currency"].nil?
    fields << 'salary_currency'
    values << json["common"]["salary_currency"]
  end
  if !json["common"]["number_openings"].nil?
    fields << 'number_openings'
    values << json["common"]["number_openings"]
  end
  if !json["common"]["duty"].nil?
    fields << 'duty'
    values << json["common"]["duty"]
  end
  if !json["common"]["job_type"].nil?
    fields << 'job_type'
    values << json["common"]["job_type"]
  end
  if !json["common"]["probation_period"].nil?
    fields << 'probation_period'
    values << json["common"]["probation_period"]
  end

  if !json["common"]["functions"].nil?
    fields << 'functions'
    values << json["common"]["functions"]
  end

  if !json["common"]["minimum_education"].nil?
    fields << 'minimum_education'
    values << json["common"]["minimum_education"]
  end
  if !json["common"]["years_work_experience"].nil?
    fields << 'years_work_experience'
    values << json["common"]["years_work_experience"]
  end
  if !json["common"]["profession"].nil?
    fields << 'profession'
    values << json["common"]["profession"]
  end
  if !json["common"]["minimum_age"].nil?
    fields << 'minimum_age'
    values << json["common"]["minimum_age"]
  end

  if !json["common"]["competition_topic"].nil?
    fields << 'competition_topic'
    values << json["common"]["competition_topic"]
  end

  if !json["common"]["contact_address"].nil?
    fields << 'contact_address'
    values << json["common"]["contact_address"]
  end
  if !json["common"]["contact_phone"].nil?
    fields << 'contact_phone'
    values << json["common"]["contact_phone"]
  end
  if !json["common"]["contact_person"].nil?
    fields << 'contact_person'
    values << json["common"]["contact_person"]
  end

  if !json["common"]["additional_requirements"].nil?
    fields << 'additional_requirements'
    values << json["common"]["additional_requirements"]
  end
  if !json["common"]["for_more_information"].nil?
    fields << 'for_more_information'
    values << json["common"]["for_more_information"]
  end

  if !json["common"]["form_and_terms_of_decision"].nil?
    fields << 'form_and_terms_of_decision'
    values << json["common"]["form_and_terms_of_decision"]
  end

  if !json["special_cases"]["computer_software"].nil?
    fields << 'computer_software'
    value = "total:#{json["special_cases"]["computer_software"].length}\n"
    value += json["special_cases"]["computer_software"].map{|x| "type:#{x['name']} | level:#{x['level']}"}.join("\n")
    values << value
  end

  if !json["special_cases"]["languages"].nil?
    fields << 'languages'
    value = "total:#{json["special_cases"]["languages"].length}\n"
    value += json["special_cases"]["languages"].map{|x| "language:#{x['language']} | writing:#{x['writing']} | speaking:#{x['speaking']}"}.join("\n")
    values << value
  end

  if !json["special_cases"]["competition_stages"].nil?
    fields << 'competition_stages'
    values << json["special_cases"]["competition_stages"].join("\n")
  end

  if !json["special_cases"]["mandatory_blocks"].nil?
    fields << 'mandatory_blocks'
    values << json["special_cases"]["mandatory_blocks"].join("\n")
  end


  if !fields.empty? && !values.empty?
    sql= "insert into postings("
    sql << fields.join(', ')
    sql << ") values("
    sql << values.map{|x| "\"#{mysql.escape(x.to_s)}\""}.join(', ')
    sql << ")"
  end

  return sql
end

# delete the record if it already exists
def delete_record_sql(mysql, posting_id)
    sql = "delete from postings where posting_id = '"
    sql << mysql.escape(posting_id.to_s)
    sql << "'"

    return sql
end

# update github with any changes
def update_github
  unless environment_is_production
    puts 'NOT updating github because environment is not production'
    return false
  end

  puts 'pushing database to github'

  @scraper_log.info "------------------------------"
  @scraper_log.info "updating git"
  @scraper_log.info "------------------------------"
  x = Subexec.run "git add #{@db_dump_file} #{@status_file_name}"
  x = Subexec.run "git commit -m 'Updated database dump file and status.json with new hr.gov.ge data'"
  x = Subexec.run "git push origin master"
end

def compress_file(file_path)
  file_name = File.basename(file_path)
  dir_path = File.dirname(file_path)

  compressed_file_path = "#{dir_path}/#{file_name}.zip"

  begin
    Zip::File.open(compressed_file_path, Zip::File::CREATE) do |zipfile|
      zipfile.add(file_name, file_path)
    end
  rescue StandardError => e
    @data_files_log.error "Could not zip #{file_path} ---> #{compressed_file_path}; error: #{e}"
  end

  File.delete(file_path)
end

def reached_max_num_ids_to_scrape
  !@max_num_ids_to_scrape.nil? && @num_ids_scraped >= @max_num_ids_to_scrape
end

def compress_data_files
  if uncompressed_data_files.empty?
    puts 'Data files are already compressed!'
    return
  end

  uncompressed_data_files.each do |file|
    compress_file(file)
  end
end

def uncompressed_data_files
  html_files = Dir.glob("#{@data_path}/**/*.html")
  json_files = Dir.glob("#{@data_path}/**/*.json")
  return html_files + json_files
end

def git_checkout_file(file)
  puts "Running 'git checkout -- #{file}'"
  `git checkout -- #{file}`
end
