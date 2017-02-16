require 'gruff'
require 'pry'

class MyBar < Gruff::Bar
  def draw_legend
    return if @hide_legend

    # @legend_labels = @data.collect { |item| item[DATA_LABEL_INDEX] }
    @legend_labels = @data.collect { |item| item[DATA_LABEL_INDEX].to_s.concat("\n\n #{item[1].first}") }

    legend_square_width = @legend_box_size # small square with color of this item

    # May fix legend drawing problem at small sizes
    @d.font = @font if @font
    @d.pointsize = @legend_font_size

    label_widths = [[]] # Used to calculate line wrap
    @legend_labels.each do |label|
      metrics = @d.get_type_metrics(@base_image, label.to_s)
      label_width = metrics.width + legend_square_width * 2.7
      label_widths.last.push label_width

      if sum(label_widths.last) > (@raw_columns * 0.9)
        label_widths.push [label_widths.last.pop]
      end
    end

    # current_x_offset = center sum(label_widths.max) ###############
    # binding.pry
    # current_x_offset = label_widths.flatten.inject(:+) / 4.5*label_widths.length
    current_x_offset = 100
    # current_x_offset = 130#center(sum(label_widths.first))
    current_y_offset = @legend_at_bottom ? @graph_height + title_margin : (@hide_title ?
        @top_margin + title_margin :
        @top_margin + title_margin + @title_caps_height)

    @legend_labels.each_with_index do |legend_label, index|

      # Draw label
      @d.fill = @font_color
      @d.font = @font if @font
      @d.pointsize = scale_fontsize(@legend_font_size)
      @d.stroke('transparent')
      @d.font_weight = NormalWeight
      @d.gravity = WestGravity
      @d = @d.annotate_scaled(@base_image,
                              @raw_columns, 1.0,
                              current_x_offset + (legend_square_width * 1.7), current_y_offset + 23,
                              legend_label.to_s, @scale)

      # Now draw box with color of this dataset
      @d = @d.stroke('transparent')
      @d = @d.fill @data[index][DATA_COLOR_INDEX]
      @d = @d.rectangle(current_x_offset,
                        current_y_offset - legend_square_width / 2.0,
                        current_x_offset + legend_square_width,
                        current_y_offset + legend_square_width / 2.0)

      @d.pointsize = @legend_font_size
      metrics = @d.get_type_metrics(@base_image, legend_label.to_s)
      current_string_offset = metrics.width + (legend_square_width * 4) ###################

      # Handle wrapping
      label_widths.first.shift
      if label_widths.first.empty?
        debug { @d.line 0.0, current_y_offset, @raw_columns, current_y_offset }

        label_widths.shift
        current_x_offset = center(sum(label_widths.first)) unless label_widths.empty?
        line_height = [@legend_caps_height, legend_square_width].max + legend_margin
        if label_widths.length > 0
          # Wrap to next line and shrink available graph dimensions
          current_y_offset += line_height
          @graph_top += line_height
          @graph_height = @graph_bottom - @graph_top
        end
      else
        current_x_offset += current_string_offset
      end
    end
    @color_index = 0
  end
end

def default_theme
  {
    colors: ['#FCD443', '#FFB02F', '#FD5926', '#D91B36'],
    marker_color: '#e2e2e2',
    font_color: 'black',
    background_colors: 'white'
  }
end

# data = {"Low": 15, "Medium": 10, "High \n\n 29": 29, "Critical \n\n 10": 10}
data = {"Low": 15, "Medium": 10, "High": 29, "Critical": 10}

g = MyBar.new
g.theme = default_theme
g.minimum_value = 0
g.maximum_value = 25
g.y_axis_increment = 5
g.spacing_factor = 0.75
g.legend_margin = 100

      data.each do |data|
      g.data(data[0], data[1])
    end


g.write('exciting.png')
