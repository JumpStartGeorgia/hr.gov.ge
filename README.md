# hr.gov.ge Scraper

This program scrapes real estate data from the site hr.gov.ge and saves it to a database.

## Getting Started

1. `bundle install`
2. `cp .env.example .env`
3. Fill in `.env` variables. Unless you set ENVIRONMENT to production, emails will be sent to mailcatcher and you can use any fake email addresses you want.
4. Create mysql database and database user specified in `.env`.
5. Optional: Load data in from compressed database file (`hr.gov.ge.sql.gz`). See section The Data below.

## Usage

- `rake scraper:run` -> Run the scraper!
- `rake scraper:schedule:run_daily` -> Schedule a cron job to run `rake scraper:run` every day at 4 AM.

## Testing

No automatic test suite, but you can use

`rake scraper:test_run`

to manually test the scraper. Differences include:
- ENVIRONMENT cannot be set to production
- Only 20 ads will be scraped
- Emails will be sent to [mailcatcher](http://mailcatcher.me/)
- Database dump and status.json will not be pushed to github

## How it Works

When you run the scraper, the following happens:

1. __Choose Ads to Scrape__: The scraper gets a list of all posting IDs in the database. It then gets all of the IDs in the list of jobs for hr.gov.ge and only keeps the IDs that are not already in the system saves to `ids_to_process` in `status.json`.
2. __Scrape Ads__: Requests are sent to hr.gov.ge to the ads listed in `ids_to_process` and are saved as `data.json` files in the `data` folder.
3. __Save Ads to Database__: The ad info in the new `data.json` files are saved to the database.
4. __Update Github with New Data__: The database is dumped to `real-estate.sql.gz` and pushed to github, along with the new `status.json` file.
5. __Send Email Report on Scraper Run__: A report about the scrape run, including basic statistics and logged errors, is sent to the recipient specified in the `.env` file.

## The Data

The database is pushed with every scrape run to the github repo. That means you can use what others have already scraped to start out your database of hr.gov.ge real estate data. However, because updating github is built into the app, you will have to do one of the following:

1. Setup your own origin repo on github to receive your new scrape data.
2. Disable pushes to github.

## Project Layout
The following files contain code that is specific to hr.gov.ge.

- global_attributes.rb - Contains a list of all global variables used in throughout the script such as the search url, posting url, file paths, file names, and the list of the labels that are on the posting page.
- postings_database.rb - Creates the posting table if it does not exist and is called automatically when the scraper runs
- hr.gov.ge.rb - Defines how the IDs from the listing pages are gathered, calls each of these pages, and then starts the processing
- process_response.rb - Sets how each field is pulled from the web page. For hr.gov.ge, the majority of the page follows the format of title being in a `dt` tag while the value is in the proceeding `dd` tag.
- utilities.rb - A collection of common methods used throughout the scraping process. Defines the json template for saving the web page data. Creates the SQL insert statement for adding data to the database.
