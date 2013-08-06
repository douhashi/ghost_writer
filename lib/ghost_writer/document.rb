class GhostWriter::Document
  attr_reader :title, :description, :location, :url_example, :param_example, :status_example, :response_example, :output, :relative_path

  def initialize(output, attrs)
    format_module = "GhostWriter::Format::#{attrs[:format].to_s.classify}"
    extend(format_module.constantize)

    @output           = output
    @relative_path    = Pathname.new(output).relative_path_from(GhostWriter.output_path)
    @title            = attrs[:title]
    @description      = attrs[:description]
    @location         = attrs[:location]
    @url_example      = attrs[:url_example]
    @param_example    = attrs[:param_example]
    @status_example   = attrs[:status_example]
    @response_example = attrs[:response_example]
  end

  def write_file(overwrite = false)
    unless File.exist?(File.dirname(output))
      FileUtils.mkdir_p(File.dirname(output))
    end

    mode = overwrite ? "w" : "a"
    doc = File.open(output, mode)

    if overwrite
      doc.write paragraph(document_header)
    end

    doc.write(document_body)

    doc.close
  end

  def document_header
    <<EOP
#{headword(title, 1)}

#{separator(32)}

EOP
  end

  def document_body
    <<EOP
#{headword(description, 2)}

#{headword("access path:", 3)}
#{quote(url_example)}

#{headword("request params:", 3)}
#{quote(param_example.inspect, :ruby)}

#{headword("status code:", 3)}
#{quote(status_example)}

#{headword("response:", 3)}
#{quote_response(response_example)}

Generated by "#{description}\" at #{location}

#{separator(32)}
EOP
  end

  private
  def quote_response(body)
    if param_example[:format] && param_example[:format].to_sym == :json
      quote(arrange_json(response_example), :javascript)
    else
      quote(response_example, param_example[:format])
    end
  end

  def arrange_json(body)
    data = ActiveSupport::JSON.decode(body)
    if data.is_a?(Array) || data.is_a?(Hash)
      JSON.pretty_generate(data)
    else
      data
    end
  rescue MultiJson::DecodeError
    body
  end
end
