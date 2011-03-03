require_relative 'binding_hack'
require_relative 'visualizations'


module Appoxy

  module UI

    # To use, include in your ApplicationHelper.
    # include Appoxy::UI::ApplicationHelper
    module ApplicationHelper

      def self.included(base)
#                puts self.class.name + " included in " + base.class.name
      end

      def current_url
        request.url
      end

      def base_url
        r = "#{request.protocol}#{request.host}"
        if request.port != 80
          r << ":#{request.port}"
        end
        @base_url = r
        r
      end


      # todo: add themes support http://www.stemkoski.com/jquery-ui-1-7-2-themes-list-at-google-code/
      def appoxy_javascripts
        '<script type="text/javascript" src="http://www.google.com/jsapi?key=ABQIAAAAhes0f80sBcwL-h5xCNkkgxQBmiBpQeSpIciQPfZ5Ss-a60KXIRQOVvqzsNpqzhmG9tjky_5rOuaeow"></script>
        <script type="text/javascript">
            google.load("jquery", "1");
            google.load("jqueryui", "1");
        </script>
      '.html_safe
      end

      # Place in application.html.erb in head to get default Appoxy style elements and javascripts.
      def appoxy_header
        # stylesheets and what not could either be included in this gem or links to s3

        # include google javascript for jquery and jquery-ui and perhaps jquery tools
        ret = appoxy_javascripts
        ret.html_safe
      end

      def appoxy_footer
        ret = ''

        if current_user # && current_user.time_zone.blank?
          ret += '
    <script type="text/javascript">
        $(document).ready(function() {
            var myDate = new Date();
            var tz_offset = -(myDate.getTimezoneOffset() / 60);
//            document.write(tz_offset);
            $.post("/users/' + current_user.id + '/timezone", { offset: tz_offset })
        });
    </script>'
        end

        if defined?(RELEASE_INFO)
          ret += '<div style="clear:both; margin-top:15px;"
          class="instance_info_div">' + INSTANCE_INFO["instance_id"] + ':
          Revision ' + RELEASE_INFO["scm"]["revision"][0..5] + ' built on ' +
              RELEASE_INFO["deploy_date"] + '</div>'
        end

        if ::Rails.env == "development"
          ret += '<div style="margin-top: 10px;">' + ERB::Util.html_escape(SimpleRecord.stats.inspect) + '</div>'
        end
        ret.html_safe
      end

      # options:
      #   :format=>:long, default = :long
      #   :user=> a User object, if not specified will use @current_user
      def date_format(date, options={})
        format = options[:format] || :long
#        puts 'date_format on ' + date.class.name + " --- " + date.inspect
        user   ||= @current_user
        return '' if date.nil?
        date = Time.parse(date) if date.is_a?(String)
        if date.is_a?(Date) && !date.is_a?(DateTime) && !date.is_a?(Time)
          return date.to_formatted_s(format)
        end
        return date.to_local_s(user, :format=>format)
      end

      def flash_messages
        if flash.size > 0
          s  = "<div class=\"flash_messages_container\">"
          s2 = ""
          flash.each_pair do |type, msg|
            if msg.is_a?(Array)
              msg.each do |m|
                s2 << content_tag(:div, m, :class => "flash #{type}")
              end
            else
              s2 << content_tag(:div, msg, :class => "flash #{type}")
            end
          end
          s << s2
          s << "</div>"
          s.html_safe
        end
      end

      def error_messages_for(ob)
        return '' if ob.nil?
        if ob.errors.size > 0
          s  = "<div class=\"error_message_for_container\">"
          s2 = ""
          ob.errors.full_messages.each do |msg|
            s2 << content_tag(:div, msg, :class => "error_message_for")
          end
          s << s2
          s << "</div>"
          s.html_safe
        end
      end

      # Helper for getting user's geo location and storing it on User object.
      # options:
      #   :show_map=>"#div_to_show_on" - This will display a tiny map of location
      #
      def appoxy_geo_finder(options={})
#        ret = File.read('_geo_location_finder.html.erb')
        options.merge!({:current_user=>current_user})
        options  = Appoxy::UI::BindingHack.new(options)
        template = ERB.new(File.read(File.join(File.dirname(__FILE__), '_geo_location_finder.html.erb')))
        ret      = template.result(options.get_binding)
        ret.html_safe
      end

      # feed_url: url to atom or rss feed
      # options:
      #   :div_id => default is "news_feed"
      def latest_news(feed_url, options={})
        div_id = options[:div_id] || "news_feed"
                s = <<-EOF
<div id="#{div_id}"></div>

<script type="text/javascript">

      google.load("feeds", "1");

      function #{div_id}_init() {
          var feed = new google.feeds.Feed("#{feed_url}");
          feed.setNumEntries(3)
          feed.load(function(result) {
              if (!result.error) {
                  var container = $("##{div_id}");
                  for (var i = 0; i < result.feed.entries.length; i++) {
                      var entry = result.feed.entries[i];
                    container.append('<div><div class="blog_title"><a href="' + entry.link + '">' + entry.title + '</a></div>'
                    + '<div class="blog_body">' + entry.contentSnippet + '</div>'
                    + '<div class="blog_date">' + entry.publishedDate + '</div>'
                    + '</div>');
                  }
              }
          });
      }
      google.setOnLoadCallback(#{div_id}_init);
</script>
EOF
        s.html_safe
      end

      def visualizations
        Visualizations.new
      end

    end

  end

end

