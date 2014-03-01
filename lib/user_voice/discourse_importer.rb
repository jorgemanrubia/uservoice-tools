require 'csv'
require 'logging'

module UserVoice
  class DiscourseImporter
    attr_reader :user_voice_data_path, :admin_email, :users_by_uservoice_id, :admin_user, :topics_by_uservoice_id

    def initialize(user_voice_data_path = '.', admin_email)
      raise "You must set the 'ADMIN_EMAIL' environment variable#{admin_email}" unless admin_email.present?
      @user_voice_data_path = Pathname.new(user_voice_data_path)
      @admin_email = admin_email
      @admin_user = User.find_by_email(@admin_email)
      @users_by_uservoice_id = {}
      @topics_by_uservoice_id = {}
    end

    def import
      RateLimiter.disable
      delete_all
      import_suggestions
      import_comments
    end

    private

    def logger
      @@logger ||= begin
        logger = Logging.logger(STDOUT)
        logger.level = :debug
        logger
      end
    end

    def delete_all
      logger.info '** Deleting all...'

      User.where("email <> ?", admin_email).destroy_all
      Category.delete_all
      Topic.delete_all
      Post.delete_all
    end

    #{
    #    "Id" => "47477018",
    #    "Guid" => "",
    #    "Karma" => "5127",
    #    "Name" => "Jorge",
    #    "Email" => "jorge.manrubia@gmail.com",
    #    "Email Confirmed" => "true",
    #    "Last Login" => "2014-02-27 22:43",
    #    "Created At" => "2014-02-22 16:01",
    #    "Updated At" => "2014-02-28 11:31",
    #    "Referrer" => "",
    #    "Ip" => "37.11.31.110",
    #    "User Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/33.0.1750.117 Safari/537.36",
    #    "Accept Language" => "es,en;q=0.8",
    #    "Accept Charset" => "",
    #    "Host" => "support.zendone.com"
    #}
    def import_users
      each_row_in_csv('users') do |row|
        #puts "#{row['Id']}-#{row['Name']}-#{row['Email']}-#{row['Karma']}"
        #ap row.to_hash
      end
    end


    #{
    #    "Id" => "5555113",
    #    "Title" => "Make URLs in ToDos clickable",
    #    "Description" => "I have several recurring to-do items that are the URLs of websites I like to visit each day. It would be nice if the URLs were clickable to automatically open the website in a new tab/window of my browser. This is how it works in Microsoft Outlook (which I'm trying to move away from to zendone).",
    #    "Votes" => "5",
    #    "Supporters" => "0",
    #    "Comments" => "1",
    #    "Average Votes" => "0.00",
    #    "User Name" => "wbcarnes3",
    #    "User Email" => "",
    #    "User ID" => "47477125",
    #    "User Guid" => "",
    #    "Referrer" => "",
    #    "Ip" => "",
    #    "User Agent" => "",
    #    "Accept Language" => "",
    #    "Accept Charset" => "",
    #    "Host" => "",
    #    "Response Status" => "started",
    #    "Response Text" => "",
    #    "Response Created At" => "2012-06-07 10:21",
    #    "Response User Name" => "Jorge",
    #    "Response User Email" => "jorge.manrubia@gmail.com",
    #    "Forum ID" => "242371",
    #    "Forum Name" => " Ideas and Suggestions",
    #    "Category" => "",
    #    "Created At" => "2012-06-06 14:25",
    #    "Updated At" => "2014-02-22 16:35",
    #    "Last User Activity At" => "2012-06-07 10:21"
    #}
    def import_suggestions
      each_row_in_csv('suggestions') do |row|
        import_suggestion row
      end
    end

    def import_suggestion(user_voice_suggestion)
      title = user_voice_suggestion['Title']
      description = user_voice_suggestion['Description']
      author = find_or_create_user(user_voice_suggestion['User ID'], user_voice_suggestion['User Name'], user_voice_suggestion['User Email'])
      like_count = user_voice_suggestion['Votes']
      category = find_or_create_category(user_voice_suggestion['Forum Name'], user_voice_suggestion['Category'])

      logger.info("TOPIC: creating '#{user_voice_suggestion['Title']}' by #{author.email} (votes #{user_voice_suggestion['Votes']} on #{user_voice_suggestion['Created At']})")
      new_post = PostCreator.new(author, raw: description, title: title, category: category.name,
                                 skip_validations: true, created_at: user_voice_suggestion['Created At']).create

      new_post.topic.assign_attributes like_count: like_count, bumped_at: user_voice_suggestion['Created At']
      new_post.topic.save!(validate: false)

      topics_by_uservoice_id[user_voice_suggestion['Id']] = new_post.topic
    end

    def find_or_create_user(user_id, user_name, user_email)
      user_email = user_email.presence || email_from_user_name(user_name)
      user = users_by_uservoice_id[user_id] || User.find_by_email(user_email) || User.find_by_email(user_email) || create_user(user_name, user_email)
      users_by_uservoice_id[user_id] ||= user if user_id
      user
    end

    def create_user(user_name, email)
      user_name = to_valid_discourse_user_name(user_name)
      user_name = ensure_unique_username(user_name)
      email = to_valid_email(email, user_name)
      logger.info("USER: creating #{user_name} - #{email}")
      User.create!(username: user_name, email: email, password: '123456')
    end

    def ensure_unique_username(user_name)
      count = 1
      while User.find_by_username(user_name)
        user_name = "#{user_name}#{count}"
        count += 1
      end
      user_name
    end

    def to_valid_email(email, user_name)
      email.presence || email_from_user_name(user_name)
    end

    def to_valid_discourse_user_name(user_name)
      invalid_discourse_chars = /[^0-9A-Za-z_]/
      name = user_name.gsub(invalid_discourse_chars, '_')[0..14]
      name = name.gsub(/^(_)+/, '')
      name = "#{name}#{1234}" unless name.length >= 3
      name
    end

    def find_or_create_category(category_name, subcategory_name)
      category_name = category_name.strip
      subcategory_name = (subcategory_name.present? && "#{category_name}-#{subcategory_name.strip}") || nil

      category = Category.find_by_name(category_name) || Category.create!(name: category_name, user: admin_user)
      return category unless subcategory_name
      Category.create!(name: subcategory_name, user: admin_user, parent_category: category) unless Category.find_by_name(subcategory_name)
      category
    end

    def email_from_user_name(user_name)
      name = user_name.parameterize.gsub('-', '.')
      "#{name}.anonymous@zendone.com"
    end

    #{
    #    "Id" => "9456884",
    #    "Text" => "Hi Wegner,\r\n\n\nThanks for your support and your nice words. \r\n\nWe are really happy to have you on board for another year.\r\n\n\nBTW, this year will be awesome (zendone 2.0 is being cooked with lots of love)\r\n\n\nKind regards",
    #    "User Name" => "Pablo",
    #    "User Email" => "pmanrubia@gmail.com",
    #    "User Email Confirmed" => "true",
    #    "Status" => "",
    #    "Suggestion ID" => "5554398",
    #    "Suggestion Title" => "Wow, one year of paid subscription already! No regrets here.",
    #    "Forum ID" => "242375",
    #    "Forum Name" => " Praises",
    #    "Created At" => "2014-02-08 22:50",
    #    "Updated At" => "2014-02-22 16:03",
    #    "Referrer" => "",
    #    "Ip" => "",
    #    "User Agent" => "",
    #    "Accept Language" => "",
    #    "Accept Charset" => "",
    #    "Host" => ""
    #}
    def import_comments
      each_row_in_csv('comments') do |row|
        import_comment row
      end
    end

    def import_comment(uservoice_comment)
      description = uservoice_comment['Text']
      topic = find_or_create_topic(uservoice_comment['Suggestion ID'], uservoice_comment['Suggestion Title'])
      author = find_or_create_user(uservoice_comment['User Id'], uservoice_comment['User Name'], uservoice_comment['User Email'])

      logger.info("COMMENT: creating comment from '#{author.email}' in '#{topic.title}'")

      new_post = PostCreator.new(author, raw: description, skip_validations: true, topic_id: topic.id, created_at: uservoice_comment['Created At']).create
      new_post.topic.assign_attributes bumped_at: uservoice_comment['Created At']
      new_post.topic.save!(validate: false)

    rescue Exception => e
      logger.error "Error importing comment... #{e.message}"
    end

    def find_or_create_topic(user_voice_suggestion_id, user_voice_suggestion_title)
      sanitized_title = TextCleaner.clean_title(TextSentinel.title_sentinel(user_voice_suggestion_title).text)
      topics_by_uservoice_id[user_voice_suggestion_id] or Topic.where("title ilike ?", sanitized_title).first or
          Topic.where("title ilike ?", sanitized_title.gsub("!", '')).first or Topic.find_by_title(user_voice_suggestion_title) or raise "No suggestion found for id=#{user_voice_suggestion_id} and title='#{sanitized_title}'"
    end

    def each_row_in_csv(name, &block)
      CSV.foreach(user_voice_data_path.join("#{name}.csv"), headers: true, &block)
    end

  end
end

importer = UserVoice::DiscourseImporter.new('lib/data', ENV['ADMIN_EMAIL'])
importer.import
