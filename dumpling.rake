namespace :dumpling do
  namespace :import do
    desc "Import Heroku Staging database locally"
    task :staging do
      import_db("staging", "YOUR_STAGING_HEROKU_APP_HERE")
    end

    desc "Import Heroku Production database locally"
    task :production do
      import_db("production", "YOUR_PRODUCTION_HEROKU_APP_HERE")
    end

    def import_db(environment, heroku_app_name)
      puts "🥟 \e[33mImporting #{environment} database locally...\e[0m\n\n"

      @dump_file_name = "tmp/#{environment}-#{dump_name_suffix}.dump"

      puts "\e[33m→ Delete old dumps in 'tmp' folder.\e[0m\n"
      remove_old_dumps

      puts "\e[33m→ Creating back-up of\e[0m '#{local_database_name}' \e[33mdatabase in\e[0m 'tmp/development-#{dump_name_suffix}.dump'\n"
      dump_local_database

      puts "\e[33m→ Downloading Heroku last database back-up.\e[0m\n"
      download_heroku_database(heroku_app_name)
      `mv latest.dump #{@dump_file_name}`

      puts "\e[33m→ Importing downloaded database dump into\e[0m '#{local_database_name}' \e[33mdatabase.\e[0m\n"
      import_database_locally(@dump_file_name)

      puts "\e[33m→ Running migrations against the just imported database dump from Heroku.\e[0m\n"
      run_migrations

      puts "\n🏁 \e[32m#{environment} database successfully imported 🥳\e[0m"
    end

    def dump_name_suffix
      "#{Time.now.to_date}-#{Time.now.to_i}"
    end

    def remove_old_dumps
      `find tmp -type f -name "*.dump" -exec rm {} +`
    end

    def dump_local_database
      `pg_dump -Fc --no-acl --no-owner -h localhost -U #{local_database_user} #{local_database_name} > tmp/development-#{dump_name_suffix}.dump`
    end

    def local_database_name
      Rails.configuration.database_configuration[Rails.env]["database"]
    end

    def local_database_user
      `id -u -n`.strip
    end

    def download_heroku_database(app)
      `heroku pg:backups:download --app #{app}`
    end

    def import_database_locally
      `pg_restore --verbose --clean --no-acl --no-owner -h localhost -U #{local_database_user} -d #{local_database_name} #{@dump_file_name}`
    end

    def run_migrations
      `bin/rake db:migrate`
    end
  end
end
