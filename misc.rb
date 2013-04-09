# coding: utf-8

require 'nkf'
require 'MeCab'

EXCEPTION = /^[!-\/:.,?\[\]{}@#\$%^&*()_+=\\|'";<>~`「」『』、。〜ーw★☆█♪\^0-9]+?$/

def ngram(string)
    chars = []
    string.gsub!(/\s/,'')
    string.size.times do |i|
        chars << "#{string[i]}#{string[i+1]}"
    end
    chars
end

def nouns(string)
    m = MeCab::Tagger.new
    node = m.parseToNode(NKF.nkf('-Z0Z1w', string.chomp.downcase))
    nouns = []
    while(node.next)
        if node.feature.force_encoding('utf-8').split(',')[0] == "名詞"
            word = node.surface.force_encoding('utf-8')
            # 記号だけが続く文字列は、それが「名詞」と判断されていようが無視する
            unless word =~ EXCEPTION
                nouns << word if word.length > 1
            end
        end
        node = node.next
    end
    nouns
rescue
    return []
end


def atoh(array)
    return nil if not array
    hash = Hash.new(0)
    array.each do |e|
        hash[e] += 1
    end
    hash
end

def normalize(hash)
    return nil if not hash
    norm = 0.0
    hash.each do |word, freq|
        norm += freq.to_f**2
    end
    norm = Math.sqrt(norm)
    normalized_hash = {}
    hash.each{|w,f| normalized_hash[w] = f/norm}
    normalized_hash
end

def cosine_sim(doc1, doc2)
    return 0 if (not doc1) or (not doc2)

    similarity = 0.0
    doc1.each do |term, freq|
        doc2.each do |ut, uf|
            if term.to_s.downcase == ut.to_s.downcase
                similarity += freq*uf.to_f
                # puts term
            end
        end
    end
    similarity
# rescue => ex
#     $stderr.puts "#{ex.class} : #{ex.message}"
#     -1
end

def sim(url1, url2)
    # normalize(atoh(string1.split('')))
    # normalize(atoh(string1.split('')))
    # 0
    # string1.split('')
    # string2.split('')
    # 0
    cosine_sim(normalize(atoh(url1.title_array)), normalize(atoh(url2.title_array)))
    #2 cosine_sim(normalize(atoh(string1.split(''))), normalize(atoh(string2.split(''))))
end
