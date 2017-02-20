class Image
  def initialize(file_path)
    @file_path = file_path
    self.class.send(:attr_accessor, "file_path")

    self.class.send(:attr_accessor, "raw_text")
    self.class.send(:attr_accessor, "amount")
    self.class.send(:attr_accessor, "frequency")
    self.class.send(:attr_accessor, "delivery")
    self.class.send(:attr_accessor, "drug_name")
  end

  def convert_to_text
    @files = File.new(file_path)
    @data  = OcrSpace::FilePost.post('/parse/image', body: { apikey: "0ad729224588957", language: "eng", isOverlayRequired: false, file: @files })
    if @data.parsed_response["ErrorMessage"].present?
      raise StandardError.new(@data.parsed_response["ErrorMessage"][0]) and return
    end

    self.raw_text = @data.parsed_response['ParsedResults'][0]["ParsedText"].gsub(/\r|\n/, "")
    return self.raw_text
  end

  def convert_to_text_from_base64(base64)
    @data  = OcrSpace::FilePost.post('/parse/image', body: { apikey: "0ad729224588957", language: "eng", isOverlayRequired: false, base64image: base64})
    if @data.parsed_response["ErrorMessage"].present?
      raise StandardError.new(@data.parsed_response["ErrorMessage"][0]) and return
    end

    self.raw_text = @data.parsed_response['ParsedResults'][0]["ParsedText"].gsub(/\r|\n/, "")
    return self.raw_text
  end

  # def convert_to_text_from_base64(base64)
  #   path = Rails.root.join('tmp') + "#{SecureRandom.hex}.jpeg"
  #   File.open(path, "wb+") do |f|
  #     f.write(Base64.decode64(base64['data:image/jpeg;base64,'.length..-1]))
  #   end
  #
  #   # file = Tempfile.new(["parse_from_mobile", ".jpeg"])
  #   # file.binmode
  #   # decoded = Base64.decode64(base64['data:image/jpeg;base64,'.length..-1])
  #   # file.write(decoded)
  #
  #   puts "File written..."
  #
  #   file = File.new(path)
  #
  #   @data  = OcrSpace::FilePost.post('/parse/image', body: { apikey: "0ad729224588957", language: "eng", isOverlayRequired: false, file: file})
  #   if @data.parsed_response["ErrorMessage"].present?
  #     raise StandardError.new(@data.parsed_response["ErrorMessage"][0]) and return
  #   end
  #
  #   puts "@data: #{@data.inspect}"
  #   File.delete(path)
  #
  #
  #
  #   self.raw_text = @data.parsed_response['ParsedResults'][0]["ParsedText"].gsub(/\r|\n/, "")
  #   return self.raw_text
  # end

  def parse
    self.extract_drug_name
    self.extract_frequency
    self.extract_amount
    self.extract_delivery
  end

  def extract_frequency
    self.frequency = get_from_regex(/(EVERY (((\d)+ (\w)+)|((\w)+)))|((\w)+ DAILY)|(AT (\w)+)/)
  end

  def extract_amount
    self.amount = get_from_regex(/(((\d)-(\d))|((\d)+)) (TABLET|CAPSULE)(S){0,1}/)
  end

  def extract_delivery
    self.delivery =  get_from_regex(/(BY MOUTH)|(SWALLOW (\w)+)/)
  end

  def extract_drug_name
    $drug_list = []
    processed_drugs_file = Rails.root.join("lib", "drugs_processed.txt")
    File.open(processed_drugs_file, "r") do |f|
      f.each_line do |line|
        $drug_list.push(line.upcase.squeeze(" ").strip)
      end
    end

    str_split = self.raw_text.split()
    for word in str_split
      result = find_drug_name_match(word)
      if result
        self.drug_name = result
        return self.drug_name
      end
    end

    return nil
  end

  #----------------------------------------------------------------------------

  private

  def get_from_regex(r1)
    puts "self.raw_text; #{self.raw_text.inspect}"
    match = r1.match(self.raw_text)

    if !match
      return nil
    else
      return match[0]
    end
  end


  def find_drug_name_match(str1)
    for drug_name in $drug_list
      if drug_name == str1
        return drug_name
      end
    end

    return nil
  end

  #----------------------------------------------------------------------------
end