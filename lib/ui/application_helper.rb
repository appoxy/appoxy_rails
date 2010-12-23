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
                s = ""
                flash.each_pair do |type, msg|
                    if msg.is_a?(Array)
                        msg.each do |m|
                            s << content_tag(:div, m, :class => type)
                        end
                    else
                        s << content_tag(:div, msg, :class => type)
                    end
                end
                s.html_safe
            end

        end

    end

end

