require "base64"

KEY ="ICE".split("").map {|e|e.ord}
p KEY
x = "Burning 'em, if you ain't quick and nimble\nI go crazy when I hear a cymbal".split("").map {|e|e.ord}

out = []
x.each_with_index do |e,i|
    out << (e | KEY[i % 2])
end

# p Base64.encode64 
p ('B'.ord ^ 'I'.ord).chr
p Base64.encode64(out.map{|e|e.chr}.join)
