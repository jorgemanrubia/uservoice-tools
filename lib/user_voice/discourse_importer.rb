require 'awesome_print'
require 'csv'

module UserVoice
  class DiscourseImporter
    attr_reader :user_voice_data_path

    def initialize(user_voice_data_path = '.')
      @user_voice_data_path = Pathname.new(user_voice_data_path)
    end

    def import
      import_users
      #import_suggestions
      #import_comments
    end

    private

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
      CSV.foreach(user_voice_data_path.join("users.csv"), headers: true) do |row|
        #puts "#{row['Id']}-#{row['Name']}-#{row['Email']}-#{row['Karma']}"
        ap row.to_hash
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
      CSV.foreach(user_voice_data_path.join("suggestions.csv"), headers: true) do |row|
        ap row.to_hash
      end
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
      CSV.foreach(user_voice_data_path.join("comments.csv"), headers: true) do |row|
        ap row.to_hash
      end
    end

  end
end

importer = UserVoice::DiscourseImporter.new('../../data')
importer.import
