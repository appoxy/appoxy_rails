module Appoxy
  module UI
    class Visualizations


      def add_tooltip
        "
          tooltip: {
             formatter: function() {
                return '<b>'+ this.point.name +'</b>: '+ this.y;
             }
          },
    "
      end

      def pie(options={})

        @type    = 'pie'

        @options = options
        common_values(options)

        s = ""
        s << add_div()
        s << add_chart_start()
        s << "
        plotOptions: {
             pie: {
                allowPointSelect: true,
                cursor: 'pointer',
                dataLabels: {
                   enabled: false,
                   color: '#000000',
                   connectorColor: '#000000',
                   formatter: function() {
                      return '<b>'+ this.point.name +'</b>: '+ this.y +' %';
                   }
                },
                showInLegend: true
             }
          },
        "
        s << add_title

        s << add_tooltip()

        unless @options[:series]
          # make the default series
          serieses = [{:name=>options[:title, :data=>options[:data]]}]
          @options[:series] = serieses
        end

        if @options[:series]
          s << add_series
        else
          # todo: DELETE THIS SECTION
          # Single set of data
#          s << "
#           series: [{
#             type: '#{@type}',
#             name: '#{options[:title]}',
#             data: [
#    "
#          s << add_data
#          s << "]
#          }]"
        end
        s << "
       });
    });
    </script>\n"
        s.html_safe

      end

      def add_series
        s      = "series: [
"
        series = @options[:series]
        series.each_with_index do |ser, i|
          # each series is a hash
          s << "{
             type: '#{@type}',
             name: '#{ser[:name]}',
             data: ["
          s << add_data(ser[:data])
          s << "
          }
          "
          if i < series.size - 1
            s << ",\n"
          end
        end
        s
      end

      def add_data(data)
        s    = ""
#        data ||= @options[:data]
        if data.is_a?(Array)
          data.each_with_index do |d, i|
            if d.is_a?(Array)
              s << "['#{d[0]}', #{d[1]}]"
            elsif d.is_a?(Hash)
              s << "
                  {
                         name: '#{d[:name]}',
                         y: #{d[:y]}
                         // sliced: #{d[:sliced]},
                         // selected: #{d[:selected]}
                      }"
            else
              raise "Expected array or hash for data series elements."
            end
            if i < data.size - 1
              s << ",\n"
            end
          end
        end
        s
      end


      def add_div
        "<div id=\"#{@div_id}\" style=\"width:#{@width}; #{@height ? 'height:' + @height : ""}\"></div>"
      end

      def add_chart_start
        "<script type=\"text/javascript\">
    var #{@id}_chart;
    $(document).ready(function() {
       #{@id}_chart = new Highcharts.Chart({
          chart: {
             renderTo: '#{@div_id}',
             plotBackgroundColor: null,
             plotBorderWidth: null,
             plotShadow: false,
             defaultSeriesType: '#{@type}'
          },
"
      end

      def add_title
        s= ""
        if @options[:title]
          s << "title: {
             text: '#{@options[:title]}'
          },"
        end
        ""
      end

      def common_values(options)
        @id     = options[:title].underscore
        @div_id = "#{@id}_div" || "#{@type}_div"
        @width  = options[:width] || "100%"
        @height = options[:height] || nil
      end
    end

  end


end
