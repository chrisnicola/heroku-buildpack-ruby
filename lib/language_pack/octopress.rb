require "language_pack"
require "language_pack/rack"

# Rack Language Pack. This is for any non-Rails Rack apps like Sinatra.
class LanguagePack::Rack < LanguagePack::Ruby

  # detects if this is a valid Rack app by seeing if "config.ru" exists
  # @return [Boolean] true if it's a Rack app
  def self.use?
    super && File.exist?("config.ru") && rake_task_defined?("generate")
  end

  def name
    "Ruby/Octopress"
  end

  def default_process_types
    # let's special case thin here if we detect it
    web_process = gem_is_bundled?("thin") ?
                    "bundle exec rackup -s thin -p $PORT" :
                    "bundle exec rackup config.ru -p $PORT"

    super.merge({
      "web" => web_process
    })
  end

private

  def run_assets_precompile_rake_task
    log("assets_precompile") do
      if rake_task_defined?("generate")
        topic("Generating Octopress static files")
        puts "Running: rake generate"
        require 'benchmark'
        time = Benchmark.realtime { pipe("env PATH=$PATH:bin bundle exec rake generate 2>&1") }
        if $?.success?
          log "assets_precompile", :status => "success"
          puts "Octopress generate completed (#{"%.2f" % time}s)"
        else
          log "assets_precompile", :status => "failure"
          puts "Octopress generate failed"
          exit 1
        end
      end
    end
  end
end

