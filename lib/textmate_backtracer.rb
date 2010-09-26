if defined?(Rails.backtrace_cleaner)
  # This is just a way to get around ActiveSupoprt's html_escape method which
  # doesn't take into account safe stings that may be joined. If all the
  # array's strings are safe, we assume the separator is safe, and make the
  # whole joined string safe.
  class Array
    def join_with_safety(sep=$,)
      result = join_without_safety(sep)
      if all?{|e| e.to_s.html_safe?}
        result.html_safe
      else
        result
      end
    end
    alias_method_chain :join, :safety
  end
  
  # activesupport (3.0.0) lib/active_support/whiny_nil.rb:48:in `method_missing'
  # app/controllers/job_queues_controller.rb:5:in `index'
  Rails.backtrace_cleaner.add_filter do |line|
    if match = line.match(/(.*) \(.*\) (.*):(\d+):in `.*'/)
      _, gem_name, file_path, line_number = match.to_a
      if spec = Bundler.load.specs.find{|s| s.name == gem_name }
        gem_path = spec.full_gem_path
        file = gem_path + '/' + file_path
        "<a href='txmt://open?url=file://#{file}&line=#{line_number}'>#{line}</a>".html_safe
      else
        line
      end
    elsif match = line.match(/(.*):(\d+):in `.*'/)
      _, app_path, line_number = match.to_a
      file = Rails.root.join(app_path)
      "<a href='txmt://open?url=file://#{file}&line=#{line_number}'>#{line}</a>".html_safe
    else
      line
    end
  end
  
  # Remove all the silencers, which will *certainly* break anyone else's silencers.
  # Well. Don't use silencers in development mode. ;)
  Rails.backtrace_cleaner.remove_silencers!
  
  # Add back a modified "APP_DIRS_PATTERN" from Rails' railties backtrace_cleaner.rb.
  Rails.backtrace_cleaner.add_silencer { |line| line !~ /^(<.*>)?\/?(app|config|lib|test)/ }
else
  class Exception
    alias :original_clean_backtrace :clean_backtrace
  
    def add_links_to_backtrace(lines)
      lines.collect do |line|
        expanded = line.gsub '#{RAILS_ROOT}', RAILS_ROOT
        if match = expanded.match(/^(.+):(\d+):in/) or match = expanded.match(/^(.+):(\d+)\s*$/)
          file = File.expand_path(match[1])
          line_number = match[2]
          html = "<a href='txmt://open?url=file://#{file}&line=#{line_number}'>#{line}</a>"
        else
          line
        end
      end
    end

    def clean_backtrace
      add_links_to_backtrace(original_clean_backtrace)
    end
  end
end