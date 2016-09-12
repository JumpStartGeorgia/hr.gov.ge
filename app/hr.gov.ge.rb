require_relative 'environment'

def make_requests
  #initiate hydra
  hydra = Typhoeus::Hydra.new(max_concurrency: 20)
  request = nil

  # pull in first search results page
  url = @serach_url

  doc = Nokogiri::HTML(open(url))

  # get the number of pages of search results that exist
  # - get the p param out of the last page pagination link
  last_page = 1 # just give it a default value
  pagination_links = doc.css('.paging .pagination-container .pagination li a')
  if pagination_links.length > 0
    # if there is no next page, then set last_page = 1 (done above)
    # else, the last page is in the 2nd to last link (the last link is the next page link)
    if !doc.css('.paging .pagination-container .pagination li a.PagedList-skipToNext').nil?
      last_page = get_param_value(pagination_links[pagination_links.length-2]['href'], 'pageNo')
    end
  end
  last_page = last_page.to_i if !last_page.nil?

  # get all of the ids that are new since the last run
  if @start_page_num.nil?
    i = 1
  elsif @start_page_num > last_page
    puts "The requested start page doesn't exist!"
    exit
  else
    i = @start_page_num
  end

  while !@finished_scraping_new_post_ids && i <= last_page
    puts "page #{i}"
    # create the url
    url = @serach_url + @page_param + i.to_s

    # get the html
    doc = Nokogiri::HTML(open(url))

    search_results = doc.css('table.vacans-table > tbody tr td:first a')

    # if the search results has either no response, stop
    if search_results.length == 0
      @scraper_log.error "the response does not have any content to process for url #{url}"
      break
    end

    # get the ids for this page
    pull_out_ids(search_results)

    i+=1
  end

  # only keep ids that have no been processed
  @ids_to_process = @ids_to_process - @processed_ids

  # save these ids to process
  @status.save_new_posting_to_process(@ids_to_process)


  num_ids = @status.num_json_ids_to_process

  if num_ids == 0
    @scraper_log.warn "There are no new IDs to process so stopping"
    return
  end

  # record total number of records to process
  total_to_process = num_ids
  total_left_to_process = num_ids

  #build hydra queue
  @status.json_ids_to_process.each do |posting|
    @statistics_sheet.increase_num_ids_processed_by_1

    # build the url
    url = @posting_url + posting[:id]
    request = Typhoeus::Request.new("#{url}", followlocation: true)

    request.on_complete do |response|
      if response.success?
        # put success callback here
        @scraper_log.info("#{response.request.url} - success")

        @statistics_sheet.increase_num_ids_successfully_processed_by_1

        # process the response
        process_response(response)
      elsif response.timed_out?
        # aw hell no
        @scraper_log.error("#{response.request.url} - got a time out")
        @statistics_sheet.increase_num_ids_timed_out_by_1
      elsif response.code == 0
        # Could not get an http response, something's wrong.
        @scraper_log.error("#{response.request.url} - no response: #{response.return_message}")
        @statistics_sheet.increase_num_ids_with_no_response_by_1
      else
        # Received a non-successful http response.
        @scraper_log.error("#{response.request.url} - HTTP request failed: #{response.code.to_s}")
        @statistics_sheet.increase_num_ids_with_http_request_failure_by_1
      end

      # decrease counter of items to process
      total_left_to_process -= 1
      if total_left_to_process == 0
        @scraper_log.info "------------------------------"
        @scraper_log.info "It took #{Time.now - @start} seconds to process #{total_to_process} items"
        @scraper_log.info "------------------------------"

        # now update the database
        update_database

        # now push to git
        update_github

      elsif total_left_to_process % 25 == 0
        puts "There are #{total_left_to_process} files left to process; time so far = #{Time.now - @start} seconds"
      end
    end
    hydra.queue(request)
  end

  hydra.run

end
