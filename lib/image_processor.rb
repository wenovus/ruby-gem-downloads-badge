require 'rsvg2'
class ImageProcessor

    def initialize(input, mode, options ={})
        @svg = input
        @mode = mode
        @mode = :jpeg if @mode == :jpg
        @options = options.is_a?(Hash) ? options.symbolize_keys : {}
        @handle = RSVG::Handle.new_from_data(@svg)
    end

    def process
        case @mode
        when :jpeg, :jpg, :png  then render_image
    #    when :pdf, :ps          then render
        else raise Svg2pdf::UnsupportedFormatError, "Invalid output format: %s" % @mode.to_s
        end
    end

    # def render
    #   setup
    #   @context = create_context @options[:output_file]
    #   @context.target.finish
    #   File.new @options[:output_file]
    # end

    def render_image
        setup
        @context = create_context Cairo::FORMAT_ARGB32

        if @mode == :png
            b = StringIO.new
            @context.target.write_to_png(b)
            @context.target.finish
            return b.string
        else
            # b = StringIO.new
            # @context.target.write_to_png(b)
            # @context.target.finish
            # #return b.string
            #
            # @pixbuf = Gdk::Pixbuf.new(:data => b.string,
            # :colorspace => :rgb,
            # :has_alpha => false,
            # :bits_per_sample => 8,
            # :width => @width, :height => @height,
            # :rowstride => 1)
            #
            # output_String = StringIO.new
            # @pixbuf.save(output_String, @mode.to_s)
            #return output_String.string

            temp = Tempfile.new("svg2", encoding: 'utf-8')
            ObjectSpace.undefine_finalizer(temp)

            @context.target.write_to_png(temp.path)
            @context.target.finish
            @pixbuf = Gdk::Pixbuf.new(temp.path)
            new_file = @tempfile = Tempfile.new(@mode.to_s, encoding: 'utf-8')
            ObjectSpace.undefine_finalizer(new_file)

            @pixbuf.save(new_file.path, @mode.to_s)

            output = File.read(new_file.path)
            FileUtils.rm_rf(temp.path) if File.exists?(temp.path)
            FileUtils.rm_rf(new_file.path) if File.exists?(new_file.path)
            return output
        end
    end


    def setup
        @ratio = @options[:ratio].present? ? options[:ratio].to_i : 1
        @dim = @handle.dimensions
        @width = @dim.width * @ratio
        @height = @dim.height * @ratio

        surface_class_name = case @mode
        when :jpg, :jpeg, :png, :gif  then "ImageSurface"
    #    when :ps                then "PSSurface"
    #    when :pdf               then "PDFSurface"
        end
        @surface_class = Cairo.const_get(surface_class_name)
    end

    def create_context(arg)
        surface = @surface_class.new(arg, @width, @height)
        context = Cairo::Context.new(surface)
        context.scale(@ratio, @ratio)
        context.render_rsvg_handle(@handle)
        context
    end

end