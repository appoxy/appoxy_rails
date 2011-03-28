require 'aws'
require 'simple_record'

module Appoxy
  module Sessions
    module Shareable

      # Call this method on your Sharable object to share it with the person.
      # returns: a hash with :user (the user that the item was shared with), :ac (activation code that should be sent to the user)
      #          or false if couldn't be shared.
      # You can check for errors by looking at the errors array of the object.
      # Eg:
      #   if my_ob.share_with(x)
      #      # all good
      #      Mail the user a link that contains user_id and ac, this gem will take care of the rest.
      #   else
      #      # not all good, check errors
      #      errors = my_ob.errors
      #   end

      def share_with(email, access_rights={}, options={})

        access_rights = {} if access_rights.nil?

        @email = email.strip

        if @email == self.user.email
          self.errors.add_to_base("User already owns this item.")
          return false
        end

        user = ::User.find_by_email(@email)
        if user.nil?
          # lets create the user and send them an invite.
          user = ::User.new(:email=>@email, :status=>"invited")
          user.set_activation_code # todo: this shouldn't be on user anymore
          if user.save

          else
            self.errors = user.errors
            return false
          end
        end
        activation_code = user.activation_code

        # check if exists
        share_domain = self.share_domain
        item_id_name = self.item_id_name
#                puts 'share_domain = ' + share_domain.inspect
        @sdb = SimpleRecord::Base.connection
#        @shared_with = share_class.find(:first, :conditions=>["user_id = ? and item_id = ?", user.id, @item.id])
        @project_user = Shareable.get_results(:first, ["select * from #{share_domain} where user_id=? and #{item_id_name} = ?", user.id, self.id])
        puts 'sharing user=' + @project_user.inspect
        unless @project_user.nil?
          self.errors.add_to_base("This item is already shared with #{email}.")
          return false
        end

        now = Time.now
        id = share_id(user)
        @sdb.put_attributes(share_domain, id, {:new_share=>true,
                                               :id=>id,
                                               :created=>SimpleRecord::Translations.pad_and_offset(now),
                                               :updated=>SimpleRecord::Translations.pad_and_offset(now),
                                               :user_id => user.id,
                                               :activation_code=>activation_code,
                                               :status=>"invited",
                                               item_id_name => self.id}.merge(access_rights),
                            true,
                            :create_domain=>true)

#                ret = {
#                        :user=>user,
#                        :ac=>activation_code
#                }
#                return ret
        return user

      end

      def item_id_name
        return self.class.name.foreign_key
      end

      def common_attributes
        ["new_share", "id", "created", "updated", "user_id", item_id_name]
      end

      # Returns a list of users that this item is shared with.
      def shared_with
        project_users = Shareable.get_results(:all, ["select * from #{share_domain} where #{item_id_name} = ?", self.id])
        user_ids = []
        options_hash = {}
        project_users.each do |puhash|
          puhash.each_pair do |k, v|
            puhash[k] = v[0]
          end
          puts 'puhash=' + puhash.inspect
          user_ids << puhash["user_id"]
          options_hash[puhash["user_id"]] = puhash
        end
        ret = ::User.find(:all, :conditions=>["id in ('#{user_ids.join("','")}')"]).collect do |u|
          def u.share_options=(options=nil)
            instance_variable_set(:@share_options, options)
          end

          def u.share_options
            instance_variable_get(:@share_options)
          end

          u.share_options=options_hash[u.id]
          u
        end
        ret
      end

      # this unshares by the
      def unshare_by_id(id)
#        @project_user = ProjectUser.find(params[:pu_id])
#        @project_user.delete
#                puts 'unsharing ' + id.to_s
        @sdb = SimpleRecord::Base.connection
        puts "delete_attributes=" + @sdb.delete_attributes(share_domain, id.to_s).inspect
#                puts 'deleted?'
      end

      # Unshare by user.
      def unshare(user)
        @sdb = SimpleRecord::Base.connection
        @sdb.delete_attributes(share_domain, share_id(user))
#                @project_user = Shareable.get_results(:first, ["select * from #{share_domain} where user_id=? and #{item_id_name} = ?", user.id, self.id])
#                @project_user.each do |pu|
#                    @sdb.delete_attributes(share_domain, pu["id"])
#                end
      end

      def update_sharing_options(user, options={})
        options={} if options.nil?
#                puts 'options=' + ({ :updated=>Time.now }.merge(options)).inspect
        @sdb = SimpleRecord::Base.connection
        @project_user = Shareable.get_results(:first, ["select * from #{share_domain} where user_id=? and #{item_id_name} = ?", user.id, self.id])
        # compare values
        to_delete = []
        @project_user.each_pair do |k, v|
          if !common_attributes.include?(k) && !options.include?(k)
            to_delete << k
          end
        end
        if to_delete.size > 0
          puts 'to_delete=' + to_delete.inspect
          @sdb.delete_attributes(share_domain, share_id(user), to_delete)
        end
        @sdb.put_attributes(share_domain, share_id(user), {:updated=>Time.now}.merge(options), true)

      end

      def share_id(user)
        "#{self.id}_#{user.id}"
      end

      def share_domain
#                puts 'instance share_domain'
        ret = self.class.name + "User"
#                puts 'SHARE_NAME=' + ret
        ret = ret.tableize
#                puts 'ret=' + ret
        ret
      end


      def self.get_results(which, q)
        @sdb = SimpleRecord::Base.connection
        next_token = nil
        ret = []
        begin
          begin
            response = @sdb.select(q, next_token)
            rs = response[:items]
            rs.each_with_index do |i, index|
              puts 'i=' + i.inspect
              i.each_key do |k|
                puts 'key=' + k.inspect
                if which == :first
                  return i[k].update("id"=>k)
                end
                ret << i[k]
              end
#    break if index > 100
            end
            next_token = response[:next_token]
          end until next_token.nil?
        rescue Aws::AwsError, Aws::ActiveSdb::ActiveSdbError
          if ($!.message().index("NoSuchDomain") != nil)
            puts 'NO SUCH DOMAIN!!!'
            # this is ok
          else
            raise $!
          end
        end
        which == :first ? nil : ret
      end

    end
  end
end
	