require "unicode"
class String

  def downcase
    Unicode::downcase(self)
  end
  def downcase!
    self.replace downcase
  end
  def upcase
    Unicode::upcase(self)
  end
  def upcase!
    self.replace upcase
  end
  def capitalize
    Unicode::capitalize(self)
  end
  def capitalize!
    self.replace capitalize
  end

  def sanitize
    self.split('').collect do |token|
      token.gsub(/[^-<>A-Za-zА-Яа-я0-9]/, '')
    end
  end

  def regulars
    if self =~ /^</ or self =~ />$/
      self.gsub(/[^'']/, '')
    elsif self =~ /^[A-Za-z]/ and self =~ /[А-Яа-я0-9]/
      self.gsub(/[^'']/, '')
    elsif self =~ /^[А-Яа-я]/ and self =~ /[A-Za-z0-9]/
      self.gsub(/[^'']/, '')
    elsif self =~ /^[0-9]/ and self =~ /[A-Za-zА-Яа-я]/
      self.gsub(/[^'']/, '')
    else
      self
    end
  end

end

class InvertedIndex

  attr_accessor :args, :data, :doc_number, :token_sum, :token_number

  def initialize (args, index_filename, data={}, doc_number=1, in_text=false, token_sum=0, token_number=0)
    @args = args
    @doc_number = doc_number
    @in_text = in_text
    @token_sum = token_sum
    @token_number = token_number
    @data = data
    @index_filename = index_filename
  end

  def open_index
    if File.exist? @index_filename
      @data = Marshal.load open(@index_filename)
    else
      @data = {}
    end
  end

  def parse
    @args.each do |filename|
      open(filename) do |file|
        file.read.split.each do |word|
          if word.include? "Section"
            @in_text = !@in_text
          end
          if word.include? "</p>"
            @doc_number += 1
          end
          @token_sum += word.length
          @token_number += 1
          if @in_text and word.length >= 3
            word = word.downcase.sanitize.join.regulars
            @data[word] ||= []
            @data[word] << @doc_number unless @data[word].include? @doc_number
          end
        end
      end
      @doc_number += 1
    end
  end

  def write_index
    open(@index_filename, "w") do |index|
      index.write Marshal.dump(@data)
    end
  end

  def create_inverted_index
    self.open_index
    self.parse
    self.write_index
  end

end

start = Time.now

inverted_index = InvertedIndex.new(ARGV, "index.dat")
inverted_index.create_inverted_index

finish = Time.now

@test = Marshal.load open("index.dat")
term_sum = @test.keys.inject(0) {|sum, key| sum + key.length}

puts "Documents = #{inverted_index.doc_number}"
puts "Tokens = #{inverted_index.token_number}"
puts "Terms = #{inverted_index.data.length}"
puts "Average length of tokens = #{inverted_index.token_sum.to_f / inverted_index.token_number.to_f}"
puts "Average length of terms = #{term_sum.to_f / @test.length.to_f}"
puts "Elapsed time = #{finish-start} seconds"