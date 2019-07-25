namespace :tools do
  desc "指定チャンネルに全ユーザを追加する"
  task :add_user, ['channel_id'] => :environment do |task, args|
    Rails.logger.info "hello!! add users to channel token=#{Slack.config.token} channel_id=#{args.channel_id}"

    if args.channel_id.blank?
      Rails.logger.error "error. channel_id is empty!"
    else

      client = Slack::Web::Client.new
      client.auth_test

      all_members = []
      client.users_list(presence: true, limit: 500, sleep_interval: 5, max_retries: 20) do |response|
        all_members.concat(response.members)

        Rails.logger.info "fetch members: #{all_members.size}"
      end

      Rails.logger.info "fetch members:#{all_members.size}"

      members = all_members.select { |u| u.deleted == false and u.is_bot == false and u.id != "USLACKBOT"}
      members = members.select { |u|  u.is_restricted == false and u.is_ultra_restricted == false }

      Rails.logger.info "fetch members by filter:#{members.size}"

      batch_size = 30
      process_count = 0
      members.in_groups_of(batch_size, false).each do |g|
        begin
          users = g.map { |x| x['id'] }.join(',')
          #client.conversations_invite(channel: args.channel_id, users: users)
          process_count = process_count + batch_size
          Rails.logger.info "#{process_count}/#{members.size} invite:#{users}"
          sleep(1)
        rescue  => e
          puts "warn."
          puts e
        end
      end

      Rails.logger.info "success."
    end     
  end

  desc "チャンネル一覧を表示する"
  task :channels, ['name'] => :environment do |task, args|
    puts "hello! token=#{Slack.config.token} name=#{args.name}"

    client = Slack::Web::Client.new
    client.auth_test

    channels = []
    client.conversations_list(presence: true, limit: 1000, sleep_interval: 1, max_retries: 20) do |response|
      list = response['channels']
      channels.concat(list)

      puts "fetch channel: #{channels.size}"
    end

    unless args.name.blank?
      channels = channels.detect { |c| c.name.downcase.include?(args.name.downcase) }
    end

    puts "find: #{channels.size}"

    puts channels

  end

end
