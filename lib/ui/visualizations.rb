module Appoxy
  module UI
    class Visualizations

      def pie(options={})

         div_id = options[:title].underscore || "pie_div"
    width  = options[:width] || "100%"
    height = options[:height] || nil
        s      = <<-EOF
    <div id="#{div_id}" style="width:#{200}; #{height ? 'height:' + height : ""}"></div>

    <script type="text/javascript">
    var age_pie_chart;
    $(document).ready(function() {
       age_pie_chart = new Highcharts.Chart({
          chart: {
             renderTo: '#{div_id}',
             plotBackgroundColor: null,
             plotBorderWidth: null,
             plotShadow: false
          },
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
        EOF
        if options[:title]
          s << "title: {
             text: '#{options[:title]}'
          },"
        end

        s << "
          tooltip: {
             formatter: function() {
                return '<b>'+ this.point.name +'</b>: '+ this.y;
             }
          },
    "

        s << "
           series: [{
             type: 'pie',
             name: '#{options[:title]}',
             data: [
    "
        data = options[:data]
        data.each_with_index do |d, i|
          # todo: should check for hash and allow like:
          #  {
          #               name: 'Chrome',
          #               y: 12.8,
          #               sliced: true,
          #               selected: true
          #            },
          s << "['#{d[0]}', #{d[1]}]"
          if i < data.size - 1
            s << ",\n"
          end
        end
        s << "]
          }]
       });
    });
    </script>\n"
        s.html_safe

      end
    end

  end


end
