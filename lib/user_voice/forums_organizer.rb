require 'uservoice-ruby'

module UserVoice
  class ForumsOrganizer

    def client
      @client ||= UserVoice::Client.new(ENV['SUBDOMAIN_NAME'], ENV['API_KEY'], ENV['API_SECRET'], callback: ENV['URL'])
    end

    def move_categories_to_forums
      suggestions = client.get_collection("/api/v1/suggestions?sort=newest")

      puts "Total suggestions: #{suggestions.size}"

      suggestions.each do |suggestion|
        puts "#{suggestion['title']}: #{suggestion['url']}"
      end
    end
  end
end

organizer = UserVoice::ForumsOrganizer.new
organizer.move_categories_to_forums
