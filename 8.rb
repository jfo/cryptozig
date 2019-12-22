
class Candidate
  attr_accessor :score, :line

  def initialize line = ''
    @line = line
    @score = compute_score
  end

  private

  def compute_score
    chunks = @line.scan(/.{1,2}/)
    chunks.count - chunks.uniq.count
  end
end

lines = File.read('./datafiles/8.txt').split("\n").map {|l| l.chomp}

winner = Candidate.new(lines[0])

lines.map do |line|
  candidate = Candidate.new line
  if candidate.score > winner.score
    winner = candidate
  end
end

p winner.line
# "d880619740a8a19b7840a8a31c810a3d08649af70dc06f4fd5d2d69c744cd283e2dd052f6b641dbf9d11b0348542bb5708649af70dc06f4fd5d2d69c744cd2839475c9dfdbc1d46597949d9c7e82bf5a08649af70dc06f4fd5d2d69c744cd28397a93eab8d6aecd566489154789a6b0308649af70dc06f4fd5d2d69c744cd283d403180c98c8f6db1f2a3f9c4040deb0ab51b29933f2c123c58386b06fba186a"
