require "ghost_writer/version"
require "active_support/concern"

module GhostWriter
  extend ActiveSupport::Concern

  mattr_accessor :output_dir

  def generate_api_doc
    @@output_path = @@output_dir ? Rails.root + "doc" + @@output_dir : Rails.root + "doc" + "api_examples"
    unless File.exist?(doc_dir)
      FileUtils.mkdir_p(doc_dir)
    end

    doc = File.open(File.join(doc_dir, "#{doc_name}.markdown"), "w")

    doc.puts headword("#{described_class} #{doc_name.titleize}", 1)
    doc.puts headword("access path:", 2)
    doc.puts quote("#{request.env["REQUEST_METHOD"]} #{request.env["PATH_INFO"]}")
    doc.puts ""
    doc.puts headword("request params:", 2)
    doc.puts quote(controller.params.reject {|key, val| key == "controller" || key == "action"}.inspect, :ruby)
    doc.puts ""
    doc.puts headword("status code:", 2)
    doc.puts quote(response.status.inspect)
    doc.puts ""
    doc.puts headword("response:", 2)
    if controller.params[:format] && controller.params[:format].to_sym == :json
      puts_json_data(doc)
    else
      doc.puts quote(response.body)
    end
    doc.puts ""
    doc.puts "Generated by \"#{example.full_description}\" at #{example.location}"
    doc.puts ""
    doc.close
  end

  private
  def doc_dir
    @@output_path + described_class.to_s.underscore
  end

  def doc_name
    if example.metadata[:generate_api_doc].is_a?(String) || example.metadata[:generate_api_doc].is_a?(Symbol)
      example.metadata[:generate_api_doc].to_s
    else
      controller.action_name
    end
  end

  # TODO: outputのフォーマットを選択可能に
  def headword(text, level = 1)
    "#{'#'*level} #{text}\n"
  end

  def paragraph(text)
    text + "\n\n"
  end

  def quote(text, quote_format = nil)
    "```#{quote_format}\n#{text}\n```"
  end

  def puts_json_data(doc)
    data = ActiveSupport::JSON.decode(response.body)
    if data.is_a?(Array) || data.is_a?(Hash)
      doc.puts quote(JSON.pretty_generate(data), :javascript)
    else
      doc.puts quote(data)
    end
  end

  included do
    after do
      if example.metadata[:type] == :controller && example.metadata[:generate_api_doc]
        generate_api_doc if ENV["GENERATE_API_DOC"]
      end
    end
  end
end
