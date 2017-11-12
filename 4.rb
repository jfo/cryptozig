class Array
    def cxor(c)
        self.map do |e|
            e ^ c
        end
    end

    def cxorer
        out = []
        (0..255).each do |c|
            out << self.cxor(c)
        end
        out
    end

    def scorer
        self.count(32) + self.select { |e| e >= 32 && e <= 122}.size
    end
end


winner = File.readlines("datafiles/4.txt").map do |el|
    el.chomp.scan(/../).map { |e|
        e.to_i(16)
    }.cxorer.map { |a|
        [a.scorer, a]
    }.sort_by { |a|
        a.first
    }.reverse.first
end.sort_by { |a|
    a.first
}.reverse.first[1].map{ |e|
    e.chr
}.join

# puts winner
