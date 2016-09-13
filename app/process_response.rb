require_relative 'environment'

def process_response(response)
  # pull out the id from the url
  id = get_url_id(response.request.url)

  if id.nil?
    @scraper_log.error "response url is not in expected format: #{response.request.url}; expected url to end with the id"
    return
  end

  # get the name of the folder for this id
  id_folder = get_parent_id_folder(id)
  folder_path = @data_path + id_folder + "/" + id + "/"

  # get the response body
  doc = Nokogiri::HTML(response.body)

  if doc.css('form > div > dl dt').length == 0
    @scraper_log.error "the response does not have any content to process"
    return
  end

  # save the response body
  file_path = folder_path + @response_file
	create_directory(File.dirname(file_path))
  File.open(file_path, 'w'){|f| f.write(doc)}
  compress_file(file_path)

  # create the json
  json = json_template

  json[:posting_id] = id

  # get all of the common fields that use dt for label and dd for value
  common_titles = doc.css('form > div > dl dt')
  common_values = doc.css('form > div > dl dt + dd')
  if common_titles.length > 0 && common_values.length > 0
    common_titles.each_with_index do |title, title_index|
      title_text = title.text.strip.downcase
      # get the index for the key with this text
      index = @labels[:common].values.index{|x| title_text == x}
      if index
        # get the key name for this text
        key = @labels[:common].keys[index]
        # save the value
        json[:common][key] = common_values[title_index].text.strip

        # puts "> key = #{key}; value = #{json[:common][key]}"

        # perform special formatting as necessary
        if !json[:common][key].nil? && json[:common][key].length > 0
          case key
            # format deadline as date
            when :deadline
              json[:common][:deadline] = Date.strptime(json[:common][:deadline], '%d.%m.%Y').strftime
            # format number of openings as int
            when :number_openings
              json[:common][:number_openings] = json[:common][:number_openings].to_i
            # format salary as int
            when :salary
              json[:common][:salary_currency] = json[:common][:salary].split(' ').last
              json[:common][:salary] = json[:common][:salary].to_i
          end


        end
      elsif !common_values[title_index].nil? && common_values[title_index].text.strip.length != 0 && common_values[title_index].text.strip != ' '
        @missing_param_log.error "Missing detail json key for text: '#{title_text}' in record #{id} with value of '#{common_values[title_index].text.strip}'"
      end
    end
  end

  # custom processing is required for the following
  sections = doc.css('form > div > div')
  if sections.length > 0
    # computers
    # - row format: name | empty | level
    computers = sections[0].css('tr')
    computers.each_with_index do |computer, comp_index|
      if comp_index == 0
        json[:special_cases][:computer_software] = []
      else
        temp = json_computer_template.dup
        temp[:name] = computer.css('td')[0].text.strip
        temp[:level] = computer.css('td')[2].text.strip
        json[:special_cases][:computer_software] << temp
      end
    end

    # languages
    # - row format: language | written | spoken
    languages = sections[1].css('tr')
    languages.each_with_index do |language, lang_index|
      if lang_index == 0
        json[:special_cases][:languages] = []
      else
        temp = json_language_template.dup
        temp[:language] = language.css('td')[0].text.strip
        temp[:writing] = language.css('td')[2].text.strip
        temp[:speaking] = language.css('td')[4].text.strip
        json[:special_cases][:languages] << temp
      end
    end

    # competition_stages
    # - row format: value
    json[:special_cases][:competition_stages] = []
    stages = sections[2].css('tr')
    stages.each do |stage|
      json[:special_cases][:competition_stages] << stage.css('td')[0].text.strip
    end

    # mandatory_blocks
    # - div > label > text
    json[:special_cases][:mandatory_blocks] = []
    blocks = sections[3].css('div > label')
    blocks.each do |block|
      json[:special_cases][:mandatory_blocks] << block.text.strip
    end

  end

  if !json[:posting_id].nil?
    # save the json
    file_path = folder_path + @json_file
    create_directory(File.dirname(file_path))
    File.open(file_path, 'w'){|f| f.write(json.to_json)}
  end

  @status.remove_json_id(id)
end
