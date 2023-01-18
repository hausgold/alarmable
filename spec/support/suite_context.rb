# frozen_string_literal: true

# Print some information
puts
puts <<DESC
  -------------- Versions --------------
            Ruby: #{"#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}"}
      Active Job: #{ActiveJob.version}
   Active Record: #{ActiveRecord.version}
  Active Support: #{ActiveSupport.version}
  --------------------------------------
DESC
puts
