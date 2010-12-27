# adds a to_pst method to Time
module TimePluginizer #  ActiveSupport::CoreExtensions::Time::Conversions

    def self.included(base) #:nodoc:
        base.class_eval do
            #puts 'TP mixing'
            # If we want to_s to ALWAYS be local, uncomment the below line
            #alias_method :to_s, :to_local_s #
        end
    end

    def to_pst
        return in_time_zone('Pacific Time (US & Canada)')
    end

    def to_user_time(user = nil)
        local = nil
        if user && user.time_zone
            local = in_time_zone(user.time_zone)
        else
            local = to_pst
        end
        local
    end

    def to_local_s(format = :default, user = nil)
        #puts 'calling to_local_s on ' + self.class.name
        zone = to_user_time(user)
        return zone.to_formatted_s(format)
    end

end

module StringTimezoner
    def to_user_time(user)
        tz = ActiveSupport::TimeZone.new(user.time_zone || 'Pacific Time (US & Canada)')
#        puts 'tz=' + tz.inspect
        t = tz.parse(self)
        return t
    end
end

Time.send :include, TimePluginizer
DateTime.send :include, TimePluginizer
#Date.send :include, TimePluginizer

String.send :include, StringTimezoner
