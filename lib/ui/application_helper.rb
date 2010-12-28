module Appoxy

  module UI

    module ApplicationHelper

      def self.included(base)
#                puts self.class.name + " included in " + base.class.name
      end


      def current_url
        request.url
      end


      def flash_messages
        puts 'FLASH MESSAGE!'
        if flash.size > 0
          s = "<div class=\"flash_messages_container\">"
          s2 = ""
          flash.each_pair do |type, msg|
            if msg.is_a?(Array)
              msg.each do |m|
                s2 << content_tag(:div, m, :class => type)
              end
            else
              s2 << content_tag(:div, msg, :class => type)
            end
          end
          s << s2
          s << "</div>"
          s.html_safe
        end
      end

      def error_messages_for(ob)

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


    end

  end

end

