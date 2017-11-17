require "base64"

class Array
    def cxor(c)
        self.map do |e|
            e ^ c
        end
    end

    def cxorer
        out = []
        (0..255).each do |c|
            out << [self.cxor(c), c]
        end
        out
    end

    def scorer
        self.count(32) + self.select { |e| e >= 32 && e <= 122}.size
    end
end

def hamming_distance_byte(b1,b2)
    val = b1 ^ b2
    dist = 0
    while val != 0 do
        dist += 1
        val &= val - 1
    end
    dist
end

def hamming_distance(arr1, arr2)
    raise "string length mismatch" if arr1.length != arr2.length

    arr1.zip(arr2).map do |e1, e2|
        hamming_distance_byte(e1, e2)
    end.inject :+
end
def hamming_distance_str(str1, str2)
    hamming_distance(str1.bytes, str2.bytes).to_f
end
hamming_distance_str("this is a test", "wokka wokka!!!")

x = File.open("datafiles/6stripped.txt", "r").read
@input = Base64.decode64(x).bytes

def find_repeating_xor_size(input)
    outhash = {}
    (1..40).each do |keylen|
        grouped_input = input.each_slice(keylen).to_a
        out = 0
        (0..grouped_input.count - 3).each do |i|
            out += (hamming_distance(grouped_input[i], grouped_input[i+1]) / keylen.to_f)
        end
        outhash[keylen]  = out / grouped_input.count
    end
    outhash.sort_by{|k,v|v}.first.first
end

def find_repeating_xor_key(input)
    blocks = input.each_slice(find_repeating_xor_size(input)).to_a[0..-2].transpose
    winner = blocks.map{ |block|
        block.cxorer.map { |a| 
            [a[0].scorer, a[0].map {|e|e.chr}.join, a[1]] 
        }.sort_by { |a|
            a.first
        }.reverse.first
    }
    winner.map {|e|e[2].chr}.join
end

def decrypt_repeating_xor(data)
    key = find_repeating_xor_key(data)
    keydata = key.split("").map{|e|e.ord}
    x = data.each_slice(key.length).map {|l|
        l.zip(keydata).map {|e|
            (e[0] ^ e[1]).chr
        }
    }
    x.join
end

print decrypt_repeating_xor(@input)
