require 'uservoice-ruby'
require 'awesome_print'

module UserVoice
  class ForumsOrganizer
    attr_reader :category_ids_by_title
    attr_reader :forums_by_name

    def initialize
      @forums_by_name = {}
    end

    def client
      @client ||= UserVoice::Client.new('zendone', ENV['API_KEY'], ENV['API_SECRET'], callback: ENV['URL'])
    end

    def move_category_to_forum_for_all_suggestions
      suggestions = client.get_collection("/api/v1/suggestions")

      puts "Processing #{suggestions.size} suggestions..."

      suggestions.each do |suggestion|
        move_category_to_forum_for(suggestion)
      end
    end

    def delete_all_users_without_email
      client.login_as_owner do |owner|
        users = owner.get_collection("/api/v1/users")

        puts "Processing #{users.size} users..."

        delete_all_users(owner, users)
      end
    end

    def print_all_users
      users = client.get_collection("/api/v1/users")

      puts "Processing #{users.size} users..."

      users.each do |user|
        puts "#{user['id']}-#{user['name']}"
      end
    end

    #def link_account(user_voice_id, email)
    #  client.login_as_owner do |owner|
    #    user_url = "/api/v1/users/#{user_voice_id}.json"
    #    user = owner.get user_url
    #    ap user
    #    #user['user']['email'] = email
    #    owner.put user_url, {
    #        user: {
    #            id: user_voice_id,
    #            email: 'some@email.com'
    #        }
    #    }
    #  end
    #end

    private

    def move_category_to_forum_for(suggestion)
      begin
        return unless suggestion
        forum_name = suggestion['category']['name']
        category_name = suggestion['topic']['forum']['name']
        puts "Moving '#{suggestion['title']}' to forum '#{forum_name}' with category '#{category_name}'"
        move_suggestion_to_forum(suggestion, forum_name, category_name)
      rescue Exception => e
        puts "ERROR when moving '#{suggestion['title']}': #{e.message} - #{e.inspect}"
      end
    end

    def move_suggestion_to_forum(suggestion, forum_name, category_name)
      current_forum_id = suggestion['topic']['forum']['id']
      forum_id = forum_by_name(forum_name)['id']
      suggestion['category_name'] = category_name
      suggestion['forum_id'] = forum_id
      client.put("/api/v1/forums/#{current_forum_id}/suggestions/#{suggestion['id']}.json", suggestion: suggestion)
    end

    def forum_by_name(forum_name)
      forums_by_name[forum_name] || find_forum_by_name(forum_name) || create_forum(forum_name)
    end

    def find_forum_by_name(forum_name)
      found_forum = nil
      # no, Enumerable#find method won't work wiith UserVoice collections
      client.get_collection('/api/v1/forums').each do |forum|
        found_forum = forum if forum['name'] == forum_name
      end
      forums_by_name[forum_name] = found_forum if found_forum
      found_forum
    end

    def create_forum(forum_name)
      puts "Creating forum #{forum_name}..."
      client.post '/api/v1/forums.json',
                  forum: {
                      name: forum_name
                  }
    end

    def delete_all_users(owner, users)
      total = users.size
      index = 1 # no #with_index, user_voice collections are not enumerables
      users.each do |user|
        puts "Deleting user #{user['id']} - #{user['name']} (#{index}/#{total})"
        delete_user(owner, user) if !user['email'] || user['email'].strip.empty?
        index += 1
      end
    end

    def delete_user(owner, user)
      begin
        do_delete_user(owner, user)
      rescue Exception => e
        puts "Error when deleting #{user['name']}: #{e.message}"
      end
    end

    def do_delete_user(owner, user)
      owner.delete "/api/v1/users/#{user['id']}.json", user: user
    end
  end
end

organizer = UserVoice::ForumsOrganizer.new
organizer.move_category_to_forum_for_all_suggestions
#organizer.print_all_users
#organizer.delete_all_users_without_email
#organizer.link_account 47465191, 'jorge.manrubia@gmail.com'


