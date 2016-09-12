require_relative 'environment'

####################################################
# to load the jobs to a database, please have the following:
# - database.yml file with the following keys and the appropriate values
# - the user must have the ability to create database and tables
# - this database.yml file is not saved into the git repository so
#   passwords are not shared with the world
# - yml keys:
#     database:
#     username:
#     password:
#     encoding: utf8
#     host: localhost
#     port: 3306
#     reconnect: true

# - you will need to create the database
# - the tables will be created if they do not exist
####################################################

class PostingsDatabase
  def initialize(db_config_path, log)
    @log = log
    @db_config = get_db_config(db_config_path)

    @mysql = make_mysql_connection

    create_postings_table
  end

  attr_reader :db_config, :mysql, :log

  def query(sql)
    @mysql.query(sql)
  end

  def dump(db_dump_file)
    log.info '------------------------------'
    log.info 'dumping database'
    log.info '------------------------------'

    Subexec.run "mysqldump --single-transaction -u'#{db_config["username"]}' -p'#{db_config["password"]}' #{db_config["database"]} | gzip > \"#{db_dump_file}\" "
  end

  def close
    mysql.close if mysql
  end

  def number_postings_by_date
    output_query_result_to_console(
      query('SELECT date, COUNT(id) FROM postings GROUP BY date;')
    )
  end

  def processed_ids
    sql = "SELECT posting_id FROM postings order by posting_id desc;"

    query(sql).map { |row| row['posting_id'] }
  end

  # def ids_for_date(date)
  #   date_str = date.strftime('%Y-%m-%d')
  #   abort if date_str.nil?
  #   sql = "SELECT posting_id FROM postings WHERE date LIKE '#{date_str}%';"

  #   query(sql).map { |row| row['posting_id'] }
  # end

  def last_scraped_date
    sql = 'SELECT max(date) FROM postings'
    return query(sql).map { |row| row['max(date)'] }[0]
  rescue Mysql2::Error => e
    return nil
  end

  private

  def get_db_config(db_config_path)
    unless File.exist?(db_config_path)
      msg = "The #{db_config_path} does not exist"
      log.error(msg)
      abort(msg)
    end

    YAML.load(ERB.new(File.read(db_config_path)).result)
  end

  def make_mysql_connection
    Mysql2::Client.new(
      host: db_config['host'],
      port: db_config['port'],
      database: db_config['database'],
      username: db_config['username'],
      password: db_config['password'],
      encoding: db_config['encoding'],
      reconnect: db_config['reconnect'])
  end

  def create_postings_table
    query(
      "CREATE TABLE IF NOT EXISTS `postings` (\
      `id` int(11) NOT NULL AUTO_INCREMENT,\
      `posting_id` varchar(255) not null,\
      `source` varchar(255) not null,\
      `title` varchar(500) default null,\
      `employer` varchar(500) default null,\
      `category` varchar(255) default null,\
      `deadline` date default null,\
      `salary` int(11) default null,\
      `salary_currency` varchar(30) default null,\
      `number_openings` int(3) default null,\
      `duty` varchar(255) default null,\
      `job_type` varchar(255) default null,\
      `probation_period` varchar(255) default null,\

      `functions` text default null,\

      `minimum_education` varchar(255) default null,\
      `years_work_experience` varchar(255) default null,\
      `profession` varchar(255) default null,\
      `minimum_age` varchar(255) default null,\

      `competition_topic` text default null,\

      `contact_address` varchar(500) default null,\
      `contact_phone` varchar(50) default null,\
      `contact_person` varchar(500) default null,\

      `additional_requirements` text default null,\
      `for_more_information` text default null,\
      `form_and_terms_of_decision` varchar(500) default null,\


      `computer_software` varchar(500) default null,\
      `languages` varchar(500) default null,\
      `competition_stages` varchar(500) default null,\
      `mandatory_blocks` text default null,\

      `created_at` datetime,\

      PRIMARY KEY `Index 1` (`id`),\
      KEY `Index 2` (`posting_id`),\
      KEY `Index 4` (`source`),\
      KEY `Index 5` (`category`),\
      KEY `Index 6` (`job_type`),\
      KEY `Index 7` (`employer`),\
      CONSTRAINT uc_id_locale UNIQUE (posting_id)\
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
  end

  def output_query_result_to_console(query_result)
    query_result.each do |row|
      puts row
    end
  end
end
