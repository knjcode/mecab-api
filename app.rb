require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/cross_origin'
require 'sinatra/json'
require 'json'

require 'natto'
require 'moji'

Encoding.default_external = 'utf-8'

configure do
  enable :cross_origin
end

last_request_time = ""
request_counter = 0

get '/' do
  erb :index
end

post '/mecab', provides: :json do
  body = JSON.parse(request.body.read) rescue ""
  if body == ""
    status 400
  else
    request_id = ""
    if body["request_id"].nil?
      t = Time.now
      if t.to_i == last_request_time
        request_counter += 1
      else
        request_counter = 0
        last_request_time = t.to_i
      end
      request_id = "#{t.to_i}\t#{request_counter}"
    else
      request_id = body["request_id"]
    end

    sentence = ""
    normalized = false
    if body["normalize"] == "true"
      sentence = normalize_neologd(body["sentence"])
      normalized = true
    else
      sentence = body["sentence"]
      normalized = false
    end

    if body["dictionary"].nil?
      dic = ""
    else
      dic = body["dictionary"]
    end

    $stdout.sync = true

    sentence.gsub!('サンチーム','サンチーム ')
    sentence.gsub!('センチメートル','センチメートル ')
    sentence.gsub!('キログラム','キログラム ')

    word_list, dic = parse(sentence, dic)

    word_array = []
    word_list.each_line do |line|
      line = line.chomp
      break if line == 'EOS'
      surface_form = line.split(" ").first
      splitted = line.split(/\t/)[1].split(',')
      pos = splitted[0]
      basic_form = splitted[6]
      pronunciation = splitted[8]
      pronunciation = 'ふうりゅー' if pronunciation == 'フリュー'
      pronunciation = pronunciation.tr('ァ-ン','ぁ-ん') if pronunciation

      pos_detail_1 = splitted[1]
      hoge = {pos: pos, basic_form: basic_form, pronunciation: pronunciation, surface_form: surface_form, pos_detail_1: pos_detail_1}
      word_array.push(hoge)
    end

    # word_list = word_list.each_line.map(&:chomp)

    # data = { request_id: request_id, word_list: word_list, dictionary: dic, normalized: normalized }
    data = { request_id: request_id, word_list: word_array, dictionary: dic, normalized: normalized }
    json data
  end
end

helpers do
  $nm = Natto::MeCab.new

  if ENV["MECAB_IPADIC_NEOLOGD_DICDIR"]
    $nm_ipadic_neologd = Natto::MeCab.new(dicdir: ENV["MECAB_IPADIC_NEOLOGD_DICDIR"])
  end

  if ENV["MECAB_UNIDIC_NEOLOGD_DICDIR"]
    $nm_unidic_neologd = Natto::MeCab.new(dicdir: ENV["MECAB_UNIDIC_NEOLOGD_DICDIR"])
  end

  def parse(sentence, dictionary)
    dic = dictionary.downcase
    if dic == "mecab-ipadic-neologd"
      if $nm_ipadic_neologd
        return $nm_ipadic_neologd.parse(sentence), dic
      end
    elsif dic == "mecab-unidic-neologd"
      if $nm_unidic_neologd
        return $nm_unidic_neologd.parse(sentence), dic
      end
    else
      return $nm.parse(sentence), "default"
    end
  end

  # https://github.com/neologd/mecab-ipadic-neologd/wiki/Regexp.ja
  # written by kimoto (https://github.com/kimoto)
  def normalize_neologd(norm)
    puts "input: " + norm
    norm.tr!("０-９Ａ-Ｚａ-ｚ", "0-9A-Za-z")
    norm = Moji.han_to_zen(norm, Moji::HAN_KATA)
    hypon_reg = /(?:˗|֊|‐|‑|‒|–|⁃|⁻|₋|−)/
    norm.gsub!(hypon_reg, "-")
    choon_reg = /(?:﹣|－|ｰ|—|―|─|━)/
    norm.gsub!(choon_reg, "ー")
    chil_reg = /(?:~|∼|∾|〜|〰|～)/
    norm.gsub!(chil_reg, '')
    norm.gsub!(/[ー]+/, "ー")
    norm.tr!(%q{!"#$%&'()*+,-.\/:;<=>?@[\]^_`{|}~｡､･｢｣"}, %q{！”＃＄％＆’（）＊＋，−．／：；＜＝＞？＠［￥］＾＿｀｛｜｝〜。、・「」})
    norm.gsub!(/　/, " ")
    norm.gsub!(/ {1,}/, " ")
    norm.gsub!(/^[ ]+(.+?)$/, "\\1")
    norm.gsub!(/^(.+?)[ ]+$/, "\\1")
    while norm =~ %r{([\p{InCJKUnifiedIdeographs}\p{InHiragana}\p{InKatakana}\p{InHalfwidthAndFullwidthForms}\p{InCJKSymbolsAndPunctuation}]+)[ ]{1}([\p{InCJKUnifiedIdeographs}\p{InHiragana}\p{InKatakana}\p{InHalfwidthAndFullwidthForms}\p{InCJKSymbolsAndPunctuation}]+)}
      norm.gsub!( %r{([\p{InCJKUnifiedIdeographs}\p{InHiragana}\p{InKatakana}\p{InHalfwidthAndFullwidthForms}\p{InCJKSymbolsAndPunctuation}]+)[ ]{1}([\p{InCJKUnifiedIdeographs}\p{InHiragana}\p{InKatakana}\p{InHalfwidthAndFullwidthForms}\p{InCJKSymbolsAndPunctuation}]+)}, "\\1\\2")
    end
    while norm =~ %r{([\p{InBasicLatin}]+)[ ]{1}([\p{InCJKUnifiedIdeographs}\p{InHiragana}\p{InKatakana}\p{InHalfwidthAndFullwidthForms}\p{InCJKSymbolsAndPunctuation}]+)}
      norm.gsub!(%r{([\p{InBasicLatin}]+)[ ]{1}([\p{InCJKUnifiedIdeographs}\p{InHiragana}\p{InKatakana}\p{InHalfwidthAndFullwidthForms}\p{InCJKSymbolsAndPunctuation}]+)}, "\\1\\2")
    end
    while norm =~ %r{([\p{InCJKUnifiedIdeographs}\p{InHiragana}\p{InKatakana}\p{InHalfwidthAndFullwidthForms}\p{InCJKSymbolsAndPunctuation}]+)[ ]{1}([\p{InBasicLatin}]+)}
      norm.gsub!(%r{([\p{InCJKUnifiedIdeographs}\p{InHiragana}\p{InKatakana}\p{InHalfwidthAndFullwidthForms}\p{InCJKSymbolsAndPunctuation}]+)[ ]{1}([\p{InBasicLatin}]+)}, "\\1\\2")
    end
    norm.tr!(
      %q{！”＃＄％＆’（）＊＋，−．／：；＜＞？＠［￥］＾＿｀｛｜｝〜},
      %q{!"#$%&'()*+,-.\/:;<>?@[\]^_`{|}~}
    )
    puts "output: " + norm
    norm
  end
end
