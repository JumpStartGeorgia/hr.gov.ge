@statistics_sheet = StatisticsSheet.new

@data_files_log = CustomLogger.new('Data Files Log', 'data_files.log')
@missing_param_log = CustomLogger.new('hr.gov.ge Missing Params Log', 'missing_params.log')
@database_log = CustomLogger.new('Database Log', 'database.log')
@scraper_log = CustomLogger.new('Scraper Log', 'scraper.log')

@error_sheet = ErrorSheet.new([
  @data_files_log,
  @missing_param_log,
  @database_log,
  @scraper_log
])


# starting url
@posting_url = "https://www.hr.gov.ge/JobProvider/UserOrgVakActives/Details/"
@serach_url = "https://www.hr.gov.ge/"
@page_param = "?pageNo="

@finished_scraping_new_post_ids = false


####################################################
@nbsp = Nokogiri::HTML("&nbsp;").text
####################################################

@data_path = 'data/hr.gov.ge/'
@response_file = 'response.html'
@json_file = 'data.json'
@db_config_path = 'config/database.yml'
@status_file_name = 'status.json'
@db_dump_file = 'hr.gov.ge.sql.gz'

# Tracks the number of ids pulled from ad lists to be scraped;
# @max_num_ids_to_scrape is compared to this to determine when to stop
@num_ids_scraped = 0

# Set this to limit the number of ids scraped (useful in test run)
# Note: Scraper likely will not stop precisely at this number
@max_num_ids_to_scrape = nil

# Set this to the page number where gathering ids should begin.
# Useful for starting a scrape from an old date in order to break up long
# scrape runs
@start_page_num = nil

@status = Status.new(@status_file_name)
@postings_database = PostingsDatabase.new(@db_config_path, @database_log)


# create the list of labels for the elements on the web page
@labels = {}
@labels[:posting_id] = nil

@labels[:common] = {}
@labels[:common][:title] = 'თანამდებობის დასახელება'
@labels[:common][:employer] = 'დამსაქმებელი'
@labels[:common][:category] = 'კატეგორია'
@labels[:common][:deadline] = 'განცხადების წარდგენის ბოლო ვადა'
@labels[:common][:salary] = 'თანამდებობრივი სარგო:'
@labels[:common][:number_openings] = 'ადგილების რაოდენობა'
@labels[:common][:duty] = 'სამსახურის ადგილმდებარეობა'
@labels[:common][:job_type] = 'სამუშაოს ტიპი'
@labels[:common][:probation_period] = 'გამოსაცდელი ვადა'

@labels[:common][:functions] = 'ფუნქციები'

@labels[:common][:minimum_education] = 'მინიმალური განათლება'
@labels[:common][:years_work_experience] = 'სამუშაო გამოცდილება'
@labels[:common][:profession] = 'პროფესია'
@labels[:common][:minimum_age] = 'სასურველი ასაკი -დან'

@labels[:common][:competition_topic] = 'საკონკურსო თემატიკა'

@labels[:common][:contact_address] = 'საკონკურსო - საატესტაციო კომისიის მისამართი'
@labels[:common][:contact_phone] = 'საკონტაქტო ტელეფონები'
@labels[:common][:contact_person] = 'საკონტაქტო პირი'

@labels[:common][:additional_requirements] = 'დამატებით მოთხოვნები'
@labels[:common][:for_more_information] = 'დამატებითი ინფორმაცია'
@labels[:common][:form_and_terms_of_decision] = 'გადაწყვეტილების მიღების ფორმა და ვადა'

@labels[:special_cases] = {}
@labels[:special_cases][:computer_software] = 'კომპიუტერული პროგრამები, ოპერაციული სისტემები'
@labels[:special_cases][:languages] = 'ენები'
@labels[:special_cases][:competition_stages] = 'კონკურსის ეტაპები'
@labels[:special_cases][:mandatory_blocks] = 'სავალდებულო ბლოკები'
